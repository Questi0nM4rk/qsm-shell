# Spinner

An animated progress affordance for ongoing work without a fraction; it spins while running and takes no input.
states: running and stopped; the animator runs only while running and visible; stopped draws the unlit ring only, so no fraction is shown.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: no role of its own; the surface owning the task announces progress.
size: one `size` square from the icon scale; stroke follows the ring proportion with a one-pixel floor; radius insets half the stroke.
tokens: iconMd, spinnerStrokeRatio and accent; no local colours or measurements.
motion: infinite rotation on the sweep arc over a faint full ring with round caps; reduced motion lengthens the period.
not designed: fractions, metering a level or labelling; use ProgressBar, Meter or Prose for those.

## UIX audit

Scope: the library type `qml/QsmShell/Components/Spinner.qml`, its unit `workbench/units/Spinner.qml`, and story key `spinner` in `workbench/stories.json`. Method: source reading under qsm-uix ui-audit, ux-audit, review-animations and qml-ui, compared with the caelestia `LoadingIndicator.qml` and `CircularIndicator.qml`. No capture, live window or input was used. Evidence on every row is **source-reviewed**. Runtime-exercised: none. Owner-accepted: none.

### Purpose and consequence

It finishes one task: telling a person that work with no knowable end is still running (`Spinner.qml:5-15`). If it fails, a frozen or misleading mark reads as done or as a quantity. A spinner that vanishes reports nothing, so the owning surface replaces it with the result.

### Controls and states

- Properties: `size` (default `Style.iconMd`), `color` (default `Style.accent`), `sweep` (0.28), `running` (true). All four are implemented.
- States: running and stopped, both reachable by property only. The unit exposes stopped as the `motion` control.
- No `actions`, signals or functions. The unit's `events` and `actions` are empty, which matches the component.
- Not designed: failure, cancellation with a result, progress, empty or long content. A spinner has none of them.

### Routes

- Pointer: none. `Spinner.qml` declares no handler and no `MouseArea`, so input falls through to what lies beneath.
- Wheel: none; it passes through for the same reason.
- Keyboard: none. It is not a tab stop and takes no keys.
- Focus: none. It is a non-interactive mark with no focus state.
- Screen reader: no role and no name. Accessibility criteria belong to a11y-audit. A host places the mark beside text such as `Loading…`, which carries the status.

### Sizes, empty, long, failure, cancellation

