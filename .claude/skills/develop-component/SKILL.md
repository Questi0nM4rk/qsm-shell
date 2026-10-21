---
name: develop-component
description: Use when asked to build, redesign, finish or fix one qsm-shell component, including "fix this animation", "the closing snaps back" and "make this component feel right". Prepare one intentional task example, validate it on the live composed desktop with the qsm-compuse instruments, and revise that same item with the owner until accepted.
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
   content, glyphs, tokens and motion. Use `ui-design`, the design-system rules in AGENTS.md and
   actual named Caelestia files in `~/Clonned/caelestia/repo/`; compare relevant
   Material, Radix or Fluent patterns without collecting every configuration
    flag. Follow the owner's last stated decision over any spec line; quote it in the
    record and, when decisions disagree, ask one question. The two desktop wallpapers
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
   owner tests and judges. Never write "fixed", "works" or "passes" for
   pointer, drag, hover, focus or animation behaviour without a live run of the
   composed surface the owner asked for; a unit test or lint proves the unit
   only, so say "not verified live" and list what the owner should try.
   Before the hand-over, run the composed-surface pass (below) and hand over
   its before/after numbers with the item.
6. **Revise the same item.** When the owner rules in chat, edit the spec line
   in the same change and cite their words; an overruled spec line is out of date,
   not authority. Fix feedback in the owning component or tokens;
   fix a misleading example in its unit. Keep the record current and put any
   unresolved decision in one backlog line. Restart QML after edits when a live
   preview is requested. Move to the next item only after owner acceptance;
    close only your own preview windows after the owner finishes.

## Owner rulings that bind the library

General rules are in `qsm-uix` (qml-ui, ui-design, ux-audit, ui-audit); these are
the cases they apply to here.

- Hover surface (rollout, handle, popout): opens on entry, stays open in the union of
  trigger, panel and the path between, closes 180 ms after leaving. The hit zone is
  never the painted shape; the 4-dot top handle needed pixel-perfect aim.
- Scrolling list: the wheel always scrolls the list. An expandable row expands by
  click on its leading part, the rest of the row is its action, no hover-expand.
- Repeated items (notifications): each has its own body, a surface step with a slight
  shadow. One joined divider line between items looked bad.
- Frame edge: not a glow line. Slight full colour exactly at the edge, then a gradient
  fading inward into the band colour, even on all sides, corners and open rollout corners.
- Token or colour pass: values only; it never deletes a layout piece (dividers were lost).
- Colours are pastel but alive, never grey or dull.
- Qt names: a property named `on<Capital>` is read as a signal handler, and a FINAL
  property of an Item (`size`, `radius`, `live`) cannot be redeclared; both crash the
  load or drop the config silently. Rename.

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

When a change touches motion, record the named transition through its
settled tail, not only opening or the final state. Load the current QML and compiled
shader first; derive the full moving region plus fixed origin/handle from current
live coordinates. Keep native originals and actual timestamps, not interpolated
frames or upscaled pixels. Report the exercised item/routes separately from the
shared source's reach.

## Composed-surface pass

Every UI change is measured where the owner meets it: the component inside
its real desktop host, not only its unit. With `drive` (qsm-compuse) on
workspace 10, input announced: capture rest, hover, press, focus and open;
read the item tree and check the equations that must hold, each printed with
its numbers: insets equal on all sides within 1 px, no overlap between
neighbours after hover growth, no part of a track or fill outside its thumb,
a rollout centred from the monitor edge and bordered only on its attached
side, hit area at least the target floor, rendered contrast between adjacent
surfaces. Motion is recorded at real 25 to 60 fps. A check the instruments
cannot make yet is reported blocked with the missing instrument named
(marketplace epic `qsm-j480`). The numbers are evidence, never acceptance.

## Other checks

Test suites beyond the composed-surface pass run on the owner's request.
Choose a real input/integration flow with changing states and consequences,
not a test of static text or source shape. Missing tests are not defects. A
passing check is evidence of behaviour, not design acceptance.

A delegated check gets the same named item, permitted operations and exclusions;
it is not permission for extra comparisons, routes or catalog coverage.

**Trace and inventory**: before requesting a check, trace the component's
integration points (events, actions, observables, keys, textDriver, checkpoints)
and inventory what is already declared. A step a host cannot execute FAILS and
names itself; nothing returns success without having done the work.

**Sibling search**: when a new type or action is introduced, search sibling
types in the catalog, and the consumer's files, to confirm the name is not already
in use or already copied there. A type whose
name says where it is used is a type you have twice — `MenuRowItem`,
`PopoutRow` and `ResultRow` were one row wearing three names. Same for
`SearchField`: a search box is a text box with a glyph in its leading slot.

**Owner review**: the composed-surface pass is part of every UI change; an
audit, a catalog-wide capture sweep or a skill evaluation still waits for the
owner's request.

## What is not done here

- No catalog-wide sweeps, audits or skill evals without a request; no UI change without its composed-surface pass.
- No TDD, expected-red tests, static-style assertions or coverage growth.
- No plans, no dated documents, no CLOSED/LANDED history, no counters.
- No working around a component defect inside its unit.
- No re-implementing a rule a sibling type already owns. A step a harness
  cannot execute FAILS and names itself; nothing returns success without
  having done the work.
- No consumer (`qsm-desktop`) work and no local copy there: a control the consumer
  needs is a library task here, and the consumer takes it from the library.
- No self-acceptance, unattended judgement, or continuing to the next item
  because the owner is absent. No claim of acceptance from a render or green gate.
