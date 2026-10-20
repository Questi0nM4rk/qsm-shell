## 0. How to pick this change up

The library, not the desktop, is audited first. Do not start repairs here: this change produces
records and findings, and the owner chooses the first repair afterwards.

The owner allowed a full redesign, including changing the shared silhouette. That permission is
not acceptance of any particular look.

Working rules for this repository (`AGENTS.md`) and the shared method
(`qsm-uix`: `ui-design`, `ui-audit`, `ux-audit`, `a11y-audit`, `review-animations`,
`desktop-ui`, `qml-ui`) apply. One rule wins over another: say so in one line and ask.

Runtime evidence uses the installed Workbench, never a sibling checkout script:

```bash
qsm-workbench session start --provider "$PWD" --story <story-key> --headless \
  --session-file /tmp/opencode/<name>.json --log /tmp/opencode/<name>.log
qsm-workbench session request --pid <pid> --provider qsm-shell --json \
  '{"version":1,"op":"capture","scope":"preview","output":"/tmp/opencode/<name>.png"}'
qsm-workbench session request --pid <pid> --provider qsm-shell --json \
  '{"version":1,"op":"inspect"}'
qsm-workbench session stop --session-file /tmp/opencode/<name>.json
```

`scope: "window"` captures the whole Workbench window content, chrome included. Capture keeps
the current state, so a disabled control, a held press and a running animation are all
photographable. It never overwrites an existing PNG.

Measured limit: the offscreen pipeline does not rasterise `SvgIcon` glyphs, so glyph-bearing
types look empty in both scopes. That is this repository's known limit, not a component defect.
Visual evidence for glyphs needs a real window on workspace 10, opened with the owner's go.

## 1. Coverage and evidence method

- [ ] 1.1 Reconcile `Components/qmldir`, `workbench/stories.json`, existing records and desktop use.
  Add one linked coverage row per type in `docs/USAGE.md`, including aliases and unrepresented types.
- [ ] 1.2 Define the shared per-record evidence and pointer-math method in `docs/USAGE.md`.
  Use one measured target to demonstrate units, origins, width model, tolerance and evidence limits.
  Do not turn a source-derived number into a runtime measurement.

## 2. Complete source review and intended behavior

Each type gets its own section in `docs/components/<Type>.md`, added to the existing record:
purpose and consequence, expected public controls, valid states, pointer/keyboard/wheel/focus and
accessibility routes, size and overflow, visual roles, motion, pointer geometry, findings and
evidence. Proposed capability is stated as proposed, never as implemented.

- [ ] 2.1 Review foundation records: StateLayer, Surface, Card, Prose, SvgIcon, Divider,
  SelectionMark. Record source-specific consequences, expected states and meaningful non-goals.
- [ ] 2.2 Review action/input records: Capsule, IconButton, ControlLabel, Field, TextField,
  Switch, Checkbox, Radio, SpinBox, Segmented, Slider, ArmedAction, ActionTile.
  Enumerate root, child and slot actions, actual keyboard/focus routes and target geometry.
- [ ] 2.3 Review list/content records: ListRow, Menu, ScrollArea, ScrollCue, Section, Disclosure,
  MonthCalendar. Include scrolling ownership, dynamic rows, selection and trigger-panel travel.
- [ ] 2.4 Review feedback/readout records: Badge, Spinner, ProgressBar, Skeleton, Callout,
  EmptyState, Meter, Stat, StatRing, Sparkline, Marquee, ColorSwatch, Kbd, Avatar, KeyValueRow.
  Record information hierarchy, valid data extremes and whether input mathematics applies.
- [ ] 2.5 Review surface records: Popover, Dialog, Scrim, NotificationCard, NotificationCenter,
  NotificationStack, DataCapsule, ShellBorder, Rollout, ScenePointer. Trace content, paint,
  clipping, input and lifetime separately, including trigger/child routes and dismissal.

## 3. Runtime evidence without production changes

- [ ] 3.1 After the Workbench capture blocker is resolved, capture supported states and native trees
  through owned installed-tool sessions. Preserve before/after state and route identity.
  Record render/input/accessibility gaps and specify owning fixture/tooling changes separately.
- [ ] 3.2 Exercise declared real input routes, meaningful boundary/offset/overshoot paths, bad paths,
  interruption and supported size/content states. Capture pointer/focus states where supported.
  Any unsupported route remains not tested. Do not claim simulated input is compositor evidence.
- [ ] 3.3 Add measured visual, UX, motion and accessibility findings to each record. Include hitbox
  calculations, geometry/scale sources, palette/on-pair evidence and explicit model assumptions.
  Keep hypotheses and redesign proposals separate from observed defects.

Pointer mathematics, per interactive target: the input shape, not the painted glyph. Distance
D from the representative origin to the target centre in logical pixels, and the width W of the
target along the approach direction. Difficulty is ID = log2(1 + D/W) in bits, with the 2D width
model stated: for a rectangle and a centre-line unit approach vector u, the chord is
W = min(w/|u.x|, h/|u.y|), terms with a zero denominator omitted. The smaller-of model
W = min(w, h) is a separate comparison, not the same measurement. Report per-scenario difficulty
and, with explicit weights, a synthetic aggregate. Never publish a human average movement time,
miss rate or probability: no real user sample exists, and origins and weights are model
assumptions. Source: MacKenzie and Buxton, CHI 1992, <https://www.yorku.ca/mack/CHI92.html>.

## 4. Deliver the audit before repairs

- [ ] 4.1 Reconcile every coverage row with its record, link open findings from `docs/BACKLOG.md`,
  and deliver the complete audit and runtime gaps to the owner. Do not start component repairs.
- [ ] 4.2 Let the owner choose the first repair and review the proposed shared design direction.
  Create scoped repair specs only for selected work. Keep full redesign permission distinct from
  acceptance of any visual candidate, and leave desktop integration blocked by library acceptance.
