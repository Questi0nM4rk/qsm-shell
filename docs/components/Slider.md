# Slider

states: rest hover(thumb grows rhythm(space1·s) per side and overflows the control, uncapped, never added to its layout size; a pill grows along its length only, twice as far) press(growth kept, shadow lift doubles) focus(ring around the track at a spaceTight gap, concentric, under the thumbs, never around the label) disabled(every painted role through Style.disabled, still reads)
range: one type, one or two thumbs; range: true paints the low thumb (lowValue) and the fill runs between the thumbs, which never cross (Qt keeps low <= high); keyboard, wheel and actions step the last thumb a pointer grabbed, the high one until then; the high thumb alone carries thumbIcon/thumbText
actions: Increase Decrease Minimum Maximum (on the active thumb), Activate label (`activate-label`) when its label is enabled, actionable and nonempty; each action has a stable objectName. `activateLabel(): bool` emits `labelClicked` without changing host state.
size: `size` is a preset name resolved by Style.size("Slider", name) into thumbSize (thickness/thumbSize stay the API); s = preset / md; track = rhythm(two thirds of the preset) above the sm preset, a space1 hairline at or below it (under 0.7 of the thumb the fill's rounded end stays hidden behind the thumb, geometry not taste; a track thicker than its thumb runs the fill on to a full round cap concentric with the thumb, so a ring of fill colour surrounds it and no straight edge shows, and at either bound the ring is the track's end cap); hover growth rhythm(space1·s), label gap rhythm(space2·s), label text/glyph through ControlLabel.sizeScale. Main axis sliderLength / sliderLengthVertical plus the label; cross axis at least controlHeightSm and the thumb; growth and the shadow drop overflow it
thumb: thumbStyle circle (rides on the track, carries thumbIcon or thumbText) | pill (space1 bar standing space2 proud of the track, in a space1 gap whose cut ends are radiusXs/2, Material stop dot at the far end, carries nothing); thumbIconSize sets the glyph edge (default: the thumb less space2 per side, snapped by Style.iconNear); grabThumb (default off) makes a press on the thumb a grab that moves nothing and a drag then keeps the pointer's distance from the thumb's centre, where off it jumps the value to the pointer like a press anywhere; the thumb carries its own drag handler, so a host's TapHandler or other pointer handler on `second.handle` does not stop the drag; a circle's travel is never shorter than the track is thick
label: ControlLabel (the element Field uses above a text box) with labelText and/or labelIcon (label role, iconSm) at labelPosition above|below|left|right, whatever the orientation; it takes padding on its side so the track never moves for it. labelClickable makes it the slider's one action surface (StateLayer, hit box at least iconLg, hand cursor) and the host maps the click in onLabelClicked; off, it is a caption and takes no pointer. `labelAccessibleName` defaults to labelText for icon-only labels. Readonly `labelItem` exposes that same actual ControlLabel as a native composition target.
accessibility: `accessibleName` (default labelText) names the slider (role Slider) and its thumbs; a range's thumbs read `<name> minimum` / `<name> maximum`. `labelAccessibleName` names only the label's action
pointer: with one thumb, every press anywhere in the control's cross band (not only the track's thickness) takes one path, `pointerPath`; the label is outside it
wheel: `wheelUnits > 0` is the host's opt-in; a vertical wheel drives either orientation (a mouse has no other axis), a sideways wheel only a horizontal slider; a host that wants the scroller under the slider leaves it 0
colours: fill (default primary, the active part of a track) trackColor thumbColor thumbContentColor are the host's; the component never recolours a part for a state
tokens: sliderStep sliderKeyboardUnits sliderPageUnits sliderLength sliderLengthVertical sliderThumbLift space1 space2 iconXs iconSm iconLg controlHeight controlHeightSm primary overlay text textOnPrimary textMuted textSm textXs weightBold Style.disabled
motion: fast+standardEasing on the painted position, only when the change did not come from a gesture; micro on thumb growth and colour; press on the shadow lift. Reduced motion removes the position animation and shortens the rest
events: moved(gesture in progress) committed(gesture finished, a held key that lost focus, availability or visibility included; committedValue and committedLowValue are where the last gesture left the values)
keyboard: focused track/thumb handles its axis arrows, Page/Home/End and shared decrease/increase keys from Interaction (N/O by default). `decreaseKey`/`increaseKey` override them per instance; zero disables a custom binding and equal custom bindings are ignored. Ctrl/Alt/Meta custom combinations and focused label actions are not level commands. Text entry elsewhere stays text entry. Repeats nudge; real release commits once; focus/availability loss clears held-key state. Horizontal inline use maps N/left to decrease and O/right to increase in the normal LTR layout; the existing mirrored arrow semantics remain unchanged.
host keys: `keyPressed(event)` exposes the live event before value/template handling; accepting it claims navigation or editor exit while all other keys retain the shared Slider route. It is the same interception contract as TextField, not a separate keyboard implementation.
not designed: end slots (the label is the one thing beside a slider), ticks, wavy fill, value tooltip

