# Capsule

A compact labeled action, selection or status control for panel tabs and popout commands; the host owns active and any in-progress state.
states: rest, hover, press, focus, disabled and active; active is lavender identity over the current surface, primary is a filled `primary` body with `textOnPrimary` content, ghost and destructive show a lifted body under hover and press, focus rings the control body (radiusMd with a label, pill without), disabled dims each painted role through Style.disabled rather than composite opacity.
actions: pointer click, Space, Enter and the actions entry call activate() and emit clicked; active never changes inside the component.
pointer: the full body is the target and reports a hand; wheel does not claim the event.
keyboard: tab reaches an enabled capsule, click takes focus, and Space/Enter activate the same route.
screen reader: Accessible.Button names the label, or `accessibleName` when glyph-only (a capsule with neither warns once); `checkable: true` marks a toggle and exposes `active` as checked; detail is a muted reading, not a second action.
size: sm, md and lg use the control-height scale; icon, type and insets scale as their own roles, while radius and focus gap remain constant.
tokens: controlHeight, icon scale, text scale, space scale, surface ladder, accent, danger, Motion and StateLayer; no local colors or measurements.
motion: subdued capsule hover and press response plus color settling; reduced motion shortens the duration, never invents another state.
not designed: asynchronous progress, confirmation and menu disclosure; callers state progress in label/detail and surfaces own the next layer.

## UIX audit

Evidence: source-reviewed only. Runtime-exercised: none. Owner-accepted: none. Method: the qsm-uix
ui-audit, ux-audit, a11y-audit, review-animations and qml-ui skills, judged against AGENTS.md (component
laws, surface ladder). Sibling comparison: caelestia has no Capsule; its nearest pattern is
`components/controls/ButtonBase.qml` and `IconTextButton.qml`. Ratios below are arithmetic on the hex
values in `tokens/deep-night.json` with the Card at `surfaceOpacity` 0.9 over `band`; they are not pixels.

### Task and consequence

The compact action, selection or status pill of panel tabs and popout commands. A click or Enter, Space
calls `activate()`, which emits `clicked`; the host decides the consequence. `active` is host-owned and
shows identity. Consumers (all `size: "sm"` except MediaTab): BluetoothPopoutContent.qml:39, 53, 102;
NetworkPopoutContent.qml:211, 231, 451; SoundPopoutContent.qml:116; DashboardTab.qml:125;
MediaTab.qml:253. No consumer sets `variant`, `detail` or `radius`.

### Expected controls, states, implemented

| Item | Implemented | Where |
| --- | --- | --- |
| rest, hover, press, focus, disabled, active | yes | StateLayer, Capsule.qml:92-99 |
| variants ghost, secondary (default), primary, destructive | yes; no caller | Capsule.qml:57-65, 92-93 |
| sizes sm, md, lg | yes, by ternaries, not `Style.size` | Capsule.qml:71, 73, 137, 149 |
| icon, label, detail (reading) | yes | Capsule.qml:126-158 |
| glyph-only (no label) | yes, pill radius, no accessible name | Capsule.qml:35, 53 |
| failed, busy, loading, indeterminate | no (doc: host states progress in label or detail) | docs/components/Capsule.md:12 |

### Routes

- Pointer: TapHandler in StateLayer (StateLayer.qml:170-183), hand cursor (StateLayer.qml:167). Wheel:
  no WheelHandler in Capsule or StateLayer, so the wheel is not claimed (source-reviewed only).
- Keyboard: `focusPolicy: Qt.StrongFocus`; Return, Enter and Space call `activate()` on key press
  (Capsule.qml:177-179). Tab reaches an enabled capsule only.
- Focus: the ring is StateLayer's, visible when `focused && !_pointerFocus` (StateLayer.qml:152). Capsule
  passes `focused: root.focused` (= `activeFocus`, Capsule.qml:46, 168); a pointer click is kept off the
  ring by StateLayer's tap (StateLayer.qml:175-181).
- Accessibility: `Accessible.role: Button`, `Accessible.name: label` (Capsule.qml:52-53). No checkable,
  no checked, no description for `detail`.
- Programmatic: `actions` holds one `T.Action` that calls `activate()` (Capsule.qml ~84-86).

### Sizes, empty and long content, failure, cancellation

| size | height | inset | icon | label | gap |
| --- | --- | --- | --- | --- | --- |
| sm | 32 (controlHeightSm) | 12 (space3) | 16 (iconSm) | 10 (textXs) | 8 (space2) |
| md | 40 (controlHeight) | 16 (space4) | 20 (iconMd) | 12 (textSm) | 8 |
| lg | 52 (controlHeightLg) | 24 (space5) | 24 (iconLg) | 14 (textMd) | 8 |

