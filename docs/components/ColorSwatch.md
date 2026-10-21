# ColorSwatch

A colour sample with a readable value text; the ink over the sample is picked by measured contrast, never by assumption.
states: rest, hover, press, focus, selected and disabled; `empty` shows an outline instead of a face; selected adds an accent ring outside the face, with a gap; disabled dims each role through `Style.disabled` with the sample's alpha kept, so the check still shows through.
actions: pointer click, Space, Return, keypad Enter, `activate()` and the actions entry emit `clicked`; the host owns selection and what the sample means.
pointer: the target answers on the `swatchTarget` floor while the face stays `size` and swells in place; wheel does nothing and propagates.
keyboard: tab reaches an enabled swatch, click takes focus, and Space, Return and keypad Enter share the `activate()` route; the focus ring hugs the face, one step outside the selection ring while selected.
screen reader: a checkable Button named by `reading`, else the sample's value, else "Empty colour slot"; `selected` is its checked state. Ink is chosen against both check cells; when neither ink reaches 4.5:1 the reading sits on a band plate, so the text reads on any ground.
size: `size` is the painted face; the layout footprint is `max(size, swatchTarget)` with the face centred, so 24px palette samples keep 24px faces on 44px targets; the reading is never elided at the face width: it takes a plate a little wider than the face when it does not fit; radius is `radiusSm`; both rings hug the face instead of the target.
tokens: swatchTarget, the Control size table, radiusSm, spaceTight, markThickness, textXs, surface, text, band, textMuted, accent and StateLayer; no local colours or measurements.
motion: micro ring fade plus StateLayer face swell on hover (about one pixel a side at most, none under reduced motion) and push-in on press; reduced motion shortens the durations.
not designed: a colour picker, palette model or editing; it shows one sample and reports the click.
review: the value follows the rendered sample across theme changes and alpha is explicit; unrelated glyphs do not describe a colour. Selection and activation have a stated host consequence; the owner judges the example before accepting it.

## UIX audit

Evidence: source-reviewed only. Nothing was run, captured or driven; geometry and contrast are computed from `tokens/deep-night.json` and the source. Runtime-exercised: none. Owner-accepted: none.

### Purpose and consequence

Shows one colour so a person can read its value, select it, or copy it. A wrong reading or a silent unnamed control makes the person pick or copy the wrong colour, or not know which swatch is selected.

### Controls and states

Public API: `sample` (required colour), `empty`, `reading`, `size` (raw px, default `Style.size("ColorSwatch", "md")`), `selected`, `focused` (read-only), `enabled`, signal `clicked`, function `activate()`.

| state | expected | implemented |
| --- | --- | --- |
| rest | outline when empty, face otherwise | yes (`ColorSwatch.qml:221-228`, `:163-216`) |
| hover | face swell plus target | yes, `hoverScale` 1.08 through StateLayer (`:270-276`) |
| press | a visible response | yes, `pressScale: Motion.pressScale` on the face (D7 fixed) |
| focus | keyboard ring around the face | yes, its own `StateLayer` sized to the face (D5 fixed) |
| selected | accent ring outside the face | yes, reported as `Accessible.checked` (D4, D6 fixed) |
| disabled | dimmed by colour, sample alpha kept | yes (`_paint`, `Style.disabled`) |
| error | none | not applicable: an invalid colour cannot reach a `color` property; the host owns it |
| loading | none | not applicable |

### Routes

- Pointer: StateLayer covers the whole target; click calls `forceActiveFocus()` then `activate()` (`:277-280`). A drag past the threshold cancels (`StateLayer.qml:52`). Wheel: no handler, propagates.
- Keyboard: `activeFocusOnTab: enabled` (`:56`); Space and Return call `activate()` (`:283-284`). Keypad Enter (`Key_Enter`) is not handled (D8). Escape has nothing to cancel.
- Focus ring: keyboard only, through `_pointerFocus` (`StateLayer.qml:73-74`, `:152`).
- Screen reader: role Button, name = `reading`, else the sample's hex, else "Empty colour slot"; `checked` reports `selected`.

### Sizes, empty, long content, failure, cancellation

- Sizes: face = `size`; footprint = `max(size, swatchTarget)` = 44 px for every size under 44. The unit's sm/md/lg are 32/40/48 px.
- Empty: outline in `textMuted`, no checker, no reading, selected ring in `accent` (`:221-228`, `:248`).
- Long content: the reading is one line with `ElideRight` (`Prose.qml:118`). At md, `#E8C58A` truncates (D2). An 8-digit hex truncates further.
- Failure: none defined; the `color` type rejects an unparseable value before the swatch sees it.
- Cancellation: a press released off the target or dragged past the threshold does not click.

### Visual roles and palette pairs

Contrast computed from tokens, WCAG 2.2 relative luminance:

