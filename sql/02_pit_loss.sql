-- sql/02_pit_loss.sql
-- Phase 2: time lost in the pits by circuit.
--
-- Part A (simple): median pit-lane time per circuit.
--   pit-lane time = pit_stops.milliseconds (entry to exit of the pit lane, not time lost on track)
--   stops over 60 s are excluded (red flags and repairs)
--   median, not average, so a few slow stops don't move the number
--
-- Caveats
--   * Pit-lane time mostly reflects pit-lane length and speed limit, not the true cost of a stop.
--     Part B (in-lap + out-lap vs clean laps) measures that.
--   * Small samples: Madring (25 stops) and Mugello (41) are single-race venues.
--   * Group by circuitId: names can repeat or change.

SELECT
    c.circuitId                          AS circuit_id,
    c.name                               AS circuit,
    COUNT(*)                             AS stops,
    MEDIAN(p.milliseconds) / 1000.0      AS median_lane_s
FROM pit_stops p
JOIN races r    ON p.raceId = r.raceId
JOIN circuits c ON r.circuitId = c.circuitId
WHERE p.milliseconds <= 60000
GROUP BY c.circuitId, c.name
ORDER BY median_lane_s;

-- Part B (better version): time lost per stop, green-flag stops only.
--   loss = in-lap + out-lap - 2 x the driver's median clean lap in that race
--   clean lap = not lap 1, not an in-lap, not an out-lap (all stops excluded, even long ones)
--
-- Rules and counts
--   * Stops with lane time over 60 s excluded (red flags, repairs): 12,418 stops remain.
--   * 88 stops dropped: no out-lap (last-lap stop) or driver had fewer than 5 clean laps.
--   * 12,330 analysed. Loss < 0 (20 stops) or > 60 s (2,148 stops, 17%) excluded as
--     safety-car / red-flag / wet-race distortion. 10,162 stops kept.
--   * Excluding stops by their outcome biases the figure toward green-flag racing,
--     which is the intent: Phase 3 also drops safety-car battles.
--
-- Caveats
--   * About half of all stops are removed at Jeddah, Mugello and Baku; treat those with caution.
--   * Circuits with under ~50 green stops are small samples (Mugello 20, Madring 23, Jeddah 47, Algarve 47).

CREATE OR REPLACE TABLE pit_loss AS
WITH clean_laps AS (
    SELECT l.raceId, l.driverId, l.lap, l.milliseconds
    FROM lap_times l
    WHERE l.lap > 1
      AND NOT EXISTS (
          SELECT 1
          FROM pit_stops p
          WHERE l.raceId = p.raceId
            AND l.driverId = p.driverId
            AND (l.lap = p.lap OR l.lap = p.lap + 1)
      )
),
driver_medians AS (
    SELECT raceId, driverId,
           MEDIAN(milliseconds) AS median_clean_ms,
           COUNT(*)             AS clean_lap_count
    FROM clean_laps
    GROUP BY raceId, driverId
),
stop_loss AS (
    SELECT p.raceId, p.driverId, p.lap,
           inl.milliseconds + outl.milliseconds - 2 * dm.median_clean_ms AS loss_ms
    FROM pit_stops p
    JOIN lap_times inl     ON inl.raceId  = p.raceId AND inl.driverId  = p.driverId AND inl.lap  = p.lap
    JOIN lap_times outl    ON outl.raceId = p.raceId AND outl.driverId = p.driverId AND outl.lap = p.lap + 1
    JOIN driver_medians dm ON dm.raceId   = p.raceId AND dm.driverId   = p.driverId
    WHERE p.milliseconds <= 60000
      AND dm.clean_lap_count >= 5
)
SELECT
    c.circuitId                                                         AS circuit_id,
    c.name                                                              AS circuit,
    COUNT(*) FILTER (WHERE sl.loss_ms BETWEEN 0 AND 60000)              AS stops,
    ROUND(100.0 * COUNT(*) FILTER (WHERE sl.loss_ms NOT BETWEEN 0 AND 60000) / COUNT(*), 1)
                                                                        AS pct_excluded,
    MEDIAN(sl.loss_ms) FILTER (WHERE sl.loss_ms BETWEEN 0 AND 60000) / 1000.0 AS pit_loss_s
FROM stop_loss sl
JOIN races r    ON sl.raceId = r.raceId
JOIN circuits c ON r.circuitId = c.circuitId
GROUP BY c.circuitId, c.name;

-- Part A vs Part B: where the two versions disagree most (seconds)
--   Part A = median pit-lane time; Part B = green-flag time lost incl. in-lap and out-lap.
--   Samples differ slightly: Part A uses all stops with lane time <= 60 s,
--   Part B keeps only stops with a loss between 0 and 60 s.
--   Silverstone     28.8 -> 20.5 (-8.4): looks expensive by lane time, cheap once on-track time counts
--   Paul Ricard     30.8 -> 24.2 (-6.6): same pattern, but only 69 stops
--   Albert Park     22.1 -> 26.3 (+4.2): cheap lane, costly once slow in/out laps are counted
--   Zandvoort       19.6 -> 23.1 (+3.5): cheapest lane in Part A, mid-table in Part B
-- Possible reason (untested): a long pit lane costs less than its length suggests if cars would
-- have covered that stretch of track anyway, while slow in/out laps add cost the lane time misses.
-- Takeaway: pit-lane time alone would misrank circuits, so Phase 3 uses pit_loss_s from Part B.