Radius 12 (radiusMd) with a label, 999 (pill) without (Capsule.qml:35). Focus gap and ring stroke are
spaceTight (2 px). Empty (no label, no icon): a bare pill of 2 x inset wide, with no accessible name.
Long: width is content-derived, with no maximum (Capsule.qml:74; the label Prose at 140-150 has no
constraint, so its ElideRight never applies). Real cases: NetworkPopoutContent.qml:218 ("Wi-Fi OFF ·
click to enable") and MediaTab.qml:256 (`modelData.identity`, unbounded). Failure: no error state.
Cancellation: no cancel path; activate() returns nothing and does not check the host's busy state.

### Visual roles and palette pairs (declared tokens)

| pair | ratio | basis |
| --- | --- | --- |
| label text on secondary rest | 9.78 | text #f0ecf5 on surface #42394c at 0.9 over band #271e30 |
| accent label on active body | 5.07 | accent #d9b4ea on accent 12 % over surface, at 0.9 over band |
| text label on primary body | 7.83 | same body as active, text colour (see D5) |
| ghost label at rest | 8.61 | textMuted #c5bad1 on band, no body at rest |
| ghost label on hover | 13.71 | text #f0ecf5 on band, no body |
| destructive label | 8.84 | danger #f5aeb7 on band, no body |
| focus ring against band | 8.87 | accent #d9b4ea on band; the real neighbour is the host's colour, unknown |

Not computed: the hover lift (`Style.lift` bisection), `Style.disabled`, and the card shader's edge tint.
The WCAG 1.4.11 verdict on the ring is a11y-audit's.

### Motion and reduced motion

- Hover: StateLayer response 1.04 (`Motion.capsuleHoverScale`, Tokens motionCapsuleHoverScale), 130 ms
  OutCubic (`Motion.micro`, StateLayer.qml:126-131). Colour: `Behavior on surfaceColor`, 130 ms
  (Capsule.qml:101-103).
- Press: response goes to `pressScale` 1 over `Motion.press` 80 ms. No press scale, colour only on a body.
- Reduced motion: `Motion.micro` becomes 60 ms (Motion.qml:26). The 1.04 growth is still played.
  See S1.

### Pointer geometry (assumptions are labelled)

- Input shape: StateLayer `anchors.fill: parent` (StateLayer.qml:166), which is the Capsule's implicit box.
  The painted Card fills the same box (Capsule.qml:110-114). At rest, input shape equals painted box. The
  hit test is rectangular (item bounds, not the 12 px corner), so each corner has an unpainted area of
  12^2 (1 - pi/4) = 30.9 px^2 that still hovers. Glyph-only pills (radius 999) have unpainted ends outside
  the semicircle. Source-reviewed Qt behaviour, unverified at runtime.
- Hover growth: scale 1.04 grows the box by 0.02 H per side: sm 0.64 px, md 0.80 px, lg 1.04 px. Exit is
  therefore 0.02 H further out than entry.
- Width model: W_vertical = H (32, 40, 52). Landing tolerance is H/2 = 16, 20, 26 px.
  W_horizontal = implicitWidth = 2 x inset + icon + 8 + label advance (+ 8 + reading). The label advance is
  not rendered in this audit, so the horizontal W and horizontal ID are not computed.
- ID = log2(1 + D/W). D is an assumed vertical travel, not measured and not a human average:

| D (vertical, assumed) | sm H 32 | md H 40 | lg H 52 |
| --- | --- | --- | --- |
| 100 px | 2.04 bits | 1.81 bits | 1.55 bits |
| 200 px | 2.86 bits | 2.59 bits | 2.28 bits |
| 400 px | 3.75 bits | 3.46 bits | 3.12 bits |

- Label origin (assumed): the icon and label group is centred in the box, so the label centre sits
  (icon + 8) / 2 px off the box centre toward the label: sm 12 px, md 14 px, lg 16 px. Vertically the label
  box is centred; the ink centre is unmeasured.
- Label weight (assumed from the role): label takes `Style.weightMedium` (Font.Medium, Prose.qml default).
  Not rendered.
- Corridor: not a popup, not applicable.
- Neighbour interference: row spacing is the host's, not read. Grown hover boxes of two neighbours overlap
  in a gap below 0.04 H: sm 1.28 px, md 1.60 px, lg 2.08 px (hypothesis H5).

### Fix status

Fixed, source-reviewed and load-checked (qmllint, one-scenario capture), not owner-accepted: D2, D3, D4,
D5, D7, D9, D10. D4 took the first option (reveal the body on hover and press for ghost and destructive)
as a placeholder for the owner's ruling. Callers whose `active` is a toggle (BluetoothPopoutContent.qml:44,
NetworkPopoutContent.qml:221, MediaTab.qml:257) must set `checkable: true` in qsm-desktop to be announced as
toggles. Open: D1, D6, D8, S1.

### Findings

Defects (source-backed; the record names the line that proves each):

- D1, major: a long label widens the control. Capsule.qml:74 has `implicitWidth` from content with no cap.
  A person sees a player name (MediaTab.qml:256) or the Wi-Fi OFF text (NetworkPopoutContent.qml:218) push
  the pill wider than its neighbours. AGENTS: natural size is a constant. Fix: cap the label at a
  Style-owned width (a size token is needed, so shared).