- Icon scale from `Tokens.qml:42-45`: iconXs 12, iconSm 16, iconMd 20 (default), iconLg 24 (the unit's default).
- Stroke, computed from `Spinner.qml:41-42` as `max(1, size × spinnerStrokeRatio)` with a ratio of 0.16 (`deep-night.json`): 12 → 1.92 px, 16 → 2.56 px, 20 → 3.20 px, 24 → 3.84 px. None is an integer. For a curve this is expected antialiasing, so it is not a finding.
- Round caps fit the box. The radius is `centre − thickness/2` (line 48), so the outer edge of a round-capped stroke lands exactly on the box edge. Nothing clips, by arithmetic from lines 47-50.
- Cancellation: `running: false` stops the rotation and repaints the unlit ring only.

### Visual roles and palette pairs

The arc is `color` (line 20). The track is `color` at alpha 0.18 (line 52). Values are computed from the token hex, not sampled from a render: accent `#d9b4ea` and band `#271e30` (`deep-night.json`).

- Arc over band: 8.87:1.
- Track, the 18% accent composited over band as `#473951`, over band: 1.50:1.
- Arc over track: 5.92:1.

The track is deliberately dim, and the active arc is measured above it. Whether a 1.50:1 track is acceptable for a non-text part belongs to a11y-audit (see H5).

### Motion and reduced motion

- Rotation: 0 to 360 degrees over `Motion.spin`, infinite (`Spinner.qml:71-78`). `Motion.spin` is `Tokens.motionSpin` = 900 ms per turn (`deep-night.json:73`). It runs only while `running && visible` (line 77).
- Reduced motion: `Motion.spin` doubles to 1800 ms (`Motion.qml:108`). The period lengthens, so the mark stays visible and turns more slowly. This follows the AGENTS law.
- Rotation is applied to the item as a transform (lines 69-70), so it does not repaint each frame.
- review-animations verdict, on source only: justified (it shows that work is running); frequency is low (one loading row); no popover, so origin does not apply; no gesture, so interruptibility does not apply; reduced motion is handled; values sit inside bounds. Easing is open (H1). The verdict is Approve on source, pending H1. Whether the motion feels right cannot be judged from code. The check is a live window with the duration raised to 2 to 5 times, frame by frame.

### Pointer geometry

- Input shape: none. Painted shape: a ring filling a `size` × `size` box (lines 29-30).
- D, W and ID: not applicable. A spinner is not a pointer target, so no Fitts measurement is taken. A host that places it in a clickable row must make the row the target, never the spinner.
- Width model: not applicable. Label origins and weights: not applicable, since there is no label.
- Neighbouring interference: none, because it claims no events.

### Findings

**Defects (source-backed)**

- **D1, low. Literal numbers in the component.** `Spinner.qml:42` (`* 3`), `:52` (`0.18`), `:23` (`0.28`). AGENTS says every number comes from Style or Motion. The line "no local colours or measurements" in the existing record above is wrong for this file. Fix: name the track alpha and the stroke factor as Style tokens.
- **D2, low. Default size is a raw token, not a preset.** `Spinner.qml:19` (`size: Style.iconMd`). AGENTS says a sized type takes a preset from `Style.size("<Type>", …)`, and a raw px is only the escape hatch. A caller that needs another size passes px. Fix: default to `Style.size("Spinner", "md")` and add a `Spinner` row to `sizes` in the token file.
- **D3, low. Default colour is the accent.** `Spinner.qml:20` (`Style.accent`). `Style.qml:44-48` reserves the accent for what is current and says "a passive readout never spends the accent", with the status set beneath it. AGENTS says the accent belongs to focus, selection and primary action. Fix: default to a status token, such as `Style.info`. The owner names the colour.

**Proposals (owner's judgement, not defects)**

- P1: The stopped image. A stopped spinner draws the unlit track only, so it carries no fraction. The alternative is hiding the mark; stopping inside a hidden surface already avoids the repaint cost, so hiding is the simpler option.
- P2: A stroke that grows with size (line 42). AGENTS says the bigger the instance, the calmer, and a 24 px ring carries a 3.84 px stroke. caelestia's `CircularIndicator.qml` uses a fixed stroke from a token instead. Choose one after a live look.
- P3: The accessible name. It belongs to a11y-audit. The proposal is only to name the owner of the status text at each caller.

**Source conflicts**

None between the component, this record and AGENTS, apart from the record-versus-source mismatch in D1.

**Hypotheses (unmeasured, never mixed into the defects)**

- H1: Easing is unset. `Spinner.qml:71-78` sets no `easing.type`. caelestia's `LoadingIndicator.qml:108` sets `Easing.Linear` explicitly. If the QtQuick default differs from Linear, each turn speeds up and slows down. Check the installed Qt default, then set Linear.
- H2: Repaint on resize. `onPaint` reads `width` and the `thickness` derived from `root.size`. It depends on Canvas repainting on resize, which is unverified here. A stale stroke after a size change would show that.
- H3: "A short arc reads as faster at the same period" (`Spinner.qml:21-22`) is an unmeasured perception claim.
- H4: A host that shows the spinner the moment loading starts flashes the mark on a fast load. The library has no show-delay, and whether ui-design's wait value calls for one is unchecked.
- H5: The 1.50:1 unlit track against band. Whether 1.4.11 needs the ring's shape at 3:1 is a11y-audit's call.

**Not examined**

- A live window, any capture, reduced motion on a live window, frame timing, and Canvas quality at each size.
- Light and high-contrast themes. The only token file read is `deep-night.json`, so theme parity is not checked.
- Row alignment of the 16 px ring beside text.
- Accessibility criteria, which belong to a11y-audit.
- Owner acceptance: none.
