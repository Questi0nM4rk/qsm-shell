# Switch

A boolean that takes effect the moment it is thrown; a checkbox is a statement something else acts on later.
states: rest hover(knob grows space1, track lifts) press(track deepens, knob does not move) focus(ring around the track at a spaceTight gap, concentric) disabled(track and knob through Style.disabled, never opacity) on/off
actions: Toggle (pointer tap, Space, Return, keypad Enter and `flip()` share it); the host owns `checked` and answers `toggleRequested(checked)`; the host names the instance (`Accessible.name`), the component has no label
size: `size` is a preset name resolved by Style.size("Switch", name) into `knobSize` (escape hatch); the rest are proportions: inset an eighth of the knob rounded to a whole pixel (sm 2, md 2, lg 3), track two knobs plus two insets by one knob plus two insets, ring gap spaceTight constant; pointer target at least `Style.iconLg` each way, centred, overflowing the footprint; `sizeScale` = knob / md for a host composing around it. No label inside (a row or Field names it)
tokens: iconSm iconLg spaceTight space1 textMuted band accent textOnPrimary radiusPill(track = height / 2)
colours: off = track textMuted, knob band; on = track solid accent (a toggle with its own fill is selected as solid accent), knob textOnPrimary (content on accent is textOnPrimary, as the Checkbox mark)
motion: knob x Motion.fast moveEasing, colours Motion.micro; the knob slides, it is not thrown
events: toggleRequested(bool checked) on every route; nothing else
base: T.AbstractButton with checkable false. Measured: T.Switch writes `checked` itself on a drag release even with checkable false, which takes the state from the host; drag is not offered
not designed: sizes, on/off text (Fluent), icon in the knob (M3), drag

## UIX audit

Evidence: source-reviewed, plus one offscreen load-check capture after the fixes (exit 0, no QML error; it proves the scene loads, nothing about looks or input). Runtime-exercised: none. Owner-accepted: none. Skills loaded: ui-audit, ux-audit, a11y-audit, review-animations, qml-ui. No preview or session was run. Token values come from `tokens/deep-night.json` and `qml/QsmShell/Style/Tokens.qml`. Contrast ratios are hand-computed from those hex values (WCAG relative luminance), not sampled from pixels.

### Purpose and consequence

Finishes "turn this on or off now" for a host row. The desktop use is the launcher result row (`qsm-desktop` `shell/modules/launcher/LauncherSurface.qml:1211-1234`). The effect is immediate and host-applied. The component offers no undo; reversal is the host's job.

### Controls and states

- Controls: `checked` on and off, `size` sm, md, lg, `enabled` on and off (`workbench/units/Switch.qml`).
- States implemented: rest, hover (knob grows `iconSm + space1`, track lifts), press (track deepens, knob unchanged), focus (ring, keyboard only), disabled (`Style.disabled`, no opacity), on and off.
- States not implemented: pending, failed, indeterminate. None is designed (P1).

### Routes

- Pointer: a tap on the pointer target (track plus overflow, see Pointer geometry) calls `flip()`; the tap handler's exclusive grab keeps the template's own `onClicked` from also firing, and the template's `onClicked` stays for Space. Drag is not offered by design. Release outside the target does not toggle (`ReleaseWithinBounds`, source-reviewed, not run).
- Keyboard: Tab stop when enabled (`activeFocusOnTab`). Space goes through the template click. Return is `Keys.onReturnPressed` (`Switch.qml:68`). Keypad Enter is `Keys.onEnterPressed`, same call.
- Wheel: no handler, so the component does not consume it (source-reviewed, not run).
- Focus: ring drawn by `StateLayer`, shown on `visualFocus`. A pointer click focuses without ringing, through `_pointerFocus` (`StateLayer.qml:152`). Ring sits at the `spaceTight` gap, concentric, because the layer is the track.
- Accessibility: role `CheckBox` and `checkable: true` (`Switch.qml:55-56`). The component keeps no name; the host names the instance, and the unit does. No checked binding (H1).

### Sizes, content, failure, cancellation

- Sizes (knob, track width x height, inset): sm 12, 28x16, 2 px. md 16, 36x20, 2 px. lg 24, 48x30, 3 px. Insets are `round(knobSize * spaceTight / iconSm)`. Unknown preset names warn once and fall back to md (`Style.qml`, `size()`).
- Empty and long content: none. The component has no label or text.
- Failure: no failed or pending look. A host that applies the change asynchronously shows nothing until it answers (P1).
- Cancellation: a disabled switch ignores `flip()`, and its tap and hover handlers are off. A press cancelled by leaving the track does not emit.

### Visual roles and palette pairs

- Off: track `textMuted` (`Switch.qml:79-80`), knob `band`.
- On: track `accent`, knob `textOnPrimary` (equal to `band` in deep-night).
- Disabled: track and knob through `Style.disabled` (blend to band at `opacityDisabled` 0.35).
- Focus ring: `Style.accent`, `spaceTight` stroke, from `StateLayer`.

Contrast, hand-computed from token hex values, source-reviewed only:

| pair | ratio | criterion |
| --- | --- | --- |
| off knob `band` on off track `textMuted` | 8.6:1 | 1.4.11, needs 3:1, pass |
| off track `textMuted` on `surface` | 5.9:1 | 1.4.11, pass |
| off track `textMuted` on `band` | 8.6:1 | 1.4.11, pass |
| on knob `textOnPrimary` on on track `accent` | 8.9:1 | 1.4.11, pass |
| focus ring `accent` on `surface` | 6.1:1 | 1.4.11, pass |

Hover lift colours and rendered pixels are not sampled.

### Motion

- Knob slide: `Motion.fast` (180 ms, `Tokens.motionFast`), `moveEasing` (InOutCubic), `Switch.qml:101-104`.
- Track colour: `Motion.micro` (130 ms), `standardEasing` (OutCubic), `Switch.qml:82-84` and `105-107`.
- Hover and press growth: the StateLayer `response` animates over `Motion.micro` on hover and `Motion.press` on press.
- Reduced motion: the knob slide is disabled (`Switch.qml:102`, `enabled: !Style.reducedMotion`). Colour and growth durations are shortened to 60 ms and 40 ms (`Motion.qml`), not removed. The growth scale still plays (H4).
- Motion verdict: handed to review-animations (P4). This record does not rule on it.

### Pointer geometry

The pointer target is the track, grown to at least `Style.iconLg` each way and centred; it overflows the footprint and never changes the implicit size. Targets: sm 28x24, md 36x24, lg 48x30. Hover and press growth do not change it. The cursor is the pointing hand over the whole target while enabled. The StateLayer's pointer handler is off when hosted, so the target feeds the layer through `manualHoverOverride` and `manualPressOverride`. Neighbouring interference is not measured: in the launcher the switch sits in a result row that selects itself on hover (`LauncherSurface.qml`), and the gap to the row's other targets is not measured.

### Findings: source-backed defects

Each defect cites the file and line, what a person sees, the fix, and whether the fix needs a shared file. Each fix stays in `Switch.qml`, `workbench/units/Switch.qml`, or the record. Status is source-reviewed and load-checked (one-scenario capture exits 0, no QML error), never owner-accepted.

- **S1, major: hit area below the 24 px floor.** `Switch.qml:63-64`. The md track is 36x20 and the sm track is 27x15. The launcher uses sm (`LauncherSurface.qml:1222`). WCAG 2.5.8 floor is 24x24 unless a spacing exception holds, which this record cannot check. A person on the pointer lands on a 15 px band at sm, or misses onto the row. Fix: add a pointer target that overflows the footprint, centred, at least `max(track, Style.iconLg)` each way, without changing implicit size (AGENTS: an action never adds footprint). Shared: false. Fixed (source-reviewed, load-checked): a centred pointer target of at least `Style.iconLg` each way.
- **S2, minor: focus ring floats 4 px off the track and is not concentric.** `Switch.qml:116-118` makes the StateLayer the track plus `spaceTight` on each side. `StateLayer.qml:147-156` anchors the ring to that layer with a reach of `2 * spaceTight`. The ring's outer edge is 6 px from the track, and its stroke's inner edge is 4 px away. The comment and this record say the gap is `spaceTight` (2 px). Outer radius is 14 px, where concentric at a 6 px offset needs 16 px. A keyboard user sees a ring off the track with corners that do not follow it. Fix: size the StateLayer to the track (`anchors.fill: root`), so the ring sits at the documented gap. Shared: false. Fixed (source-reviewed, load-checked): the StateLayer fills the track, so the ring sits at the `spaceTight` gap.
- **S3, minor: pressed knob pokes out of its track.** `Switch.qml:122` sets `pressScale` to 1.5, driven through the StateLayer response. At md the knob grows from 16 to 24 px inside a 20 px track, so it protrudes 2 px past the track on every side. In general the protrusion is knob/8. This breaks the component law "a press changes colour only on a body (`pressScale` is 1)". The track already recolours on press (`Switch.qml:79-80`). Fix: keep `pressScale` at 1 and press by colour only, unless the owner keeps the lift. That decision is the owner's. Shared: false. Fixed (source-reviewed, load-checked): `pressScale` is the default 1, press recolours the track only. The owner may bring the lift back.
- **S4, minor: fractional inset at sm.** `Switch.qml:62`: `12 * 2 / 16 = 1.5` px. The knob's position lands on 1.5 px and 13.5 px (`Switch.qml:90-91`), so the sm knob edges fall on half pixels, against the qml-ui integer-geometry rule. md (2 px) and lg (3 px) are whole. The record claims "the proportions survive any knobSize", which fails at sm. Fix (owner picks): round the inset (sm becomes 2 px, track 16 px), or snap through `Style.rhythm` (changes md to 4 px; see C1). Shared: false. Fixed (source-reviewed, load-checked): the inset is rounded, sm becomes 2 px and a 28x16 track. Rounding was chosen over `Style.rhythm`, which would leave C1 open and move md; C1 stays the owner's.
- **S5, minor: no pointing-hand cursor.** The Switch sets no cursor. `StateLayer.qml:164-167` sets the pointing hand only on its own HoverHandler, which is disabled when hosted (`enabled: !root._hosted`). The Switch hosts itself (`Switch.qml:119`). A person sees the arrow over every enabled switch. Fix: a HoverHandler on the Switch with `cursorShape` set to the pointing hand while enabled. Shared: false. Fixed (source-reviewed, load-checked): a HoverHandler on the pointer target sets the pointing hand while enabled.
- **S6, minor: keypad Enter does nothing.** `Switch.qml:68` handles only `Keys.onReturnPressed`. Keypad Enter is delivered to `Keys.onEnterPressed` in Qt (source-level knowledge, not run; H3). Fix: add `Keys.onEnterPressed: root.flip()`. Shared: false. Fixed (source-reviewed, load-checked): `Keys.onEnterPressed` calls `flip()`. H3 still rests on Qt routing, not a run.
- **S7, minor: no accessible name.** `Switch.qml:55-56` sets the role and checkable state and no name. The unit sets none (`workbench/units/Switch.qml`). The desktop names it at `LauncherSurface.qml:1231`. A screen-reader user hears "check box" with no label, in the unit and in any consumer that forgets. Fix: the unit names its sample, and the record states that the host must name the instance. The component keeps no label, because the row names it (per the record). Shared: false. Fixed (source-reviewed, load-checked): the unit names its sample; the record states that the host names the instance.
- **S8, minor: the unit's key rows bypass the real key route.** `workbench/units/Switch.qml:38-41` and `:46` call `toggle.flip()` for "Space" and "Enter". The harness's key rows therefore pass even if the Switch's key handling is broken. AGENTS requires a step the host cannot execute to fail. Fix: focus the control and deliver the real key, or remove the key rows. Shared: false. Fixed (source-reviewed, load-checked): the unit's `keys` rows are removed, so no key row can pass without the real key route.
- **S9, minor: size is not reachable in the unit.** `workbench/units/Switch.qml:25-35` exposes `checked` and `state` only. AGENTS requires sizes to include the theme's supported names, and the desktop uses sm. Fix: add a `size` control with sm, md, and lg. Shared: false. Fixed (source-reviewed, load-checked): the unit has a `size` control with sm, md, lg.

