-- sql/01_positions_gained.sql
-- Phase 1: positions gained by circuit, 2011 onward.
--
-- Definitions
--   positions gained = grid - positionOrder (positive = moved up)
--   kept rows        = finishers only ('Finished', 'Lapped', '+N Laps'), no pit-lane starts (grid = 0)
--   pole win share   = races won from pole / races at that circuit
--   circuits kept    = at least 5 races
--
-- Caveats
--   * Retirements are excluded, so every average is pushed slightly upward (survivorship).
--   * Races are counted through `results`, so unrun 2026 rounds are ignored.
--   * Sepang's 8 races include the 2026 "Bahrain Grand Prix in Malaysia" one-off.
--   * Circuits with 5-6 races (Hockenheim, Imola, Jeddah, Miami, Zandvoort) are small samples.

WITH finisher_rows AS (
    SELECT
        c.circuitId,
        c.name AS circuit,
        race.raceId,
        r.grid - r.positionOrder AS positions_gained,
        CASE WHEN r.grid = 1 AND r.positionOrder = 1 THEN 1 ELSE 0 END AS won_from_pole
    FROM results r
    JOIN races race ON r.raceId = race.raceId
    JOIN circuits c ON race.circuitId = c.circuitId
    JOIN status s   ON r.statusId = s.statusId
    WHERE race.year >= 2011  -- safe even if the data is already filtered
      AND r.grid > 0
      AND (s.status IN ('Finished', 'Lapped') OR s.status LIKE '+%')
),
by_circuit AS (
    SELECT
        circuitId,
        circuit,
        COUNT(DISTINCT raceId)                       AS num_races,
        AVG(positions_gained)                        AS avg_positions_gained,
        SUM(won_from_pole) / COUNT(DISTINCT raceId)  AS pole_win_share
    FROM finisher_rows
    GROUP BY circuitId, circuit
    HAVING COUNT(DISTINCT raceId) >= 5
)
SELECT
    circuit,
    num_races,
    avg_positions_gained,
    pole_win_share,
    RANK() OVER (ORDER BY avg_positions_gained DESC) AS comeback_rank
FROM by_circuit
ORDER BY comeback_rank;

-- Albert Park, Sepang and Baku gained the most places (about 1.9 to 2.2 per finisher), while Suzuka, Miami and Zandvoort gained the fewest (about 0.8 to 0.9). That may reflect overtaking opportunity, since narrow or flowing tracks make passing hard, and if so, teams might value track position gained in the pits more there.
-- Averages cover finishers only: retirements are excluded so a front-row car that crashed doesn't count as a big loss of places, which also nudges every circuit's average upward.