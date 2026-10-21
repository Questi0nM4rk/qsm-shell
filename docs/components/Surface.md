# Surface

The Rectangle that binds the state matrix; a component body is one Surface and never its own colour ternary.
states: rest, hover, press, selected and disabled through one `tone` call (focus is the ring `StateLayer` paints, never a Surface state); selected is accent identity over the layer and content follows it.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none of its own; the hosting control forwards hovered and pressed.
keyboard: none of its own; the ring is `StateLayer`'s.
screen reader: none; the hosting control carries the role and name.
size: none; it fills whatever body hosts it.
tokens: surface, accent, text, disabled and the tone helper; callers pass the base and never local colours.
motion: micro colour settling on state change; reduced motion shortens the duration.
not designed: interaction, feedback or layout; use StateLayer, the control itself or the host for those.

## UIX audit

Evidence: source-reviewed only. Live geometry: none. No runtime capture, no preview, no owner
acceptance. Skills applied: ui-audit (static tokens and palette), ux-audit (routes), a11y-audit
(criteria, left to that skill), review-animations (values read from source, no verdict issued here),
qml-ui (mechanics). Sibling: caelestia has no Surface. The nearest comparison is caelestia
`controls/ButtonBase.qml` (lines 36-41, 64), which picks its disabled and active colours per control
by ternary. That per-component matrix is what Surface exists to remove.

### Purpose and consequence

Surface is the body a component paints: one Rectangle whose fill is
`Style.tone(base, hovered, pressed, selected, enabled, accent)` (Surface.qml:40) and whose content
colour is `contentColor` (Surface.qml:29-31). It finishes one task: every host shows the same rest,
hover, press, selected and disabled look for one body. It has no input, no size and no content.

### Controls and states

- Inputs: `base` (default `Style.surface`), `accent` (`Style.accent`), `hovered`, `pressed`,
  `selected`, `snapEdge` (`""`), `enabled` (inherited). `radius` is not declared: a body is square
  unless its host sets it.
- Output: `contentColor`, animated with the fill; a host reads it and never assigns it.
- States implemented in `Style.tone`: rest; hovered (lift 0.4, Style.qml:131); pressed (lift 0.8,
  Style.qml:129); selected (accent at `opacitySelected` 0.12 over base, Style.qml:138-140, Tokens.qml:70);
  disabled (`Style.disabled`, opacity 0.35, Style.qml:107-114, Tokens.qml:69).
- Focus: not implemented. Surface has no focus input and no key handling.
- Corners: `snapEdge` "left", "right", "top" or "bottom" squares the two corners on that wall
  (Surface.qml:35-38). Any other value rounds all four, silently.

### Routes

- Pointer: none on Surface. Hosts own it and forward `layer.hovered` and `layer.pressed`.
- Keyboard: none on Surface. The host routes Return, Enter and Space.
- Wheel: none.
- Focus: none on Surface; a host shows focus through its StateLayer ring.
- Screen reader: none on Surface. The host carries role and name. Verdicts are a11y-audit's.
- Cancellation: none on Surface. The colour `Behavior` (Surface.qml:42-44) retargets from the
  current value when the binding changes; this is Qt's default, source-only, not run.

### Sizes, empty and long content, failure

- Sizes: none on Surface. The unit body is `Style.controlWidth / 2` by Control `md`
  (workbench/units/Surface.qml:22-23). Hosts size it themselves.
- Empty and long content: Surface has no content. A child reads `contentColor` only if it binds it.
- Failure: an unknown `snapEdge` string is treated as no snapping (Surface.qml:35-38). A body with
  no `radius` renders square corners (Rectangle default). No error path exists.

### Visual roles and palette pairs

Computed in this audit from token values, not sampled from a render. Token values:
`band` #271e30 (tokens/deep-night.json:3), `surface` #3b3145 (:4), `text` #f0ecf5 (:6), `accent`
#d9b4ea (:10). Ratios use WCAG 2.x relative luminance.

| pair | ratio | requirement | note |
| --- | --- | --- | --- |
| text on rest body (surface) | 10.53:1 | 4.5:1 body text (1.4.3) | passes by computation |
| accent on selected body (accent at 0.12 over surface) | 5.25:1 | 4.5:1 body text (1.4.3) | passes by computation |
| text on selected body (surface base) | 8.10:1 | reference | |
| accent on selected body (transparent base over band) | 6.85:1 | 4.5:1 body text (1.4.3) | passes by computation |
| disabled text on surface | 2.23:1 | inactive-component exception (1.4.3) | a11y-audit confirms the exception |
| selected body vs rest body (surface) | 1.30:1 | non-text (1.4.11) only if the tint alone carries the state | see H-02 |
| surface vs band (ladder rest step) | 1.30:1 | 1.30:1 per AGENTS.md | holds |

Motion: `Behavior on color` with `ColorAnimation` over `Motion.micro`, easing `Motion.standardEasing`
(Surface.qml:42-44). `Motion.micro` is 130 ms (Tokens.qml:47), 60 ms under reduced motion
(Motion.qml:26). Standard easing is `Easing.OutCubic` (Motion.qml:120). Reduced motion shortens the
duration and removes nothing. `contentColor` has its own `Behavior` with the same animation (not observed on screen). The timing verdict belongs
to review-animations and is not issued here.

### Pointer geometry

- Input shape: none. Surface.qml declares no MouseArea, handler or pointer item, so it is not a
  target. Its painted area is set by the host.
- Painted size against input shape: not applicable.
- D, W and ID (log2(1 + D/W)): not applicable, there is no target. A host that makes the body a
  target uses its own StateLayer as the hit area, which is unmeasured here.
- Width model: not applicable.
- Label origin and weight (assumptions, not measured): the unit label is centred with
  `anchors.centerIn` (workbench/units/Surface.qml:29) and takes its weight from the Prose role
  `label` (Prose.qml role mapping).
- Landing tolerance, neighbour interference, popup corridor and timing: not applicable.

### Proposals

- Declare a default `radius` on Surface from the token set, so an unset host is not square by
  accident. Taste: the owner decides which radius is the default.
- Replace the `snapEdge` strings with a typed value, or reject an unknown one loudly. Today a typo
  rounds all four corners with no message.
- The selected identity is a 12 percent tint (1.28:1 against the rest body). If selection must be
  readable without colour, the host adds a non-colour carrier. The ruling belongs to a11y-audit.

### Hypotheses

- H-02: a 12 percent tint with a text colour change is the only carrier of selection. Whether that
  fails 1.4.1 or 1.4.11 is a11y-audit's question, not answered here.

### Not examined

- Any rendered pixel, any live window, any keyboard or pointer run, any reduced-motion run on screen.
- Hover, press and disabled looks against a live surface (the numbers above are source-computed).
- Owner acceptance: none recorded.
