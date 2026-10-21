# Dialog

A modal takeover that dims the ground, traps focus and returns it on close; the surface that opened it owns dismissal policy.
states: open and closed; open fades and settles the card in, close exits it out; the card keeps its shape while invisible so layout never jumps.
actions: slotted controls in the default `actions` slot, declared in reading order (the first takes focus, the last trails); Escape and the scrim only report `dismissRequested`, and close restores focus and emits `closed`. Pass `returnFocusTo` a control that survives the action, because an invoker that is removed or hidden refuses focus and Dialog has no fallback.
pointer: the scrim catches every button so nothing reaches the surface behind; the card absorbs presses on its text and padding so they never dismiss; the body scrolls under a fixed title and actions; during the fade out a shield catches the pointer.
keyboard: focus moves to the first action (the card itself with no action) on open and back to the captured item on close; head and tail sentinels trap tab inside while open; Escape reports only while open. The body has no keyboard scroll route.
screen reader: the card is `Accessible.Dialog` named by `title`; slotted actions name themselves.
size: fixed `dialogWidth`; height follows content up to the window minus `space6` on each side, then the body scrolls; double container margins, radius `radiusXl`; the action row trails in reading order. `tone` is `neutral`, `danger` or `warning`; anything else logs an error and draws neutral.
tokens: controlWidth, space5, space3, space2, iconMd, radiusXl, overlay, accent, danger, warning and Prose; no local colours or measurements.
motion: medium opacity and scale settling with emphasized entry and exit curves; reduced motion shortens the duration.
not designed: modeless popovers, inline messages, form fields or dismissal policy; use Popover, Callout, Field or the host for those.

## UIX audit

Evidence: source-reviewed only. No capture, tree dump, synthetic input or runtime run was made, and
no owner acceptance exists. Contrast figures are arithmetic on `tokens/deep-night.json` values, not
rendered pixels. Geometry is computed from token values and an assumed font, and each assumption is
named. Channels available: source and tokens. Channels missing: live geometry, capture, input.

### Purpose and consequence

- The task it finishes: a consequence the person cannot continue past without answering.
- Consequence when it fails: a click on its own text closes it (D1); a destructive confirm receives
  the first Enter (D2); a long body pushes its buttons off the window (D3).

### Controls, states, implemented

- Expected from the header contract: `open`, `title`, `body`, `tone` (`neutral`, `danger`,
  `warning`), default `actions` slot, `returnFocusTo`, `dialogWidth`, `dismissRequested`, `closed`.
- Implemented: all of them. `warning` has a mark and colour in source (Dialog.qml 46-48, 176).
- Not exercised by the story: `warning`, empty title, empty body, zero actions, long title, long
  body, `dialogWidth` override. The unit's `controls` declare `tone` as `danger` and `neutral` only.
- Card-level hover and press: none. The actions own their five states through `Capsule`.

### Routes

- Pointer: Capsule click activates through StateLayer (Capsule.qml, `onClicked`). Scrim click reports
  `dismissRequested`. A click on the card's non-control area also reports it (D1). Wheel: no card
  target; the Scrim is the wheel's target while shown (see SC1).
- Keyboard: on open, focus enters the first item in declaration order (Dialog.qml 77-79), which is
  the destructive action in the unit (D2). Tab and Shift+Tab are held by `head` and `tail`
  (Dialog.qml 154-157, 208-211). Return, Enter and Space activate a Capsule (Capsule.qml, key handlers).
  Escape reports `dismissRequested` (Dialog.qml 147) only while focus is inside the card.
- Focus return: captured at open (Dialog.qml 97-106), restored at close (108). See D7.
- Screen reader: no role or name is set on the card, title or body. Grep for `Accessible` in
  `Dialog.qml`, `Scrim.qml` and `Card.qml` returns nothing. The actions name themselves through
  Capsule (`Accessible.Button`, name = label). The rest is for a11y-audit.

### Sizes, empty, long, failure, cancellation

- Width: fixed `dialogWidth`, default `Style.controlWidth` = 380 (Tokens.qml 86).
- Height: content-driven, `content.implicitHeight + space5 * 2` (Dialog.qml 124), with no maximum (D3).
- Empty title: the title row and its mark hide together (Dialog.qml 171; D8).
- Empty body: hidden. Zero actions: focus lands on the `tail` sentinel (D5).
- Long title: `Prose` heading is `NoWrap` and `ElideRight` (Prose.qml 114, 118), so it truncates.
  Long body: `WordWrap` with `ElideNone` (Prose.qml 114, 118), so it grows the card (D3).