## UIX audit

Evidence: source-reviewed only. No live geometry, accessibility tree, capture or input was used, so every row cites file and line. Runtime-exercised: none. Owner-accepted: none.

### Purpose and consequence

One continuous value the person sets by pointer, wheel or keyboard: one thumb, or a low and high pair. A wrong or lost value is heard (volume) or seen (seek, brightness) at once. The host owns the value (Slider.qml:31-36) and receives `moved` and `committed`.

### Controls and states

- Expected: value, lowValue, range, size, thumbStyle, thumbIcon, thumbText, grabThumb, wheelUnits, label text/icon/position/clickable/accessible name, fill, trackColor, thumbColor, thumbContentColor, decreaseKey, increaseKey, raised, keyPressed, actions.
- Implemented: all of them (Slider.qml:66-164, 74-76, 265-296).
- Unit coverage (workbench/units/Slider.qml:71-101): state, range, size, thumb, wheel, label action, mute. Not covered: value at first or last (min/max), thumbText, thumbIcon off, orientation. AGENTS asks for first, middle, last and all-disabled per option.
- Valid states: enabled, disabled, rest, hover, press, keyboard focus, single or range, label action enabled or caption.

### Routes (source)

- Pointer, single thumb: `pointerPath` MouseArea (Slider.qml:730-795). Track press jumps (749-772), thumb press grabs when grabThumb (758-761), drag (773-780), release and cancel commit (781-790), thumb double-click reported (791-794). Disabled for range (732), where Qt's handles take the press (640-658).
- Label: ControlLabel `clicked` calls `activateLabel` (438, 159-164). The label is focusable and Enter/Space activate it (ControlLabel.qml:61, 74-93).
- Wheel: MouseArea over the whole control, enabled only when wheelUnits > 0 (978-981). 120 units per notch, accumulated (968-1005). See SL-3.
- Keyboard: focused handle or label. On-axis arrows step sliderKeyboardUnits (856-872, 5 units). PageUp/PageDown step sliderPageUnits (890-900, 20). Home/End go to min/max (901-910). N/O are the default decrease/increase (Interaction.qml:9-10; Slider.qml:75-76, 876-888). Holding repeats; release commits once (918-942). Host intercepts via keyPressed (74, 545, 852-853).
- Focus: ring at the track, not the label, shown when root or either handle has visual focus (678-699). A pointer press focuses with MouseFocusReason (770-771).
- Accessibility (source): no `Accessible` property is set on the slider or its handles (grep of Slider.qml). ControlLabel reports Accessible.Button when clickable and StaticText otherwise (ControlLabel.qml:65-67). Actions are increase, decrease, minimum, maximum, activate-label, each with an objectName (265-296). Tree not read, so name, role and state verdicts are not tested here and belong to a11y-audit.

### Sizes, empty, long, failure, cancellation

- Sizes from tokens `sizes.Slider` (sm 16, md 24, lg 40 thumb). Track thickness 4 / 16 / 28 (Slider.qml:117-118, rhythm of two thirds of the preset). Reserved cross extent 32 / 32 / 40 (409, 416-418). Natural main axis 260 horizontal, 180 vertical (415, 417).
- Empty label: no padding (165-169, 422-425). Empty thumbText: no reading (621).
- Long label: widens the natural size (SL-6).
- Long thumbText at sm: a 10px reading in a 16px thumb is not examined (623-626).
- Pointer cancel: commits when the value changed (781-790). Focus loss during a key hold: no commit (SL-10).
- Disabled: every painted role through Style.disabled (299-303). Pointer and keys ignored (219, 240, 850, 980).

### Visual roles and pairs

Track is `overlay` (80), an inactive track per the ladder. Fill defaults to `accent` (79), see SL-5. Thumb is `text` (81) on a `band` ring (86), with `textOnPrimary` content (88). Focus is the `focus` role via StateLayer. No contrast value was measured, because no pixel channel was used.

### Motion and reduced motion (source)

- Position: `fast` with `standardEasing` on `_paintedHigh` and `_paintedLow` (331-338), only when the change is host-driven (322-327, 306-308). Reduced motion removes the Behavior through `enabled` (332, 336).
- Thumb growth: `micro` (566-568); thumb colour `micro` (604-606); press lift on the shadow with `press` (561, 569-572); shadow only when raised (576).
- Reduced motion shortens micro to 60 ms and press to 40 ms (Motion.qml:24-26). The verdict on feel belongs to review-animations and was not run.

