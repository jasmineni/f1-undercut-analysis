-- 00_load_data.sql
-- Loads the RaceData CSVs into DuckDB, then keeps only 2011+ races that were run.
-- Run from the repo root (paths are relative):
--   duckdb f1.duckdb < sql/00_load_data.sql

-- 1. Raw tables (kept untouched; `\N` marks missing values in the CSVs)
CREATE OR REPLACE TABLE races_raw     AS SELECT * FROM read_csv('data/races.csv',     nullstr='\N');
CREATE OR REPLACE TABLE circuits      AS SELECT * FROM read_csv('data/circuits.csv',  nullstr='\N');
CREATE OR REPLACE TABLE drivers       AS SELECT * FROM read_csv('data/drivers.csv',   nullstr='\N');
CREATE OR REPLACE TABLE results_raw   AS SELECT * FROM read_csv('data/results.csv',   nullstr='\N');
CREATE OR REPLACE TABLE status        AS SELECT * FROM read_csv('data/status.csv',    nullstr='\N');
CREATE OR REPLACE TABLE lap_times_raw AS SELECT * FROM read_csv('data/lap_times.csv', nullstr='\N');
CREATE OR REPLACE TABLE pit_stops_raw AS SELECT * FROM read_csv('data/pit_stops.csv', nullstr='\N');

-- 2. Analysis tables: 2011 onward, races that were actually run
--    (races first; the others filter through it because they have no year column)
CREATE OR REPLACE TABLE races AS
SELECT * FROM races_raw
WHERE year >= 2011
  AND raceId IN (SELECT raceId FROM results_raw);

CREATE OR REPLACE TABLE results   AS SELECT r.* FROM results_raw   r JOIN races USING (raceId);
CREATE OR REPLACE TABLE lap_times AS SELECT l.* FROM lap_times_raw l JOIN races USING (raceId);
CREATE OR REPLACE TABLE pit_stops AS SELECT p.* FROM pit_stops_raw p JOIN races USING (raceId);

-- safety_cars has no raceId: match it to races by "<year> <name>", and make Retreated a number.
-- Retreated is blank when the race finished under the safety car, so it becomes NULL.
CREATE OR REPLACE TABLE safety_cars AS
SELECT r.raceId,
       s.Cause,
       s.Deployed,
       TRY_CAST(TRY_CAST(NULLIF(s.Retreated, '') AS DOUBLE) AS INTEGER) AS Retreated,
       s.FullLaps
FROM safety_cars_raw s
JOIN races r ON s.Race = r.year || ' ' || r.name;

-- 3. Sanity checks: expect 330 races, 370,470 laps, 13,029 stops
SELECT 'races'     AS tbl, COUNT(*) AS n FROM races
UNION ALL SELECT 'lap_times', COUNT(*) FROM lap_times
UNION ALL SELECT 'pit_stops', COUNT(*) FROM pit_stops
UNION ALL SELECT 'results',   COUNT(*) FROM results
UNION ALL SELECT 'safety_cars', COUNT(*) FROM safety_cars;

SELECT MIN(year), MAX(year), COUNT(*) FROM races JOIN pit_stops USING (raceId);  -- 2011, 2026, 13029