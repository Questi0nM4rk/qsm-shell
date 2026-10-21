# Radio

A radio is one option in a host-owned exclusive set; it reports selection intent and never owns group state.
states: rest hover(circle grows by Motion.hoverScale) press(recolours only, pressScale 1) focus(keyboard ring one step, spaceTight, outside the circle) disabled(every painted role through Style.disabled) off/on
actions: Select (pointer click, Space, Return, keypad Enter, `actions[0]` and `select()` share it); disabled or already selected radios refuse; the host answers `selectionRequested()` and owns `checked`
size: `size` resolves through Style.size("Radio", name) into `radioSize` (sm 12 / md 16 / lg 24, escape hatch); the dot is 0.4 of the circle rounded to whole pixels (5/6/10) from Caelestia's 8/20 geometry; `sizeScale` = radio / md for host label composition
content: the default slot is adjacent visible content; the screen-reader name is the label slot's text, `accessibleName` overrides it; an empty slot takes no width and no gap
colours: off = transparent fill, textMuted ring; on = solid accent fill with textOnPrimary dot; custom `accentColor`; disabled dims each role by colour
base: T.AbstractButton with checkable false, because T.RadioButton owns checked and group behavior belongs outside the component

## UIX audit

Evidence level: source-reviewed only. Available channels: the design source (`tokens/deep-night.json`, `Style.qml`, `Tokens.qml`, `Motion.qml`) and AGENTS.md component laws. Not available in this pass: a capture (channel 1), a live item tree (channel 2), a Workbench session. Runtime-exercised: none. Owner-accepted: none. Every number below is either read from a token or source line, computed from token colours, or a labelled assumption.

### Purpose and consequence

Finishes one single-choice pick inside a set the host owns. The consequence is the host's: `selectionRequested()` asks the host to change `checked` on this option and clear the others.

### Controls, states, implemented

- Expected public controls: `checked`, `enabled`, `size`, `accentColor`, `accessibleName`, default label slot, `actions` (`Select`), signal `selectionRequested`.
- Valid states: checked on or off, enabled or disabled, with hover, press and keyboard focus as pointer or key states. All are implemented in `Radio.qml` and `StateLayer.qml`.
- Workbench unit (`workbench/units/Radio.qml:34-43`): controls for checked on or off and enabled or disabled. Size is not a unit control, so sm and lg are not reached by the harness.

### Routes

- Pointer: click anywhere on the button, including the label slot (`Radio.qml:45`). Hover reads `host.hovered` (`StateLayer.qml:81`), so the whole row counts as hover.
- Keyboard: Tab via `activeFocusOnTab: enabled`. Space is the `AbstractButton` default press and release (not an explicit handler here). Return and keypad Enter are explicit handlers. Arrow keys have no handler and each option is its own Tab stop (see P1).
- Wheel: not applicable.
- Focus ring: `StateLayer.qml:147-161`, shown only for keyboard focus (`visualFocus`, `_pointerFocus`).
- Accessibility: role `RadioButton`, checkable, checked (`Radio.qml:35-37`). Name is `accessibleName` when set, else the text of the first label-slot item.
- Cancellation: Qt's default for a button, release outside the button does not click. Not exercised.
- Disabled: no Tab stop, actions refuse, hover off (`StateLayer.qml:81`), every painted role through `Style.disabled`.

### Sizes, empty, long content, failure

- Sizes from `tokens/deep-night.json` `sizes.Radio`: sm 12, md 16, lg 24. Border is `Style.indicatorWidth` 2 px at every size. Dot is 0.4 of the circle rounded: 5, 6 and 10 px. Gap is `Style.rhythm(radio * 0.5)`: 8, 8 and 12 px, because `Style.rhythm` rounds half up (`Style.qml:284`, 6 becomes 8).
- Empty label: the slot is hidden, so the width is the circle alone.
- Long label: no maximum width and no elision (`Radio.qml:86-88`), so the natural width grows with the label (P3).
- Failure: the radio has no error state. Cancellation: see Routes.

### Visual roles and palette pairs

Computed from token values (WCAG 2.2 relative luminance), not sampled from pixels. Band `#271e30`, surface `#3b3145`.