- Failure: the component has no failure state. The consumer decides what a refused dismissal means.
- Cancellation: Escape and scrim report intent; the consumer closes. Close restores focus (D7).

### Visual roles and palette pairs

- Card: an opaque `overlay` body (Dialog.qml 164, Card.qml `surfaceColor`) with the card's edge
  separation and slight shadow on (defaults).
- Scrim: `band` at `Style.scrimOpacity` (Scrim.qml `strength`). The dim is the band role, not black; the
  shadow token is black.
- Pairs (token arithmetic, default theme, source-reviewed):

  | pair | ratio | criterion |
  | --- | --- | --- |
  | `text` #f0ecf5 on `overlay` #4c4357 | 8.02:1 | 4.5 body text passes |
  | `textMuted` #c5bad1 on `overlay` (the body is `muted`) | 5.04:1 | 4.5 passes |
  | `danger` #f5aeb7 on `overlay` (mark) | 5.17:1 | 3:1 non-text passes |
  | `warning` #d9c284 on `overlay` (mark) | 5.34:1 | 3:1 non-text passes |
  | `accent` #d9b4ea on `overlay` (unknown tone) | 5.19:1 | 3:1 non-text passes |
  | secondary Capsule body (opaque surface #3b3145) with `text` | 10.53:1 | 4.5 passes |

- Destructive Capsule at rest paints nothing (quiet variant), so its `danger` label sits on the
  overlay at 4.63:1.
- Overlay tier: AGENTS places overlay on popouts and menus; a modal on the scrim uses the same tier.
  Recorded as a proposal, not a defect.

### Motion and reduced motion

- Card opacity: `Motion.medium` = 260 ms (Tokens 50). Reduced motion gives 100 ms (Motion.qml 58).
  Enter `standardEasing` (OutCubic), exit `exitEasing` (InCubic) (Dialog.qml 134-139).
- Card scale 0.96 to 1: `emphasizedEasing` in, `exitEasing` out (Dialog.qml 129, 140-145). Reduced
  motion keeps the scale and shortens only the duration. The verdict is review-animations; the
  reduced-motion form is a11y-audit's (2.3.3 is AAA).
- Scrim opacity: `Motion.medium` with the same curves (Scrim.qml 38-43).
- Exit: `enabled` flips at once (Dialog.qml 67), so the Capsule labels and fills change to disabled
  colours for the 260 ms fade (Capsule.qml 65-66, 92-93; `Motion.micro` colour change). The scrim
  stops catching at the same moment (Scrim.qml 47). See D4.

### Pointer geometry

Assumptions, each stated: font family unknown; label advance 0.55 em at `textSm` = 12 px, weight
Medium (`Style.weightMedium`), label centred vertically by the Capsule fill; icons 20 px; `contentInset`
`space4` = 16 px per side; gap `space2` = 8 px; card 380 px wide with 24 px inset; card height estimated
at 165 px (title line 26, one body line 19, gaps 12, actions margin 8 and height 40). The invoker's
position is unknown, so the pointer is modelled as entering from the dialog centre. D is measured
from the card centre. Width model: the Capsule width is icon 20 + gap 8 + label + 2 x 16.

| target | input shape | painted | size (estimate) | D (px) | W (px) | ID (bits) |
| --- | --- | --- | --- | --- | --- | --- |
| Scrim | whole window | band at 0.55 | window | n/a | n/a | n/a |
| card non-control area | card rectangle (not absorbed, D1) | card, radius 20 | 380 x 165 | n/a | n/a | n/a: dismisses |
| Keep (secondary) | Capsule rectangle | radius 12 | 86 x 40 | 41 | 40 (height) | 1.03 |
| Remove (destructive) | Capsule rectangle | radius 12 | 100 x 40 | 122 | 40 (height) | 2.02 |
| Remove, dominant x approach | as above | as above | as above | 122 | 100 (width) | 1.16 |

ID = log2(1 + D/W). The W=40 row is the conservative case for a vertical approach; the dominant-x
row is the case for a horizontal one.

- Input versus paint: the Capsule's hit box is its bounding rectangle. At radius 12 the corners
  outside the painted arc are 3.1 percent of the hit box, so a press there activates with nothing
  painted under it. Not a defect at this size.
- Landing tolerance: 40 px high, above the 24 px WCAG 2.5.8 floor on both axes (source size, not
  measured).
- Neighbour interference: Remove's left edge is 8 px from Keep's right edge (0.2 W). Any landing more
  than 8 px past Keep's right edge is on the destructive action. The gap is the system's common value;
  the cost is the destructive default (D2), not the gap alone.
- Popup corridor and timing: not applicable, no hover-driven open. Open and close each 260 ms; clicks
  during the close fade are not caught (D4).

### Fix status

Source-reviewed and load-checked (one capture load, exit 0, no QML error); runtime behaviour and owner acceptance are not claimed.

- D1 fixed: the card carries a `MouseArea` that takes every press, declared before the content.
- D2 fixed: `RightToLeft` is gone, a filler `Item` leads `actionHost`, actions are declared in reading order (the unit declares Keep first).
- D3 fixed: the card height is capped at the window minus `space6` per side and the body is in a `ScrollArea` between the fixed title and actions.
- D4 fixed: `enabled: root.open` is gone; a shield `MouseArea` catches the pointer after `open` drops, focus inside the fading card moves to the card, and Escape reports only while open. Tab can still reach a fading action for the 260 ms.
- D5 fixed: the first-focus target is rejected when it is `tail`, so the card takes focus.
- D6 fixed: the card sets `Accessible.role: Accessible.Dialog` and `Accessible.name: root.title`; a11y-audit still rules the criterion.
- D7 resolved by contract, no code: the consumer passes `returnFocusTo` a surviving control (header contract and the `actions` line above).
- D8 fixed: the title row shows for a title or a mark, and the mark follows the tone alone.
- D9 fixed: tones map explicitly (`neutral`, `danger`, `warning`); an unknown tone logs `console.error` and draws neutral without a mark.

The Findings below describe the state before these fixes. The unit now declares Keep before Remove, adds the `warning` tone and a long-body control.

### Findings

Defects (source-reviewed; file and line cited; consequence is what a person sees):

- D1, major, Dialog.qml 119-.: The card has no pointer handler, so a press on its title, body or
  padding is not accepted by it and falls through to Scrim.qml 45-52, which reports `dismissed`.
  Person sees: the dialog closes when they click its text. Fix: a `MouseArea { anchors.fill: parent;
  acceptedButtons: Qt.AllButtons }` as the card's first child, with no handler, so it takes presses
  and the Scrim never sees them. Capsules declared later stay on top. Shared: no.
- D2, major, Dialog.qml 200 and 77-79; workbench/units/Dialog.qml 37-47: `layoutDirection:
  Qt.RightToLeft` puts the first declared action on the right, but focus follows declaration order.
  The unit declares Remove first, so the dialog opens with Remove focused, and Enter removes the
  device. Tab then goes to Keep on the left, against the visual order. The header's "trailing edge
  last" and Dialog.md's "reading order" both assume the opposite. Fix: drop `RightToLeft`, add
  `Item { Layout.fillWidth: true }` as the first child of `actionHost` so the leading space fills, and
  have consumers declare actions in reading order. Which action takes focus first is P1. Shared: no.
- D3, medium, Dialog.qml 124: The implicit height has no maximum and nothing scrolls. A long body
  pushes the title above and the actions below the window edge; both sit outside the viewport and
  the pointer cannot reach them. Fix: cap the card's height to the parent with a margin, and put the
  body in a scroll container (ScrollArea) that keeps the title and actions fixed. Shared: no.
- D4, minor, Dialog.qml 67; Scrim.qml 47; Capsule.qml 65-66, 92-93: `enabled: root.open` turns
  the card's content disabled on the first frame of close, so buttons grey out during the 260 ms fade
  while the card is still visible. Scrim.qml 47 also drops the catch at the same moment, so a click
  during the fade reaches the surface behind. Person sees: buttons dim as the dialog leaves, and a
  click there reaches the ground. Fix: keep pointer and key answering gated on `root.open` but keep
  the painted colours and the catch until the fade ends (the owner chooses the mechanism). Shared: no.
- D5, minor, Dialog.qml 77-79: With zero actions, `head.nextItemInFocusChain(true)` returns `tail`,
  which passes the `_holds` test, so focus lands on the invisible sentinel and never on the card.
  Person sees: no focus indicator; Tab cycles on nothing. Fix: `if (first && first !== tail &&
  root._holds(first))`, so the card takes focus (it has `focus: true`). Shared: no.
- D6, minor, Dialog.qml 119- (no `Accessible` in the file): the card declares no role and no name, so
  a screen reader gets no dialog announcement and no title. Dialog.md says it does. Fix:
  `Accessible.role: Accessible.Dialog` and `Accessible.name: root.title` on the card. This is
  a11y-audit's to rule; it is listed here because the source has no such attribute. Shared: no.
- D7, minor, Dialog.qml 108: On close, `root._returnTo.forceActiveFocus()` runs with no check.
  An invisible or disabled item refuses focus silently (the file's own comment at 100-104 says so for
  the open side), and a destroyed item becomes null with no fallback. Person sees: when the confirm
  removes the row that opened the dialog, focus leaves the window and the next Tab starts at the top.
  Fix: the consumer passes `returnFocusTo` to a control that survives the action, and Dialog.md says
  so. Dialog does not guess a fallback (one path). Shared: no.
- D8, minor, Dialog.qml 171: The title row, which holds the tone mark, is hidden when the title is
  empty. A danger dialog with no title loses its mark, and the header says severe dialogs carry one.
  Fix: show the mark on `tone !== "neutral"` separately from the title. Shared: no.
- D9, minor, Dialog.qml 46-48, 176: Any tone other than `danger` gets the triangle mark, and any tone
  other than `danger` or `warning` takes the accent colour. A typo or a new tone shows a warning
  triangle in lilac. Fix: map each named tone explicitly; an unknown tone is an error in the consumer,
  not a second look. Shared: no.

Proposals (taste or design; the owner decides):

- P1: Focus the safe action first in a destructive dialog. The fix for D2 makes this a declaration
  order choice: cancel declared first puts Keep at focus.
- P2: No visible close control exists, so Escape and a scrim click are the only exits by pointer
  without a Cancel. Consider an optional close glyph in the title row.
- P3: Under `Style.reducedMotion`, drop the scale term and keep only the opacity fade.
- P4: Icon and heading alignment in the title row: fill and centre both, as the Capsule does (H2).
- P5: Gap rhythm: 12 between title and body, 20 (12 plus 8 margin) between body and actions. Deliberate
  or not, one rhythm is easier to defend.

Source conflicts (the owner decides which wins):

- SC1: Dialog.md says "the card keeps its own targets and wheel passes through to content". The card
  has no wheel target and no scroll (D3), and AGENTS.md records that a MouseArea consumes the wheel
  unless `accepted = false`, so the Scrim takes it. The doc claim is not supported by the source.
- SC2: Dialog.md says "the action row trails in reading order". Dialog.qml 200 reverses the visual
  order without reversing focus (D2).
- SC3: Dialog.md says "title and body are heading and body text". Source sets no role on either (D6).
- SC4: AGENTS.md component law 5: "Natural size is a constant. Long content scrolls or elides, never
  grows the control." Dialog's height is content-driven (Dialog.qml 124). The law is written for
  controls; whether a dialog falls under it is the owner's ruling.

Hypotheses (observed in source, not measured):

- H1: `onOpenChanged` may not fire for an initial `open: true`. The story "Dialog / Open"
  (stories.json 1012-1027, unit `open: variant === "open"`) would then never run focus entry or
  capture the return target. Basis: Dialog.qml 97-108. Verify only on request.
- H2: The title row (Dialog.qml 165-185) has no fill or vertical alignment, unlike Capsule. AGENTS.md
  records a half-pixel offset from baseline alignment in a RowLayout. Unmeasured.

Not examined:

- Runtime: no capture, no tree, no input, no focus or pointer run. Accepted by the owner: none.
- Themes beyond deep-night (light, high contrast) and the `warning` tone: not examined.
- Scaling of text, and icon rendering (SvgIcon does not rasterise offscreen; AGENTS.md).
- Motion verdict: review-animations. Reduced-motion form and screen-reader behaviour: a11y-audit.
- Consumers: none known. caelestia has no Dialog control in `components/controls/`;
  `components/filedialog/FileDialog.qml` is a file picker, not a sibling.
- `design/MASTER.md` was not looked for. The design source used is AGENTS.md (component laws and
  surface ladder) and `tokens/deep-night.json`.
