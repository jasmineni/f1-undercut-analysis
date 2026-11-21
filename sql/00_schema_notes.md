# Schema notes

Analysis tables (`races`, `results`, `lap_times`, `pit_stops`) hold 2011-2026 only; `*_raw` copies hold all years.

```
races   one row per GP (raceId): year, round, name, circuitId -> circuits on circuitId
circuits    one row per track (circuitId): name, location, country
drivers     one row per driver (driverId): code, forename, surname
results     one row per driver per race (raceId, driverId): grid, positionOrder, laps, constructorId, statusId -> races on raceId, drivers on driverId, status on statusId
status  one status per row (statusId): status
lap_times   one row per driver per lap (raceId, driverId, lap): position, milliseconds -> races on raceId, drivers on driverId
pit_stops   one row per stop (raceId, driverId, stop): lap (the in-lap), milliseconds (pit-lane time) -> lap_times on (raceId, driverId, lap)
safety_cars     one deployment (no key): Deployed, Retreated, FullLaps -> races on safety_cars.Race = races.year || ' ' || races.name

Join keys: raceId (race-level), driverId (driver) circuitId (track), statusId (result status).
Lap-level tables always join on raceId + driverId together.

