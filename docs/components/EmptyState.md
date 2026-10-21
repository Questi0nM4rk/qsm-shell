# EmptyState

A centred icon, title and detail with one action slot for content that has nothing to show; it explains the void and offers the way out.
states: none; icon, detail and action sections each collapse when empty (the action section when the slot holds no item; a hidden item still occupies it), and `title` is always present.
actions: none of its own; the consumer's recovery control rides the default `action` slot.
pointer: none on the message itself; the slotted control keeps its own target and wheel passes through.
keyboard: none on the message itself; the slotted control keeps its own tab stop and keys.
screen reader: title names the state and detail describes it; the slotted action names itself.
size: content-driven column with fixed spacing; the glyph is icon large and the text is centred title and muted body.
tokens: space2, iconLg, textMuted and Prose; no local colours or measurements.
motion: none; an empty surface never implies interactivity through motion.
not designed: loading shells, error copy with tone or inline field hints; use Skeleton, Callout or Field for those.

## UIX audit

Method: ui-audit, ux-audit, a11y-audit (criteria left to its run), qml-ui. Evidence channel: source-reviewed only. No running shell, no live geometry tree, no capture and no keyboard driving was used, so every number below is either a token value (cited to `tokens/deep-night.json` or `qml/QsmShell/Style/Tokens.qml`), a ratio computed from those hex values, or a labelled assumption. Motion: the source has no animation, so review-animations has nothing to rule on. Runtime-exercised: none. Owner-accepted: none.

### Purpose and consequence

The message a list shows when it has nothing to show. It says what belongs there and, through the `action` slot, offers the next step. Wrong, a blank list reads as broken, or the person has no way forward.

### Controls and states

- Expected: `title` (required), `detail`, `icon` (a glyph name), and a default `action` slot.
- Implemented: all four (`EmptyState.qml` lines 11-16, 18-44). Icon, detail and title collapse as specified. The action slot collapses when it holds no item (ES-1, fixed).
- Not designed: loading, error, and cancellation. There is no failure path, so nothing to cancel.

### Routes

- Pointer: `EmptyState` has no pointer handler and no `MouseArea`, so the wheel passes through. The slotted `Capsule` takes pointer through its `StateLayer` (`HoverHandler` and `TapHandler`, `StateLayer.qml` lines 164-170) and `Capsule.qml` lines 171-174.
- Keyboard: `EmptyState` takes no focus. The slotted `Capsule` has `focusPolicy: Qt.StrongFocus` and activates on Return, Enter and Space (`Capsule.qml` lines 50, 177-179). No desktop call site passes an action, so no empty state in the desktop has a keyboard route today.
- Focus ring: keyboard focus only (`StateLayer.qml` line 152).
- Accessibility: neither `EmptyState` nor `Prose` sets `Accessible.role` or `Accessible.name`. Whether the platform tree exposes `title` and `detail` is not tested (see H-2).

### Sizes, empty and long content

- No size axis. Fixed roles: icon 24 px (`iconLg`, `Tokens.qml` line 45); title `textMd` 14 px bold; detail `textSm` 12 px regular with line height 1.55 (`Prose.qml` lines 74, 90, 102); column spacing 8 px (`space2`, `Tokens.qml` line 22).
- Empty: title only is the minimum valid state. The action slot takes no gap when it holds no item (ES-1, fixed).
- Long: the detail wraps when a width is given. Natural width is not constant (ES-2). The title does not wrap; it elides only if something narrows it, which nothing does (H-1).
- Failure: not designed (see record line 12).

### Visual roles and palette pairs

Ratios are WCAG 2.2 relative luminance from the deep-night hex values (`tokens/deep-night.json`). The component paints no background, so each ratio assumes the host paints that colour behind it. Only the deep-night set was read; light and high-contrast values were not.

| pair | role | ratio | required | verdict |
| --- | --- | --- | --- | --- |
| text `#f0ecf5` on band `#271e30` | title | 13.71:1 | 4.5 (1.4.3) | pass |
| textMuted `#c5bad1` on band | detail, icon | 8.61:1 | 4.5 for text, 3 for the icon (1.4.11) | pass |
| textMuted on surface `#42394c` | detail on a card | 5.89:1 | 4.5 | pass |
| textMuted on overlay `#534a5e` | detail on a popout | 4.51:1 | 4.5 | pass by 0.01 |

### Motion and reduced motion

None. `EmptyState.qml` and `Prose.qml` declare no animation, `Behavior` or transition. Reduced motion has nothing to shorten. The slotted `Capsule` has its own `Behavior`s (`Capsule.qml` lines 101-106), covered by its own record.

### Pointer geometry (the recovery action; the message has no target)

Assumptions, each labelled:

