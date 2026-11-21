# F1 Undercut vs Overcut

**Question:** When does pitting before the car ahead (the undercut) gain the position, and when does staying out longer (the overcut) work better?

**Result:** TBD (fill in after Phase 3)

## Definitions

Every number in this project depends on these rules.

1. **Gap:** time between two cars at the end of a lap, from each driver's running total of lap times.
2. **Battle:** on the lap before the first car pits, the two cars are in adjacent positions and the gap is 3.0 s or less.
3. **First mover / responder:** the first mover pits first; the responder pits 1 to 3 laps later. If the responder doesn't pit within 3 laps, the pair is dropped.
4. **Undercut attempt:** the first mover was the car behind. **Overcut attempt:** the first mover was the car ahead, so the car behind stayed out longer.
5. **Success:** the attacker (the car behind before the stops) is ahead at the end of the first lap after both cars have stopped.
6. **Exclusions:** lap 1 stops, pit-lane times over 60 s, cars a lap or more apart, and pairs where either car retired before both stops.

Segments compared: circuit, era (2011-13, 2014-21, 2022 onward) and gap bucket (0-1 s, 1-2 s, 2-3 s).

## Data and scope

- Source: RaceData CSVs (Ergast-style tables), queried in DuckDB.
- Scope: 2011 to 2026. 330 races, 13,029 pit stops, 370,470 laps.
- Setup: `sql/00_load_data.sql` loads the CSVs and keeps only 2011+ races that were run. Table notes are in `sql/00_schema_notes.md`.

## Findings

TBD: 3 charts with a one-sentence takeaway each (success rate by circuit, by era, by gap bucket). Show the sample size next to every rate.

## Headline numbers

TBD: battles found, races covered, undercut vs overcut success rate, best and worst 3 circuits.

## Feature pitch

TBD: the "undercut threat" fan-app card, its success metric and the A/B test.

## Limits

- No tyre data in the core tables.
- Safety cars can decide a battle instead of strategy.
- Small samples at some circuits; some tracks changed layout.

## Repo map

- `sql/00_load_data.sql`: load and filter the data
- `sql/00_schema_notes.md`: tables and joins
- `sql/01_positions_gained.sql`, `02_pit_loss.sql`, `03_undercut.sql`: TBD, added as each phase is done