- D2, medium: `active` is not exposed to the accessibility tree (Capsule.qml:52-53). It is a toggle at
  BluetoothPopoutContent.qml:44, NetworkPopoutContent.qml:221, MediaTab.qml:257. A screen reader gets
  "button" and the name only. Fix: expose checkable and checked where the host marks a toggle. The criterion
  verdict is a11y-audit's.
- D3, low: a glyph-only capsule has an empty accessible name (Capsule.qml:53; the pill radius at :35). No
  caller uses it. Fix: refuse an empty label, or require a host-supplied name; no silent empty name.
- D4, medium: quiet variants answer the pointer weakly. Destructive keeps its danger label on hover
  (Capsule.qml:64-65, no hover branch) and its body stays at opacity 0 when hovered (:97-99). Press returns
  the growth to 1 with no colour change for ghost or destructive (StateLayer.qml:113). AGENTS: hover grows
  and changes colour. Fix needs an owner decision: reveal the body on hover and press for quiet variants
  (changes the ghost rule in the comment at :57), or lift the label colour for both on hover and press.
- D5, medium, no current caller: `primary` is not filled. Capsule.qml:92-93 passes `variant === "primary"` as
  the selected state, so its body is the active tint (accent 12 %). Its label is text (:64-65). It differs
  from `active` only in label colour (5.07 against 7.83, table above). Surface ladder: primary is the one
  filled action. Fix: fill with `Style.primary` and `Style.textOnPrimary` (Style.qml:43-44); selected only
  for `active`.
- D6, medium, shared: sizes are a local enum with mapped values (Capsule.qml:71, 73, 137, 149). AGENTS: a
  component knows its proportions, and the absolute size comes from `Style.size`. No `sizes.Capsule` exists
  in tokens/deep-night.json. Fix: add `sizes.Capsule` (32, 40, 52), derive the rest by ratio through
  `rhythm`, `textNear`, `iconNear`. The derivation gives lg inset 20 against the table's 24: an owner choice.
- D7, low: the detail reading is accent (Capsule.qml:157). AGENTS: accent belongs to focus, selection and
  primary action, never passive metrics. No caller sets `detail`. Fix: use the muted role for a reading.
- D8, low: `surfaceColor` and `surfaceOpacity` are public (Capsule.qml:31-32) but are bound internally
  (:92, :97). A host assignment silently replaces the state logic. Fix: make them internal, or document them
  as overrides with the hover and disabled logic moved into a host-visible route.
- D9, low, record: docs/components/Capsule.md:4 and :6 say the focus ring and target are "the outer pill".
  Labelled capsules use radiusMd (Capsule.qml:35; commit ff244af "radius follows the control row"). The
  record is stale, not the code. Fix: correct the two words in the existing record, owner to confirm.
- D10, major, known issue R2/R3 confirmed: `controls` holds only `state` enabled and disabled
  (workbench/units/Capsule.qml:26-31). Not reachable in the window: `active`, the three sizes, the four
  variants, `detail`, a long label, glyph-only. stories.json:439 describes "active state with detail text",
  and the unit never sets `detail`. Fix: add controls for active, size and variant; add the detail
  composition the story names.

Source conflicts (owner rules):

- S1: reduced motion. AGENTS "Reduced motion shortens a DURATION" (the Capsule follows this) conflicts with
  AGENTS Slider law "a one-shot position animation is REMOVED under reduced motion, not shortened" and with
  review-animations standard 8 ("keep opacity and colour, drop movement"). The growth (StateLayer.qml:113)
  continues. Owner decides. Fix location: StateLayer.qml, Motion.qml (shared).

Proposals (taste):

- Label size: sm labels are 10 px (Capsule.qml:149), the metadata step, while the label role defaults to 12 px
  (Prose.qml default branch). Consider 12 px for sm with the 32 px height. Measure first.
- Quiet press: a press could morph the corner, as caelestia's ButtonBase.qml `pressedRadius` does, instead of
  colour. Fits D4.
- Space fires on key press. Qt Quick Controls fire Space on release. Decide with a11y-audit.
- Overloaded `active`: consumers use it for power-on (BluetoothPopoutContent.qml:44), scan in progress
  (NetworkPopoutContent.qml:237) and an armed warning (NetworkPopoutContent.qml:221). Separate identity from
  status before the toggle exposure (D2) lands.

Hypotheses (not measured):

- H1: hover-on starts at the painted edge and exits 0.02 H further out (pointer hysteresis, geometry above).
- H2: the click-no-ring path depends on StateLayer's tap ordering (StateLayer.qml:175-181). Not run.
- H3: whether a press that releases outside the box fires `clicked` depends on TapHandler.DragThreshold
  semantics. Not run.
- H4: label ink centre is offset from the box centre by font metrics. Not measured.
- H5: grown hover boxes of neighbours overlap in gaps under 0.04 H (1.28 to 2.08 px). Host spacing unread.

Not examined: any runtime, capture, or Workbench session (none requested); glyph rendering (offscreen does not
rasterise SvgIcon); keyboard, screen reader and reduced motion at runtime; the light theme (only
deep-night tokens exist); host row spacing; the rendered label width; the disabled and lift values; touch.