- Reading ink: `Style.text` #f0ecf5 or `Style.band` #271e30, chosen by the better of the two (`:114-116`). Opaque samples: the worst case is 3.70:1 at relative luminance Y = 0.19 (about sRGB 110-135 grey). The best ink is below 4.5:1 for Y between about 0.15 and 0.25 (D1).
- Ring ink on the sample: 8.9:1 for the `warning` sample (#d9c284) and the `accent` sample (#d9b4ea). Ring ink against host `surface` #3b3145: 1.30:1 (D6).
- Empty outline `textMuted` #c5bad1: 8.61:1 on band, 6.61:1 on surface.
- Focus ring `accent` #d9b4ea: 8.87:1 on band, 6.82:1 on surface.
- Checker cells #ffffff and #c0c0c0 are literals (D10).
- Disabled: `Style.disabled` blends each colour 35 percent toward band. The disabled reading is inactive, so it is exempt from the 4.5:1 text rule.

### Motion and reduced motion

- Selection ring: `Behavior on border.width` at `Motion.micro` (130 ms, OutCubic). Reduced motion: 60 ms (`Motion.qml`, `Style.reducedMotion`).
- Hover: face scale to 1.08 over `micro` through `StateLayer.response`. Press: no visible change.
- Focus ring opacity: `micro`.
- Reduced motion shortens durations only. The hover swell still plays at full size (D11).

### Pointer geometry

- Input shape: square 44 x 44 px target, `StateLayer` anchored to the root (`:146-147`, `:270-272`). Painted face: `size`, 40 px by default (24 px in a compact row). For a 24 px face the input area is 1936 px^2 and the painted area 576 px^2, 30 percent.
- Origin (assumption, not measured): the pointer starts at the centre of the adjacent swatch in one row. Weight: none (assumption).
- Distance D: 48 px centre to centre for a compact row, assuming `RowLayout spacing: space1` = 4 px between 44 px footprints.
- Width model: W = 44 px, the target the pointer must land on (the pointer obeys the target). Alternative W = 24 px, the face a person sees.
- Difficulty: ID = log2(1 + D/W). W = 44: 1.06 bits. W = 24: 1.59 bits. Computed.
- Landing tolerance: plus or minus 22 px around the centre for the target; plus or minus 12 px for the 24 px face.
- Neighbouring interference: targets do not overlap, and the 4 px gap between footprints answers neither swatch (8 percent of the 48 px pitch). Hypothesis H1.
- Popup corridor: not applicable, this is not a popup.

### Fix status

Fixed, source-reviewed and load-checked (qmllint clean, `swatch` scenario loads with no QML error). Not runtime-exercised, not owner-accepted.

- D1 fixed: when the better ink is under 4.5:1 the reading takes a band plate with `Style.text` ink.
- D2 fixed: the reading is measured with `TextMetrics`; one that does not fit the face's inner width takes the plate, which may extend a little past the face instead of eliding. An 8-digit hex on a small face can still elide at the plate's cap.
- D3 fixed: name is `reading`, else the sample's value, else "Empty colour slot".
- D4 fixed: `Accessible.checkable` and `Accessible.checked: selected`.
- D5 fixed: the keyboard ring is a second `StateLayer` anchored to the face; the pointer `StateLayer` keeps the 44 px target. Both ring and face ride one `_pointerFocus` flag so a click still does not ring.
- D6 fixed: the selection ring is accent, outside the face at `spaceTight`; the keyboard ring steps out beyond it while selected.
- D7 fixed: `pressScale: Motion.pressScale`.
- D8 fixed: `Keys.onEnterPressed`.
- D11 fixed: hover growth is `1 + min(hoverScale - 1, spaceTight / size)` and 1 under `Style.reducedMotion`.
- D9, D10 stay open (shared tokens and Style).

### Findings (as audited, before the fixes)

Source-backed defects (each cites file and line; severity uses the ui-audit scale):

- **D1 major, ink fails 4.5:1 mid-tone.** `ColorSwatch.qml:98-116`. The ink is the better of two, not one that reaches 4.5:1. A person sees a value like `#E8C58A` or any grey-to-mid swatch with a hard-to-read hex. Fix: when the better ink is under 4.5:1, draw the reading on a band plate inside the face. Shared: false.
- **D2 major, reading truncated at md.** `ColorSwatch.qml:255-265`, `:257` (2 px inset), `:260` (`Style.textXs`). The md inner width is 40 - 2 x 2 = 36 px. `#E8C58A` at 10 px monospace is about 42 px, assuming 0.6 em per glyph (assumption, not measured), so `ElideRight` cuts it. The unit's default shows this. Fix: fit the reading to the face through `Style.textNear`, or place it outside the face on small sizes. Shared: false.
- **D4 major, selected state not announced.** `ColorSwatch.qml:49`, `:58-59`. No `Accessible.checked` or `checkable`. Fix: `Accessible.checkable: true; Accessible.checked: root.selected`, or a RadioButton role if the host is single-choice. Shared: false.
- **D5 major, focus ring detached from the face.** `StateLayer.qml:147-157` draws the ring around its own parent (the 44 px root, margins -4 px), while the face is `size`. Stroke position outside the face: 4 to 6 px at md, 8 to 10 px at 32 px, 12 to 14 px at 24 px. The 2 px gap the comment at `StateLayer.qml:141-146` requires only holds at size 44 or more. The record's "rings hug the face" (line 9) is true of the selection ring only. Fix: keep the 44 px pointer target on its own item and size the StateLayer to the face. Shared: false.
- **D6 major, selected ring blends into the host on pale samples.** `ColorSwatch.qml:237-253`, `:114-116`. The ink is chosen against the sample only. For the `warning` and `accent` samples it is band #271e30, whose contrast against host `surface` is 1.30:1. The ring's outer edge is the face's edge, so a selected pale swatch shows a dark outline merged into a dark host, reading as a smaller swatch. WCAG 1.4.11 needs 3:1 against adjacent colours. Host colour assumed `surface`. Fix: a selection ring outside the face at `spaceTight` in `accent`, which is 6.82:1 against surface. Shared: false.
- **D7 minor, pressed state has no visible response.** `StateLayer.qml:59` (`pressScale` default 1), `ColorSwatch.qml:270-281` (not overridden). The record's "swell on hover and press" (line 11) is false for press. Fix: `pressScale: Motion.pressScale` on the face, or leave as-is and correct the record. Shared: false.
- **D8 minor, keypad Enter ignored.** `ColorSwatch.qml:283-284` handles Space and Return only. Qt delivers the keypad Enter as `Key_Enter`, which needs `Keys.onEnterPressed`. Fix: add `Keys.onEnterPressed: root.activate()`. Shared: false.
- **D9 minor, size does not scale the reading.** `ColorSwatch.qml:48` (a raw px property whose default is the md preset), `:260` (fixed `Style.textXs`, no `Style.textNear`). At lg (48 px) the reading is still 10 px in a 48 px face, the "two components" failure the component laws name. Fix: a `sizes.ColorSwatch` table in the theme and `Style.textNear` for the reading. Shared: true (tokens and Style).
- **D10 minor, literal colours.** `ColorSwatch.qml:85-86` (`#ffffff`, `#c0c0c0`), `:189` (checker cells), against the record's "no local colours" (line 10). Fix: a checker pair in tokens, read through `Style`. Shared: true (tokens and Style).
- **D11 minor, hover movement under reduced motion, and no size scaling.** `StateLayer.qml:56` takes `Motion.hoverScale` as a constant, so the face still swells 8 percent with `Style.reducedMotion` set. review-animations standard 8 says reduced motion drops movement. The lg hover (48 x 1.08 = 51.8 px) overhangs its 48 px footprint by 1.9 px a side, while the component laws say overhangs scale slower with size. Fix: `hoverScale: Style.reducedMotion ? 1 : Motion.hoverScale` and a size-scaled hover. Shared: false.

Source conflicts (record against code; the code is what runs, so the record must be corrected with the fix):

- Line 8 "reads on any ground" against D1 (3.70:1 at worst).
- Line 9 "rings hug the face" against D5 (focus ring).
- Line 10 "no local colours" against D10.
- Line 11 "swell on hover and press" against D7.

Redesign proposals (taste and design, for the owner to rule):

- Palette rows as one Tab stop with arrow keys, roving focus as in radio groups, instead of one stop per swatch.
- Selected state as an accent ring outside the face (D6), which needs a ruling against the focus ring's colour.
- Reading below small faces instead of inside them (D2).
- Compact palette: 24 px faces 24 px apart read as separate buttons; a tighter row or a grouping cue.
- Press response: `Motion.pressScale` on the face, 0.94 by the token, against the component's "colour only on a body" rule (D7).

Hypotheses (unmeasured):

- H1: the 4 px gap between palette targets makes hover flicker when a fast pointer crosses it.
- H2: the ring's `Behavior on border.width` passes fractional widths mid-tween, a shimmer at 1 px.
- H3: checker seams at odd sizes, where `face.width / 4` is fractional. No used size is odd.
- H4: `Keys.onSpacePressed` fires on press, while a native button activates on release.
- H5: D2's text width is arithmetic from a 0.6 em advance. Font metrics were not read.

Not examined: no runtime, capture, Workbench session or preview (the owner's rule for this audit). The deep-night tokens were read; the light backend was not. The host background was assumed to be `surface`. Keyboard, focus ring rendering, reduced motion and screen-reader behaviour were not run. No caelestia sibling exists: `~/Clonned/caelestia/repo/components` holds no swatch control.
