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

Finishes "turn this on or off now" for a host row. A typical use is a result row. The effect is immediate and host-applied. The component offers no undo; reversal is the host's job.

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

The pointer target is the track, grown to at least `Style.iconLg` each way and centred; it overflows the footprint and never changes the implicit size. Targets: sm 28x24, md 36x24, lg 48x30. Hover and press growth do not change it. The cursor is the pointing hand over the whole target while enabled. The StateLayer's pointer handler is off when hosted, so the target feeds the layer through `manualHoverOverride` and `manualPressOverride`. Neighbouring interference is not measured: in a result row that selects itself on hover, the gap to the row's other targets is not measured.

### Source conflicts

- **C1.** AGENTS component law: "every other measurement is its md value times s, snapped to its own scale", and "spacing and insets through `Style.rhythm`". Versus this record: "the inset is the knob's own eighth, so the proportions survive any `knobSize`". Snapping to the rhythm changes md's inset from 2 px to 4 px. The owner rules which wins.

### Redesign proposals (taste, not defects)

- **P1: a pending state for host-applied changes.** A host that binds `checked` straight to service state gives no cue between a press and the service's answer, nothing moves. Option: a host-owned `pending` that dims the knob or holds it at mid-travel. This is the owner's design call. The component has no pending state at all.
- **P2: hover makes the knob the track's height exactly.** At md the knob grows from 16 to 20 px inside a 20 px track. At sm it is 15 in 15, and at lg 30 in 30. The knob's circle then coincides with the track's end cap, so the off track's outline disappears at that end. A growth smaller than the inset would keep the track legible.
- **P3: remove the `_knob` alias.** `Switch.qml:61` repeats `knobSize`. `_s` (line 36) and `sizeScale` (line 37) are one value named twice. Keep `sizeScale`, which the record names.
- **P4: motion, for review-animations.** The knob slides and the colour changes on every route, including keyboard. review-animations standard 2 says a keyboard-driven toggle gets no animation. The single `flip()` route (AGENTS law) hides the route from the component, so a fix needs a host-supplied fact. Not ruled here.

### Hypotheses (not measured)

- **H1.** `Accessible.checked` is not bound to `checked`. If the platform does not derive the state for a `checkable: false` button, a screen reader hears no on or off. Check with `qsm-uix a11y-tree` on the running unit (a11y-audit, not run here).
- **H2.** `Accessible.CheckBox` may announce as "check box", not as a switch. Whether the installed Qt offers a switch role was not checked.
- **H3.** Keypad Enter reaches `Keys.onEnterPressed` by Qt key routing, not by a run.
- **H4.** Hover and press growth keep moving under reduced motion, shortened to 40 to 60 ms rather than dropped. review-animations standard 8 asks for opacity and colour to stay and movement to go. This is for review-animations to rule.
- **H5.** The wheel passes through to the enclosing list, because the component has no handler. Not run.

### Not examined

No runtime input: no preview, session or ydotool, and the one load-check capture does not draw glyphs or judge looks. Not seen, and the new pointer target's exclusive grab (no double toggle, click focus) is not run: the rendered ring, the rendered press protrusion, the hover lift colour, the lg and sm looks, the disabled look, a screen reader, keyboard focus in a window, reduced motion in a window, the composed launcher row, touch. Owner acceptance: none.
