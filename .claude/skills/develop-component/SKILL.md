---
name: develop-component
description: Use when asked to build, redesign, finish or fix one qsm-shell component, including "fix this animation", "the closing snaps back" and "make this component feel right". Prepare one intentional task example and revise that same item with the owner until accepted. Tests, captures and skill evaluations require an explicit request.
---

# Develop a component

This library has one developer and one current proof consumer. Components
remain reusable, rethemeable and composable for other Qt 6/Quickshell desktops;
the consumer's policy stays outside them. Functional, beautiful native controls
with dynamic, accessible UX are the product. Workbench only supports their
development and judgement. Keep the least code and documentation that work.

## The loop, in order

1. **Choose one item and its task.** Read `AGENTS.md` and the existing record
   in `docs/components/<Type>.md`. Name what the person finishes and what the
   action changes. State the settings, supported states, input/focus/accessibility
   routes, sizes and overflow behaviour in that short record before coding.
   Extend an existing type unless the concept genuinely differs.
2. **Design deliberately.** Start from the task, then interaction, hierarchy,
   content, glyphs, tokens and motion. Use `ui-design`, the blueprint PDF and
   actual named Caelestia files in `~/Clonned/caelestia/repo/`; compare relevant
   Material, Radix or Fluent patterns without collecting every configuration
    flag. Follow the owner's accepted decisions first. The two desktop wallpapers
    inform a cosy, minimal dusk/night atmosphere, not copied decoration.
    For geometry or motion, use **Motion and rendering changes** below before coding.
3. **Build the component and a coherent example.** Use the template where one
   exists, `Style`/`Motion`, shared action functions and host-owned state. The
   unit answers every intent and exercises slots through the real API. Glyph,
   verb, reading, confirmation and outcome describe the same task. A fixture's
   purpose is chosen as a whole, not by swapping one icon on unrelated copy.
4. **Make supported cases reachable.** Keep one unit per type and the catalog
   mapping intact. Declare compact controls for property states: sizes, valid
   empty/long content, and first/middle/last/all-disabled options where supported.
   Pointer-reachable hover, press and focus are exercised by the owner. Expose
   integration hooks for requested checks; do not create or run tests or flows
   simply to fill an inventory.
5. **Hand over, then wait.** Say which item is ready, its purpose, and the few
   states the owner should inspect. If asked to open it, use `qsm-compuse` on
   workspace 10, announce input, select only this item, then stop input. The
   owner tests and judges. Do not run an audit, a capture sweep, an input trace,
   validation or a skill evaluation without an explicit request.
6. **Revise the same item.** Fix feedback in the owning component or tokens;
   fix a misleading example in its unit. Keep the record current and put any
   unresolved decision in one backlog line. Restart QML after edits when a live
   preview is requested. Move to the next item only after owner acceptance;
    close only your own preview windows after the owner finishes.

## Motion and rendering changes

Trace the complete rendered path, not just the property being animated: host
intent → progress → full body/content → clip viewport → registry normalization,
snapping and transforms → shader fill/stroke → input region → hiding/unloading.
In the existing component record, name the owning files, coordinate spaces and
what stays constant at each boundary. A helper can invalidate upstream geometry;
reading only the component does not establish what reaches the screen.

Compare the reference's caller, wrapper and renderer together. Record the useful
mechanism and incompatible policy, not just its easing or a copied offset. For
edge motion, Caelestia's `modules/osd/Wrapper.qml`, `modules/drawers/ContentWindow.qml`
and `modules/bar/popouts/ClipWrapper.qml`, with
`plugin/src/Caelestia/Blobs/shaders/blob.frag`, are relevant; controls alone are not.
Replace contradictory instructions in place; a new paragraph does not cancel an
older formula elsewhere in the same spec.

Define the terminal handoff before implementing it: almost hidden → hidden but
still registered → removed/unloaded. The hidden contribution must become neutral
before removal, including paint, deformation and input, so removal introduces no
second motion or relighting. For SDF paint this includes interior distance and
gradient, not only the outline; use `docs/12-mechanism.md` for the exact formulas.
Fix a broken handoff in its owner, not with extra easing, parking travel or a timer.

When recording is explicitly requested, capture the named transition through its
settled tail, not only opening or the final state. Load the current QML and compiled
shader first; derive the full moving region plus fixed origin/handle from current
live coordinates. Keep native originals and actual timestamps, not interpolated
frames or upscaled pixels. Report the exercised item/routes separately from the
shared source's reach. Without permission, leave this runtime evidence unverified.

## Requested checks

Only an explicit request authorizes creating or running a check. Choose a
real input/integration flow with changing states and consequences, not a test
of static text, font sizes, colours, geometry literals or source shape. Missing
tests are not defects. A passing check is evidence of behaviour, not design
acceptance, and does not authorize a wider sweep.

A delegated check gets the same named item, permitted operations and exclusions;
it is not permission for extra comparisons, routes or catalog coverage.

**Trace and inventory**: before requesting a check, trace the component's
integration points (events, actions, observables, keys, textDriver, checkpoints)
and inventory what is already declared. A step a host cannot execute FAILS and
names itself; nothing returns success without having done the work.

**Sibling search**: when a new type or action is introduced, search sibling
types in the catalog to confirm the name is not already in use. A type whose
name says where it is used is a type you have twice — `MenuRowItem`,
`PopoutRow` and `ResultRow` were one row wearing three names. Same for
`SearchField`: a search box is a text box with a glyph in its leading slot.

**Owner review / test opt-in**: no check, capture, audit or validation runs
without an explicit owner request. A request to build or review a component is
not permission to test it. Tests, validation, captures and automated input run
only when explicitly requested; a request to build or review a component is not
permission to test it.

## What is not done here

- No automatic testing, validation, capture sweeps, audits or skill evals.
- No TDD, expected-red tests, static-style assertions or coverage growth.
- No plans, no dated documents, no CLOSED/LANDED history, no counters.
- No working around a component defect inside its unit.
- No re-implementing a rule a sibling type already owns. A step a harness
  cannot execute FAILS and names itself; nothing returns success without
  having done the work.
- No consumer (`qsm-desktop`) work; it catches up after the controls land.
- No self-acceptance, unattended judgement, or continuing to the next item
  because the owner is absent. No claim of acceptance from a render or green gate.
