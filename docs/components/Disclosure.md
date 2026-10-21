# Disclosure

A collapsible heading over an indented content slot; the host owns `expanded` and answers every toggle.
states: expanded and collapsed; the chevron rests at a right angle when open and flat when closed, and collapsed content is not laid out at all.
actions: enumerated `toggle()` reports `toggled(!expanded)`; the native heading button, Space, Enter/Return, accessibility and callers share it. `expanded` never changes inside the component.
pointer: the whole heading is the target with a StateLayer swell on the chevron; wheel does nothing and propagates.
keyboard: tab reaches an enabled heading and Space and Return share the toggle route; the focus mark forwards to the StateLayer.
screen reader: one named toggle-button heading reports checked state and an Expanded/Collapsed description; the badge is supporting information.
size: heading at control small height with fixed row spacing; content hangs from the title's left edge (chevron, optional icon and gaps), 8 px below the heading; long titles elide rather than growing the heading.
tokens: the Control size table, space1, space2, iconSm, Motion.pressScale, radiusSm, text roles and Badge; no local colours or measurements.
motion: fast chevron rotation plus StateLayer hover and press swell; reduced motion shortens the duration.
source: compared caelestia `ButtonBase.qml`'s StateLayer activation; rejected its internal toggle state and palette. Qt's native AbstractButton supplies heading input/focus while the host keeps expansion.
expected: enumerated `toggle()` is the single pointer, Space, Enter and programmatic route. It reports `toggled(!expanded)` once without writing host state, refuses when unavailable, and exposes one named focusable heading with expanded accessibility state.
not designed: selection, menu disclosure or asynchronous content; use Segmented, Menu or the host for those.

## UIX audit

Evidence: source-reviewed only. No preview, capture, tree dump, key or pointer driving was run, and live geometry was not read. Owner acceptance: none. Design source: the component laws and surface ladder in `AGENTS.md`, and the values in `qml/QsmShell/Style/Tokens.qml`.

### Purpose and consequence

Opens rare or advanced detail under a heading without that detail taking room in the closed state. A wrong heading either hides something a person needs, or shows an open group as closed.

### Controls and states

- Unit controls (`workbench/units/Disclosure.qml`, lines 41-58): expansion (open, closed), badge (count, none), icon (shown, none), state (enabled, disabled). All four are implemented.
- Not in the unit: empty title, long title.
- Implemented states: expanded and collapsed (host-owned), enabled and disabled. Disabled gates input and dims the chevron, icon and label by colour; the Badge stays at full strength, see D1.

### Routes (source)

| Route | Real path | Source |
| --- | --- | --- |
| Pointer click | heading `clicked` calls `toggle()` | Disclosure.qml:51, :37-40 |
| Pointer hover | chevron grows through StateLayer `target: chevron` | Disclosure.qml:93-103 |
| Space | Qt AbstractButton emits `clicked` on release, which calls `toggle()` | Disclosure.qml:44, :51 |
| Return, Enter | `Keys.onReturnPressed` and `onEnterPressed` call `toggle()` | Disclosure.qml:58-59 |
| Wheel | no wheel handler on the heading, so the wheel reaches the parent | Disclosure.qml:44-104 |
| Focus | `focusPolicy: StrongFocus`; `focused` is `heading.visualFocus` | Disclosure.qml:30, :49 |
| Programmatic | `actions` entry `toggle`; unit `runAction` | Disclosure.qml:35; unit :60-75 |
| Accessibility | Button role, name is the title, checkable and checked, description Expanded or Collapsed | Disclosure.qml:52-57 (see hand-off) |

Failure and cancellation: `toggle()` refuses when disabled (Disclosure.qml:38). No async content, so no cancellation path. An empty title has no guard and shows a bare chevron.

### Sizes, empty and long content

- Heading height 32 px (Control `sm`). Width comes from the host (unit 380 px, `controlWidth`).
- Body indent is the title's x (`titleLabel.x`): 24 px without the icon, 48 px with it; the body follows the title.
- Long title: the label is a Prose `label` role with `elide: ElideRight` (Prose.qml), so it truncates inside the row. Whether the natural width grows is H1.

### Visual roles, motion and reduced motion

