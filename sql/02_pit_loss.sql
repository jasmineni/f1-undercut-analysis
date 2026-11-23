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

-- Part B (better version): add below.