- A-1, label width: "Pair device" at 10 px (`textXs`) is estimated at about 60 px, from an assumed 5.5 px per character. A real render replaces it.
- A-2, origin: the pointer rests near the host centre, the position after a click on a centred surface. The column is centred in its host, so the action's offset from host centre does not depend on the host size. Any other origin changes D.
- Input shape: the `Capsule`'s own rectangle. Its `StateLayer` fills it (`Capsule.qml` lines 164-166) and the handlers carry no margins (`StateLayer.qml` lines 164-170). Hover scale 1.04 is visual; whether it also scales the hit box depends on the `StateLayer` target, not checked.
- Painted: a `Card` with `radiusMd` 12 px (`Capsule.qml` line 35), height `Style.controlHeightSm` 32 px (`tokens/deep-night.json` `geometry.controlHeightSm`). Width is about 108 px: 12 inset, 16 glyph, 8 gap, about 60 label, 12 inset.
- Column, from assumed line boxes (title 17 px, one detail line 19 px): icon 24 + 8 + 17 + 8 + 19 + 8 + 32 = 116 px. Action centre sits 42 px below the host centre: D = 42 px.
- W: the approach is vertical, so the width model is the target height, 32 px. Shannon form: ID = log2(1 + D/W) = log2(1 + 42/32) = 1.21 bits.
- Landing tolerance: plus or minus 16 px vertically about the action centre, plus or minus 54 px horizontally.
- Neighbouring interference: none inside `EmptyState`. Host neighbours not examined.
- Popup corridor and timing: not applicable, no popup.

### Findings

Source-backed defects:

| id | pass | element | evidence (source) | expected (source) | actual | severity |
| --- | --- | --- | --- | --- | --- | --- |
| ES-1 (fixed: source-reviewed, load-checked; not owner-accepted) | 2 spacing | action `RowLayout`, `EmptyState.qml` lines 40-44, spacing from line 18 | No `visible` binding on the `RowLayout`, so the `ColumnLayout` lays it out and adds `space2` above it when it is empty. Layouts skip only invisible children (`Capsule.qml` lines 130-135 relies on this). | AGENTS.md component law: an empty slot takes no space. Record line 4 says the action section collapses. | A blank 8 px gap below the title, or below the detail, in every use without an action. The visible group sits 4 px above the host centre. None of the five desktop call sites read here passes an action (`LauncherSurface.qml` 1346, `DashboardTab.qml` 222, `MediaTab.qml` 40, `ClipboardSurface.qml` 258, `CheatSheetSurface.qml` 250). | minor |
| ES-2 | 1 structure | root `ColumnLayout`, `EmptyState.qml` line 8; detail `Prose`, lines 32-39; `Prose.qml` line 114 | Root has no `implicitWidth`. The detail is `fillWidth` and `WordWrap`, but its implicit width is its unwrapped text width (Qt `Text` semantics; not run). | AGENTS.md definition of done 5: natural size is a constant; long content wraps or elides, never grows the control. | With no width set, a long detail widens the column to its unwrapped line length instead of wrapping. No desktop call site sets a width or a detail today, so this is latent. | minor |
| ES-3 (fixed: source-reviewed; not owner-accepted) | record | `docs/components/EmptyState.md` line 4 (existing record, kept unchanged here) | The record says the action section collapses when empty. The source does not (ES-1). | The record says what is true now. | A reader trusts the claim and does not expect the gap. | minor |

Fixes, unverified (no run):

- ES-1: fixed (source-reviewed, load-checked, not owner-accepted): the `RowLayout` at `EmptyState.qml` line 40 is `visible: children.length > 0`, so a slot with no item takes no space and record line 4 is true. A slotted item that is only hidden still leaves the gap, because a hidden child cannot be told from a shown one without reading effective visibility, which the hidden row itself would feed.
- ES-2: add `implicitWidth: Style.controlWidth` to the root after line 18, so the detail wraps at a constant width. A consumer that needs narrower sets `width`. Check that a `Layout` root honours an explicit `implicitWidth` when run.
- ES-3: fixed (source-reviewed, not owner-accepted): record line 4 now matches the source after ES-1.

Redesign proposals (taste, owner's call):

- P-1: the title role is 14 px bold over a 12 px detail, a 2 px step carried by weight. For an empty state that must be read first, `heading` (22 px, `textXl`) would give the message its own level.
- P-2: `icon` is a glyph-name property (`EmptyState.qml` line 13), so the component owns which glyphs exist. A slot would let the consumer pass a glyph, the AGENTS "content goes in slots" law. Changing it touches the `icon: "music"` call site in `DashboardTab.qml`.
- P-3: the muted icon at 8.61:1 is not faint. Keep it.

Hypotheses (observed in source, not measured):

- H-1: a title wider than its host may overflow instead of eliding (`EmptyState.qml` lines 27-31; `Prose.qml` lines 116-118). Nothing gives it a width to elide into, and the minimum width `Layout` assigns a `Text` was not read. Test: set a title wider than the host and capture.
- H-2: `EmptyState` and `Prose` set no accessible role or name. Whether the platform tree exposes `title` and `detail` is unknown. Test: `qsm-uix a11y-tree` on a live host, owned by a11y-audit.
- H-3: the 4 px visual offset in ES-1 and the 42 px D depend on the assumed line boxes. Measured line heights would move both.
- H-4: the muted detail on an overlay passes by 0.01. A surface opacity below 1 or a token change could drop it under 4.5. Not rendered under opacity.

Not examined:

- Runtime: no shell run, no live tree, no captures, no keyboard driving. Hover, focus, wheel and the `Capsule` press are source-reviewed only.
- Themes: light and high-contrast token sets not read.
- Glyphs: `SvgIcon` does not rasterise offscreen, so the icon is judged in a live window only, not here.
- Hosts: the five desktop call sites were read in part (snippets). Scale factor 200 percent and reserved space were not examined.
- Accessibility criteria: a11y-audit's run, not done here. No conformance table is filed.
- Sibling: caelestia `components/controls/` has no empty-state type (a grep for empty and placeholder found none), so there was no sibling comparison.
- Motion: none in source, so none to judge.