- Chevron `textMuted` (Disclosure.qml:69). Icon `text` (:80). Label Prose `label` role, colour `text` (Prose.qml). Badge `neutral` tint (Badge.qml). Focus ring `Style.accent` (StateLayer default `focusColor`). Palette pairs were not measured.
- Chevron rotation 0 to 90 degrees over `Motion.fast`, 180 ms (Tokens.qml:49), easing `Motion.moveEasing` (InOutCubic, Motion.qml:128). Measured from source only.
- Hover response: `Motion.hoverScale` on the chevron plus a `Style.tone` disc over the heading. Press response: `Motion.pressScale`. Both from tokens.
- Body: appears and disappears with no transition.
- Reduced motion: `Motion.fast` becomes 80 ms (Motion.qml:56). The rotation still plays. See S1.

### Pointer geometry (assumptions labelled)

- Input shape: the whole heading row, host width by 32 px, no padding. Painted content: chevron 16 by 16 px at x 0-16, label, optional icon 16 px, badge at the right end. The unpainted right part is also input.
- Painted against input: the glyph is 16 px inside a 32 px row (50 percent of the row height). The row is 32 px high, above the 24 px pointer floor in WCAG 2.5.8 (criterion from `a11y-conformance`; not measured). No touch route exists in source, so the 44 px touch floor is not applicable.
- Width model: nominal, geometry size with no effective-width correction, because no trajectory data exists. Assumption: a stack of disclosures separated by `space1` (4 px, Disclosure.qml:42), with the pointer arriving from the centre of the previous row. This is a modelled trajectory, not a human average.
- Vertical approach: D = 32 + 4 = 36 px, W = 32 px, ID = log2(1 + 36/32) = 1.09 bits.
- Horizontal approach: W = 380 px (the full row), so ID is at most log2(1 + D/380), which is at most 1 bit for any D inside the row. The vertical axis is the limit.
- Landing tolerance: plus or minus 16 px vertically from the row centre; the full row width horizontally.
- Neighbour interference: the gap from the heading to the body is 4 px (Disclosure.qml:42 and :114). See H4.
- Trigger-to-panel corridor and timing: not applicable, the component is not a popup and does not open on hover.

### Findings

- D1 (minor, shared): a disabled heading dims the chevron, icon and label by colour, but the Badge stays at full strength. `Badge.qml` needs to dim when its host is disabled.
- D2 (owner choice): the body indents to the title (`Layout.leftMargin: titleLabel.x`). The owner may prefer the chevron-only indent, which would put the body at 24 px against a 48 px title when the icon is shown.

### Hypotheses (not measured)

- H1: a long title may widen the heading's natural width rather than eliding. The heading sets no `implicitWidth` (Disclosure.qml:44), and whether the AbstractButton's implicit width includes the row depends on how its children attach. Check in the tree with an 80-character title.
- H2: wrapping body text needs the host to give it `Layout.fillWidth`. The body slot does not set it (:109-115) and the unit's body Prose has none (unit :34-38). Check with a wrapping body.
- H3: keyboard focus inside the body is lost when the group collapses, because `visible: false` removes it from focus. Check with focus inside the body and a programmatic collapse.
- H4: body controls within 4 px of the heading can take an overshoot below the heading. Applies only if a host puts targets in the body.
- H5: `Style.accent` for the focus ring may be under 3:1 against the band (WCAG 1.4.11). The palette value was not read, so this needs a capture.

### Source conflicts

- S1: AGENTS says a one-shot position animation is removed under reduced motion, not shortened, and also says reduced motion shortens a duration (Motion.qml:56). The chevron is a rotation, not a position, so the code follows the shortening rule. review-animations standard 8 says to drop movement. The owner decides which rule governs a rotation.

### Hand-off to review-animations (motion verdict is theirs)

- The chevron animates on keyboard toggles too. The standard says keyboard-initiated actions get no animation, and `toggle()` carries no origin, so the component cannot tell the two apart.
- The body snaps open while the chevron turns over 180 ms, so the state change and its indicator finish at different times.

### Hand-off to a11y-audit (criteria are theirs)

- The accessible name is the title only, so the badge count is not spoken.
- The state is given twice, as checkable and checked and as the description Expanded or Collapsed. Verify what the tree reports.
- An empty title leaves the button unnamed.

### Needs human trial

- Keyboard focus ring in each theme: Tab to the heading, expanded and collapsed, and read the ring against its neighbour.
- Pointer feel: hover and press on the chevron and the whole row, and the 32 px target at the stack gap.
- Screen reader: name, role and state of the heading after Space and Enter.

### Not examined

- No runtime: no preview, capture, tree dump, key or pointer driving.
- Themes: only the deep-night values were read; the light theme was not.
- Long title, wrapping body and empty title: not rendered.
- Touch: no touch route in source.
