## Context

The catalog has 60 keys mapping to 52 unique units. `Components/qmldir` exports 52 types.
The narrower production set in `GOAL.md` is not the scope of the owner's complete-library audit.
The owner permits a full UIX redesign, with the complete audit preceding repairs and desktop work.

## Goals / Non-Goals

**Goals:** one inspectable record per type, an honest coverage map, deliberate behavior and controls,
visual/motion assessment, and pointer acquisition/corridor analysis.

**Non-Goals:** component repairs, new visual tokens, user telemetry, production desktop operation,
automatic acceptance, a generic test framework or a new collection of duplicate audit documents.

## Decisions

1. **Extend existing records.** `docs/components/<Type>.md` owns its purpose, expected controls and
   behavior, states, size/overflow, input/accessibility, visuals/motion, pointer geometry, findings
   and evidence. A type with no pointer action states why pointer acquisition is inapplicable.
   README links to the existing `docs/USAGE.md` index. Repeating full records in README was rejected.
2. **Keep one method and index.** `docs/USAGE.md` holds the shared method and coverage table, keyed
   by exported type with all alias stories linked. Each row separates source review, runtime
   evidence and owner acceptance. A source-only record cannot silently become runtime-complete.
3. **Record intended behavior before judging implementation.** Controls mean both public component
   capabilities and Workbench options needed to reach valid states. A useful new capability is a
   redesign proposal, not an existing behavior or an automatic feature requirement.
4. **Treat pointer movement as a task.** For each real target, identify representative origins from
   its expected host, rather than pretending the standalone canvas has a normal user origin.
   Measure logical coordinates, actual input shape, transforms, clipping, visibility and z-order.
   Keep painted bounds, layout footprint and hit shape separate. Check neighbours through real
   routing where reachable, not bounding-box overlap alone.
5. **Separate acquisition from staying inside a corridor.** For origin S and target centre C,
   D = |C-S| in logical pixels. State the width model for ID = log2(1 + D/W) in bits. For an
   axis-aligned rectangle and a centre-line unit approach vector u, the geometric chord is
   W_theta = min(w/abs(u.x), h/abs(u.y)), omitting terms with a zero denominator. This follows
   rectangle-line intersection. It is not the rectangle's projected bounding width. The
   smaller-of model W = min(w,h) is a separate comparison supported by the cited study.
   Nonrectangular shapes require their actual intersection or an explicitly bounded proxy.
6. **No invented human average.** Origin positions, scenario weights and offset/overshoot paths are
   labelled model assumptions. Do not copy published timing coefficients or claim an average
   movement time, miss rate or probability from synthetic paths. Report per-scenario difficulty
   and, only with explicit weights, a synthetic aggregate. No passive pointer recording is added.
7. **Measure tolerance and continuity independently.** For a proposed landing point report distance
   to the usable input boundary and nearest competing target. For trigger-to-panel travel sample
   straight, diagonal and boundary-offset routes, with offsets derived and recorded from local
   geometry. Report corridor gaps, minimum clearance and dismissal delay. A passing straight path
   does not establish a success probability for natural mouse movement.
8. **Use UIX without erasing the evidence.** Palette, spacing, no-touch/overlap, controls and motion
   are assessed against named source rules and the owner's direction. Local rules in conflict with
   UIX become source-conflict rows requiring a design-source decision before repair. Permission to
   change the silhouette is not acceptance of a particular replacement.

Pointer-model source: MacKenzie and Buxton, *Extending Fitts' Law to Two-Dimensional Tasks*,
CHI 1992, <https://www.yorku.ca/mack/CHI92.html>. Published regression coefficients are specific
to that experiment, not calibration for this owner.

## Risks / Trade-offs

- Offscreen SVG capture can be empty → distinguish pipeline limitations from component defects.
- Story adapters can expose semantic actions but no native targets → list unsupported routes and
  specify the smallest provider-fixture change separately, never synthesize a passing action.
- Exhaustive combinations are unbounded → enumerate every item and meaningful state/route, while
  recording unvisited combinations instead of promising every Cartesian product was exercised.
- Existing records can contain stale acceptance claims → retain only acceptance tied to the named
  item/state and distinguish it from the proposed redesign.