| Role in source | Foreground | Background | Ratio | Required |
| --- | --- | --- | --- | --- |
| unchecked ring (`textMuted`, `Radio.qml:65`) | `#c5bad1` | band | 8.6:1 | 3:1 (1.4.11) |
| unchecked ring | `#c5bad1` | surface | 6.6:1 | 3:1 |
| checked fill (`accent`, `Radio.qml:62`) | `#d9b4ea` | band | 8.9:1 | 3:1 |
| checked fill | `#d9b4ea` | surface | 6.8:1 | 3:1 |
| dot (`textOnPrimary`, `Radio.qml:80`) | `#271e30` | `#d9b4ea` | 8.9:1 | 3:1 |
| keyboard ring (`accent`, `StateLayer.qml:79`) | `#d9b4ea` | band | 8.9:1 | 3:1 |

Disabled colours are blends toward band at `opacityDisabled` 0.35. Inactive controls are exempt from 1.4.11, so they are not scored. The hover lift is `Style.lift`, not read, so hover ratios are not computed. Only one theme exists in the token source, so light and high-contrast are not examined.

### Motion and reduced motion

- Fill colour: `ColorAnimation`, `Motion.micro` 130 ms, standard easing (`Radio.qml:67-69`). Under 300 ms, ease-out, retargets when interrupted.
- Hover growth: `StateLayer` response, `Motion.micro` 130 ms, target scale `Motion.hoverScale`.
- Selection: fill, ring colour and dot opacity all fade on `Motion.micro`; the ring keeps its width and takes the fill colour when checked.
- Reduced motion: `Motion.micro` drops to 60 ms (`Motion.qml:26`) for all of them.
- Review-animations verdict: withheld. No block trigger is present. Approval needs the reduced-motion path verified live. Feel cannot be judged from code: the owner should check the fill fade and the ring and dot timing in a live window at 2 to 5 times the duration.

### Pointer geometry

- Input shape: the button's bounds, which are the whole row. Width = radio + gap + label width. Height = max(radio, label line box). Assumed label: `Prose` role `label` at 14 px (`Tokens.type.md`), line box about 17 px, width about 130 px for "Match window size". Input shape at md: 154 by 17 px (assumption).
- Painted circle: 16 px at md. The painted circle is not the input, so aiming at the circle alone is not required.
- Origin assumptions: label left edge at circle plus gap, vertically centred (`Radio.qml:87`). Label weight is not read from the role, so regular weight is assumed.
- Models (assumption: input shape width is the extent along the approach axis):
  - Horizontal approach from 200 px away onto the row: W 154 px, ID = log2(1 + 200/154) = 1.20 bits.
  - Vertical approach onto a column of options at pitch 25 px (17 px row plus an assumed 8 px host gap): W 17 px, ID = log2(1 + 25/17) = 1.30 bits.
  - Reference only, circle as the target with label not clickable: W 16 px, D 200 px, ID = log2(13.5) = 3.75 bits.
- Landing tolerance: plus or minus 8.5 px vertically inside the row before the pointer enters the host gap or the next option.
- Neighbouring interference: the host gap is dead space outside the input shape, 8 px per boundary in the assumed column. A column with no gap would have none.
- Popup corridor: not applicable, no popup.

### Findings

Redesign proposals:

- P1: arrow-key navigation and a single Tab stop for a group. Radio has no group concept (`docs/components/Radio.md:9` records it as the host's job), so a group component is needed. It would need a new qmldir entry, which makes it shared.
- P2: sm gap. `rhythm(6)` rounds to 8, the same as md, so the sm label sits 8 px from a 12 px circle. A proportion-true gap needs an explicit rule.
- P3: long label. Natural width grows with the label. Either a maximum width with elision is the consumer's slot job, or the component states one.
- P4: source conflict on press feedback. review-animations standard 5 asks for a press scale. AGENTS.md's body law sets `pressScale` 1. The owner rules which wins.
- P5: source conflict on the `size` property name. The qml-ui red flag says rename `size` on an Item. AGENTS.md defines `size` as the library's preset name, and `Radio.qml:14` follows it. Not verified on this component, and the owner rules.

Hypotheses (unmeasured):

- H2: a hovered and focused radio's ring gap shrinks slightly, because the circle grows and the ring does not.
- H3: Space reaches `clicked` through the `AbstractButton` default, not an explicit handler here.

Not examined:

- No capture, no live tree, no Workbench session, per the audit instructions. Nothing was run.
- Light, high-contrast and scale-factor variants (one theme in the token source).
- Hover lift colour (`Style.lift`) and label typography (`Prose` role `label`), which were assumed.

Channels: source only. Themes: deep-night only.