### Pointer geometry (source)

- Input shape: track presses hit the `pointerPath` band, whose height is the track thickness (694-698, 734). Thumb presses hit the thumb rectangle (550-557). Whether Qt's own press covers the whole reserved box is unverified (H-1).
- Painted size: thumb 16 / 24 / 40, track 4 / 16 / 28.
- Assumptions: horizontal, no label, D = 120 px fixed for comparison. Travel is 244 / 236 / 220 px (260 minus the thumb). Width model: W is the cross-axis extent of the press region, because the pointer travels along the track and a miss is vertical. Along-axis tolerance is the value step, not a width.
- Label origins (assumed): left label at x = 0 (441-443), footprint its implicit width, gap rhythm(8 x s) = 4 / 8 / 12, hit box at least iconLg x s = 16 / 24 / 40 tall (ControlLabel.qml:132-133). Label weight is the label role, unmeasured.

| size | W band (track press) | W reserved box | ID band (bits) | ID reserved box (bits) |
| --- | --- | --- | --- | --- |
| sm | 4 | 32 | 4.95 | 2.25 |
| md | 16 | 32 | 3.09 | 2.25 |
| lg | 28 | 40 | 2.40 | 2.00 |

ID = log2(1 + D/W) with D = 120. Band: log2(31), log2(8.5), log2(5.29). Reserved box: log2(4.75), log2(4.75), log2(4).

- Landing tolerance: a press lands on the nearest value step. One step is 1% of travel (2.4 / 2.4 / 2.2 px), so half a step is about ±1.2 / ±1.2 / ±1.1 px along the axis.
- Interference: the wheel MouseArea covers the control when enabled but accepts only wheel events (978-981). Spacing between neighbouring sliders is declared by the host and not measured.
- Popup corridor: not applicable, the slider is not a popup.

### Findings

Defects, source-backed:

- SL-1 fixed (source-reviewed, load-checked): growth is uncapped and overflows, as the comment said. Original finding: Slider.qml:403-405, 409, 560, 597-598. Hover growth is capped by `_growthRoom`, which is the reserved cross extent minus the thumb, divided by two. At lg that is (40 - 40) / 2 = 0, so a circle thumb does not grow on hover, and the thumb colour has no hover branch (602). A lg pill grows 2 px instead of the 8 px `_hoverGrowth` (402) gives. Slider.md line 3 and the AGENTS hover law (grow and change colour) say otherwise. Fix: reserve the growth room in the cross size (thumb + 2 x hover growth), or let growth overflow as 394-397 describes, and make the record match.
- SL-2 fixed (source-reviewed, load-checked): `pointerPath` covers the available area, the whole cross band. H-1 is moot for the single thumb. Original finding: Slider.qml:694-698, 734, 407-409, 416-418, 720-729. The track press region is the track thickness (4 / 16 / 28 px), but the reserved cross extent is 32 / 32 / 40 px, and 407-408 says the control stays aimable. The comment at 720-729 says one press path, with Qt's press never running. The geometry does not guarantee it: presses outside the band take Qt's native press, which skips grabThumb and the double-click bookkeeping. Fix: make `pointerPath` cover the full cross band of the control, so every track press takes one path.
- SL-3 resolved the second way (source-reviewed, load-checked): a vertical wheel driving a horizontal slider is kept, because `wheelUnits` is the host's opt-in and a mouse has only that axis; the comment and this record now say so. Owner ruling needed if an on-axis-only wheel is wanted instead. Original finding: Slider.qml:983-988, 991-993. The comment says the wheel is on-axis, but the code uses `angleDelta.y` for both orientations. On a horizontal slider with wheelUnits > 0, a vertical wheel changes the value and the event is consumed, because `accepted` is only handed back when delta is 0. Consumers that set wheelUnits: BarPopouts.qml:386, SoundPopoutContent.qml:71, OsdChannel.qml:55, LauncherSurface.qml:1255. Whether any sits in a scroller is not checked. Fix: take delta from the axis only (y when vertical, x when horizontal) and hand back when it is 0. If the owner wants vertical wheel on horizontal sliders, the comment is what changes.
- SL-4 fixed (source-reviewed, load-checked): `accessibleName` names root and thumbs; the tree was not read, so the 4.1.2 verdict stays a11y-audit's. Original finding: Slider.qml (no Accessible property; labelAccessibleName used only at 292, 434). The slider and its handles have no accessible name, so a screen reader announces a value with no name. Criterion 4.1.2 is a11y-audit's verdict and is not tested here. Fix: add `accessibleName` defaulting to labelText, and set `Accessible.name` on the root and the handles.
- SL-5 fixed (source-reviewed, load-checked): fill defaults to `primary` and the unit follows; owner ruling needed if accent was accepted on purpose. Original finding: Slider.qml:79; workbench/units/Slider.qml:54. The default fill is `accent`. Style.qml:38-39 and the surface ladder say `primary` is the active part of a track, and `accent` is for focus, selection and primary action, never passive metrics. Fix: default `fill` to Style.primary, and the unit's fill to match. Owner ruling needed if accent was accepted on purpose.
- SL-6 (medium), Slider.qml:165-169, 413-415, 422-423; ControlLabel.qml:62, 109-116. A long label widens the natural size, because label width enters both the padding and implicitWidth, and ControlLabel has no elide or width cap. This violates the component's definition of done, which says natural size is constant and long content elides. Fix: cap the label's width in ControlLabel and elide. Touches ControlLabel, so shared.
- SL-7 (low), ControlLabel.qml:132-133 with sizeScale from Slider.qml:437 and 106. A clickable label's hit box is iconLg x sizeScale, which is 16 px tall at sm. The ux-audit floor for a desktop pointer is 24 x 24. The ControlLabel comment says "at least one large icon", which the scaling undercuts. Fix: floor the hit box at the unscaled iconLg. Touches ControlLabel, so shared.
- SL-8 (low), Slider.qml:582. The thumb shadow uses a literal `Qt.rgba(0, 0, 0, .45)`. Style.shadow exists (Style.qml:59, token colorShadow) and the opacity tokens are 0.28. The alpha is a number outside the tokens and does not follow a theme. Fix: take the colour from Style.shadow and the opacity from a named token. Adding a token touches tokens/*, so shared.
- SL-9 fixed (source-reviewed, load-checked): wrapped in Style.iconNear. Original finding: Slider.qml:140. `thumbIconSize` is not snapped to the icon scale. At thumbSize 30 it is 22 px, which is not on the icon scale of 12, 16, 20, 24 (icon tokens). Fix: wrap in Style.iconNear.
- SL-10 fixed (source-reviewed, load-checked): clearing a gesture that moved emits `committed`. Original finding: Slider.qml:944-956, 944-952. Clearing held-key state on focus loss resets `_keyMoved` without emitting `committed`, and the key release may never arrive. A value moved by a held key can then end with no commit, even though the event contract says committed ends the gesture (Slider.qml:172-175, Slider.md line 12). Fix: emit committed when clearing a gesture that moved.
- SL-11 fixed (source-reviewed, load-checked): the unit has a `value` control with first, middle, last. Original finding: workbench/units/Slider.qml:12-13, 71-101. The unit never shows value at min or max, so the can-increase and can-decrease states at the bounds are never reached in the window. Fix: add a value control with first, middle and last options.

Source conflicts (owner ruling):

- BACKLOG R2/R3 says the unit does not answer label clicks. Source does answer: `onLabelClicked` (unit:57-60), `activate-label` in actionHandlers (unit:25) and in integration (unit:105). The unit's default is labelClickable false (unit:18), so the default story's label is a caption and a click does nothing. That holds only in the caption state, and the label control switches it (unit:93-96). Status: not reproduced in source; it needs a runtime check.
- Slider.qml:38-41 says the component never recolours a part for a state. AGENTS requires hover to grow and change colour. The thumb has no hover colour, so the two disagree.
- Slider.qml:86-88 paints a band-coloured ring around the thumb. The ladder says layers are separated by a step, never by a line. The ring is a gap, not a line, but the owner should rule on it.

Proposals (taste, not defects):

- The sm preset puts a 16 px thumb below the 24 px desktop floor, by design as a hairline reading rail. The owner should decide whether a grab target that small is acceptable.
- Unit `ods` (unit:11) is a cryptic name for the OSD variant.
- thumbText at sm is not examined and may overflow a 16 px thumb.

Hypotheses (unmeasured):

- H-1: Qt's native press covers the whole reserved box, which would make SL-2 milder than it reads. Unverified.
- H-2: Thumb hover (`node.hovered`, Slider.qml:559) may not fire while `pointerPath` sits above the handle. Unverified.
- H-3: A pill's grab target is 4 px wide (Slider.qml:551, 597), so horizontal pill presses land on the band only. Unverified.

Not examined: runtime behaviour, tree, captures and input; pixel contrast; vertical geometry (not computed, only horizontal); range-mode pointer path beyond the Qt handles; the desktop layouts that host the sliders; sm thumbText overflow; reduced-motion feel.

### Evidence split

- Source-reviewed: every row above.
- Runtime-exercised: none.
- Owner-accepted: none.
