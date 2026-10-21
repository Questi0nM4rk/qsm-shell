# SelectionMark

The pure visual tick that marks a selected row; the row owns the semantics and the mark only shows them.
states: hidden and shown; `strong` marks the keyboard-current row wider and opaque while a resting tick dims through `restOpacity`.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: none; the owning row carries the selectable name and state.
size: mark thickness by mark height with pill radius; hidden collapses height and opacity together; the consumer positions it in the row layout.
tokens: markThickness, markHeight, spaceTight and accent; no local colours or measurements.
motion: micro height, opacity and width settling with emphasized and exit curves; reduced motion shortens the durations.
not designed: selection state, focus or activation; use ListRow, Menu or the host for those.

## UIX audit

Evidence: source-reviewed only. Runtime-exercised: none (no preview, capture, input or tree dump was run). Owner-accepted: none.

### Purpose and consequence

Marks the one current row of a list. The person learns which item is current from the mark's presence and width. Its only live caller is `NotificationCard.qml:324` (`strong: true`, `shown: root.selected && !root.bodied`). `docs/components/ListRow.md:15` and `docs/USAGE.md:76` name SelectionMark as a ListRow or Menu part, but no `ListRow.qml` or `Menu.qml` instantiates it (grep over `qml/`), so those mentions are stale.

### Controls and states

- Expected by this record: `shown`, `strong`, `restOpacity`, plus the colour override `markColor`.
- Implemented: `shown` (bool, false), `strong` (bool, false), `markColor` (colour, `Style.accent`), `restOpacity` (real, 1). Plain properties only; no function, signal or action.
- Valid states: hidden or shown; normal or strong; full or dimmed. `strong` overrides the dim (`SelectionMark.qml:38`), so strong-and-dimmed draws at opacity 1 by design.
- Unit: `visibility`, `emphasis` and `rest` controls (`workbench/units/SelectionMark.qml:27-40`). One story key, `SelectionMark / Shown` (`workbench/stories.json:1104`). Hidden, strong and dimmed are reachable only through the controls.

### Routes

- Pointer: none. The root is a bare `Rectangle` with no handler, so it claims no events and the wheel passes through.
- Keyboard: none. Not a tab stop.
- Focus: none.
- Screen reader: none. Neither the mark nor the unit sets `Accessible`. Whether the selected state reaches assistive technology depends on the owning row; `NotificationCard.qml:112-117` sets `Accessible` only for its primary action. That question is a11y-audit's.
- Programmatic: the four properties, set by the host.
- Cancellation and reset: not applicable; no pending work.

### Sizes, empty and long content, failure

- Sizes: one, not a preset. Thickness `Style.markThickness` 3 and height `Style.markHeight` 18 (`tokens/deep-night.json:106-107`). Strong width is 3 + `Style.spaceTight` 2 = 5 (`SelectionMark.qml:34`).
- Empty and long content: not applicable.
- Failure: none.

### Visual roles and palette pairs

- Role: `accent` (`#d9b4ea`, `tokens/deep-night.json` `color.accent`) on the unit's `band` (`#271e30`). Computed from the token hex values: 8.87:1 at full opacity.
- Dim rest state: the unit sets `restOpacity` 0.35 (`workbench/units/SelectionMark.qml:24`). Blended over band that is `rgb(101,82,113)` at 2.30:1, below the 3:1 non-text line. Whether the criterion applies is a11y-audit's ruling. The 0.35 is a literal in the unit, not a token.
- Disabled colour: `NotificationCard.qml:327` uses `Style.disabled(Style.accent)`, which follows the opaque-blend rule of AGENTS.md.
- Surface ladder: the mark has no surface of its own. The consumer's surface is not measured here.

### Motion and reduced motion

Judged by review-animations; values only, from source. Height and opacity use `Motion.micro` (130 ms) with `emphasizedEasing` (OutQuart) on show and `exitEasing` (InCubic) on hide (`SelectionMark.qml:42-53`, `Motion.qml:120-125`). Width uses `Motion.micro` with `moveEasing` (InOutCubic) (`SelectionMark.qml:55-57`). Reduced motion sets `Motion.micro` to 60 ms (`Motion.qml:26`); height and width still change, only shorter. Entry and exit durations are equal.

### Pointer geometry

- Input shape: none. Painted size: 3 x 18 normal, 5 x 18 strong, radius width / 2.
- Input shape against painted size: not applicable, the mark takes no input.
- D, W, ID: not applicable; no target and no distance are modelled. Conditional only: if a host made the mark the target, the painted box sits below the 24 x 24 px floor that ux-audit check 3 cites (WCAG 2.5.8), so that host would need its own hit area.
- Label origins and weights: no label.
- Trajectories: none modelled.

