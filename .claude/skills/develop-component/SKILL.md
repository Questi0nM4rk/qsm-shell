---
name: develop-component
description: Use when building, redesigning or finishing one qsm-shell component type (Slider, TextField, Switch, ...). The step loop from "what is production-ready X" through live-window judgement. Project-only; one developer, one consumer, no external users.
---

# Develop a component

This library has one developer and one consumer. Nothing here is for a
public. That is what lets us skip API stability, versioning, coverage and
documentation: the only things that count are features that work in a live
window and pixels that follow the design sources. Less code is better. Less
docs is better. Every line of either needs a reason.

## The loop, in order

1. **Ask the production question.** Before reading our code, answer in
   writing: what does a fully working, production-ready X look like? List
   its settings, its behaviour under pointer, keyboard, wheel, focus and a
   screen reader, its sizes, what grows and what stays constant, its states,
   its events, and which of that is globally accepted across component
   libraries rather than our taste. Sources, in this order:
   - caelestia: `~/Clonned/caelestia/repo/components/controls/Styled*.qml`
   - other component libraries (Material 3, Radix, shadcn, Fluent): the
     union of their props and states is the definition of "feature-full"
   - `design-system-blueprint.pdf` at the repo root: every state designed,
     4px rhythm, one type scale, one icon scale, duration scale
   - the `ui-design` skill for the design record
   The answer becomes `docs/components/<Type>.md`: states, actions, size,
   tokens, motion, events, not designed. Ten lines, not a plan.
2. **Copy first, write second.** Take the template wiring and geometry from
   caelestia. `Tokens.*` becomes `Style.*`; M3 roles and C++ types do not
   port. Invent only what no source has.
3. **Build the real QML.** The component under `qml/QsmShell/Components/`,
   on its `QtQuick.Templates` type. Every number from `Style` or `Motion`.
   Every action a function listed in `actions`; pointer, keyboard and
   callers share it. State the host owns is reported, never written.
4. **Build the unit.** `previews/units/<Type>.qml` takes `variant`, plays the
   host (answers every upward signal), exercises every slot and label, declares
   `controls` for states a pointer cannot reach. Point the scenario keys in
   `previews/scenarios.json` at it and delete the inline children from
   `previews/Preview.qml`.
5. **Look at it.** `npm run preview -- <key>`. Announce you are taking the
   pointer, drive every state, then hand the window to the owner. Anything
   with a glyph is judged here only; captures do not rasterise icons.
6. **Audit.** `ux-audit` for interaction, `ui-audit` for the native visual
   result, both against the record and a tree dump (`--inspect`). Fix the
   findings. What stays open is one line in `docs/BACKLOG.md`.
7. **One regression check, after.** `tests/units/tst_<Type>.qml` with real
   events, only for behaviour that can realistically regress. Never pixels,
   never appearance, never a JavaScript model of QML. Drain that type's
   lines from `tests/interaction/tst_library.qml`.
8. **`npm test`**, then the owner judges the live window. Not delegable.

## What is not done here

- No TDD, no expected-red tests, no test growth for coverage.
- No plans, no dated documents, no CLOSED/LANDED history, no counters.
- No working around a component defect inside its unit.
- No consumer (`qsm-desktop`) work; it catches up after the controls land.
- No claim of completion from mocks, lint or a capture.