### Source conflicts

- **C1.** AGENTS component law: "every other measurement is its md value times s, snapped to its own scale", and "spacing and insets through `Style.rhythm`". Versus this record: "the inset is the knob's own eighth, so the proportions survive any `knobSize`". Snapping to the rhythm changes md's inset from 2 px to 4 px. The owner rules which wins.

### Redesign proposals (taste, not defects)

- **P1: a pending state for host-applied changes.** The desktop binds `checked` straight to service state (`LauncherSurface.qml:1223-1229`). Between a press and the service's answer, nothing moves. Option: a host-owned `pending` that dims the knob or holds it at mid-travel. This is the owner's design call. The component has no pending state at all.
- **P2: hover makes the knob the track's height exactly.** At md the knob grows from 16 to 20 px inside a 20 px track. At sm it is 15 in 15, and at lg 30 in 30. The knob's circle then coincides with the track's end cap, so the off track's outline disappears at that end. A growth smaller than the inset would keep the track legible.
- **P3: remove the `_knob` alias.** `Switch.qml:61` repeats `knobSize`. `_s` (line 36) and `sizeScale` (line 37) are one value named twice. Keep `sizeScale`, which the record names.
- **P4: motion, for review-animations.** The knob slides and the colour changes on every route, including keyboard. review-animations standard 2 says a keyboard-driven toggle gets no animation. The single `flip()` route (AGENTS law) hides the route from the component, so a fix needs a host-supplied fact. Not ruled here.

### Hypotheses (not measured)

- **H1.** `Accessible.checked` is not bound to `checked`. If the platform does not derive the state for a `checkable: false` button, a screen reader hears no on or off. Check with `qsm-uix a11y-tree` on the running unit (a11y-audit, not run here).
- **H2.** `Accessible.CheckBox` may announce as "check box", not as a switch. Whether the installed Qt offers a switch role was not checked.
- **H3.** The keypad Enter mapping in S6 rests on Qt key routing, not on a run.
- **H4.** Hover and press growth keep moving under reduced motion, shortened to 40 to 60 ms rather than dropped. review-animations standard 8 asks for opacity and colour to stay and movement to go. This is for review-animations to rule.
- **H5.** The wheel passes through to the enclosing list, because the component has no handler. Not run.

### Not examined

No runtime input: no preview, session or ydotool, and the one load-check capture does not draw glyphs or judge looks. Not seen, and the new pointer target's exclusive grab (no double toggle, click focus) is not run: the rendered ring, the rendered press protrusion, the hover lift colour, the lg and sm looks, the disabled look, a screen reader, keyboard focus in a window, reduced motion in a window, the composed launcher row, touch. Owner acceptance: none.