### Findings

Defects (source-backed):

1. `SelectionMark.qml:17-58`. The root sets no `implicitWidth` or `implicitHeight`, so to any layout the mark is 0 x 0. qml-ui requires a reusable component to set both. A host that places it in a RowLayout or ColumnLayout would see no mark at all. Latent: the only caller uses anchors. Severity minor. Fix: `implicitWidth: width` and `implicitHeight: height` in the component; height is 0 while hidden, which the layout should honour. shared: false. Fixed (source-reviewed, load-checked): the root sets `implicitWidth: width` and `implicitHeight: height`.
2. `workbench/units/SelectionMark.qml:19-25`. `anchors.centerIn` on a 380-wide parent (`Style.controlWidth`, `tokens/deep-night.json` `controlWidth`) puts x at 188.5 for the 3 px pill and 187.5 for the 5 px pill. A half-pixel x blurs a 1 px edge (qml-ui, "Integer geometry"), so the person would see soft pill edges in the unit. Inferred from arithmetic, not captured. Severity minor. Fix: place the unit's mark with `x: Math.round((parent.width - width) / 2)`. shared: false. Fixed (source-reviewed, load-checked): the unit uses `anchors.verticalCenter` and `x: Math.round((root.width - width) / 2)`.
3. `SelectionMark.qml:32` with `workbench/units/SelectionMark.qml:24`. No live caller uses `restOpacity`, but its dim level is 2.30:1 against band. If the owner keeps the dim as meaning, it fails the 3:1 non-text line. Severity minor. Fix: owner ruling, either remove `restOpacity` and the `rest` control, or move its dim value to a Style token that passes the line the owner picks. shared: true, because the token route touches `qml/QsmShell/Style/*` and `tokens/*`.

Redesign proposals (taste or simplification, not defects):

- Remove `restOpacity` and the `rest` control unless a caller returns. Nothing uses them.
- Delete the history in `SelectionMark.qml:5-16` (four past copies, the restated "3x18"). AGENTS.md keeps history out of source. Delete also the urgency-tick paragraph at `SelectionMark.qml:26-31`, which describes a consumer that no longer exists (see source conflicts).
- `workbench/units/SelectionMark.qml:10` declares `eventRecorder`, which nothing in the unit reads. Delete.
- `SelectionMark.qml:36` computes the pill radius as `width / 2`, while `tokens/deep-night.json` `radius.pill` (999) exists. The result is the same at these sizes; Qt's clamp is not verified. Polish.
- Strong is 2 px wider and the same colour. Whether 3 px against 5 px is enough for a cursor is taste; the owner judges it in a live window.
- A cursor moving between rows is two marks, one leaving and one arriving. Whether one mark should travel is a motion question for review-animations and the owner.
- A catalog key for hidden and for strong would make those states reachable without the controls. `workbench/stories.json` is shared, so this waits for an owner's go.
- The consumer animates the mark on every selection change, keyboard cursor moves included. Whether that is allowed is review-animations' call. The component offers no way to set the mark without its transition.

Source conflicts:

- `SelectionMark.qml:26-31` says a notification's urgency tick dims through `restOpacity`. `NotificationCard.qml` says "Urgency has no tick (the glyph carries it)". The code and the consumer agree; the comment is the stale party.
- `docs/components/ListRow.md:15` and `docs/USAGE.md:76` name SelectionMark in ListRow and Menu. No ListRow or Menu source uses it. Outside this record; a remark, not a task.
- Exit curve: `Motion.qml:123-125` says an exit accelerates away, while the qsm-uix review-animations standard 3 says exits use ease-out. The repo's rule and the standard conflict; the owner decides. Standard 4 also wants an exit about 80% of the entry, and here they are equal. The motion verdict is review-animations'.

Hypotheses (not measured):

- `NotificationCard.qml` centres the mark with `anchors.verticalCenter: headline.verticalCenter`. With an odd headline height that gives a half-pixel y for the 18 px mark. The headline height is not measured.
- Finding 2's soft edge would also appear in a live window. Not captured.
- The row's selected state may not reach assistive technology. That is a11y-audit's question.

Not examined:

- Runtime: no preview, capture, input or tree dump was run; none was requested.
- Themes: `tokens/` holds only `deep-night.json`. Light and high-contrast have no source here.
- Keyboard, screen reader, and the 1.4.11 ruling: a11y-audit.
- Motion timing: review-animations.
- qsm-desktop: a grep over `qsm-desktop/shell` found no SelectionMark use.
- `tests/interaction/tst_library.qml:92` instantiates the mark; not run, not requested.
