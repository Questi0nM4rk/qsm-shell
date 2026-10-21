# Scrim

The ground going quiet behind something that has taken over; it dims what is behind and catches the pointer so a modal is modal in behaviour, not just appearance.
states: shown and hidden with an opacity fade between them; hidden removes itself from the scene so it never eats clicks meant for the surface underneath.
actions: enumerated `dismiss()` and any-button click report `dismissed` while shown and enabled; the surface decides whether to answer it. Neither route changes `shown`.
pointer: catches every button while shown, enabled or not (a disabled scrim catches and reports nothing), so no click reaches the surface behind; wheel handling stays with the content above.
keyboard: none; Escape belongs to the modal content, never to the dim.
screen reader: no role of its own; the modal content names itself.
size: fills its parent; no preset and no natural size.
tokens: band and the medium Motion set with standard entry and exit easing; no local colours or measurements.
motion: medium opacity fade; reduced motion shortens the duration.
expected: enumerated `dismiss()` and every-button click share `dismissed` while shown and enabled. Hidden/disabled requests report nothing; the function never writes `shown`, closes its host or takes modal keyboard policy.
not designed: modal content, focus trapping or dismissal policy; use Dialog, Popover or the host for those.

## UIX audit

Evidence: source-reviewed only. Runtime-exercised: none. Owner-accepted: none. Read: Scrim.qml, Dialog.qml (its only library consumer), Card.qml, Surface.qml, Style/Motion.qml, Style/Tokens.qml, workbench/units/Scrim.qml. No capture, tree dump or Workbench session was run. Accessibility criteria are a11y-audit's.

**Purpose and consequence.** The ground behind a modal goes quiet and stops taking clicks. If the catch fails, a click meant for the modal reaches the shell behind it while the dim says the shell is modal.

**Consumers.** qsm-desktop references no Scrim (grep of the whole repo: no match). The only library consumer is Dialog.qml:114. Every finding below is latent until a production surface uses it.

**Controls and states.** Properties: `shown` (bool, false), `strength` (real, 0.55, Scrim.qml:21), inherited `enabled`, signal `dismissed`. Functions: `dismiss()`, and an `actions` list with one `T.Action` "Dismiss" (Scrim.qml:24). Implemented: shown, hidden, enabled, and disabled-while-shown (the dim paints but the catch is off, see D2). Not implemented: hover, pressed, focus (see P2).

**Routes.** Pointer: MouseArea over the parent, all buttons, `onClicked` calls `dismiss()` (Scrim.qml:45-51). Keyboard: none in Scrim; Escape is the Card's `Keys.onEscapePressed` in Dialog.qml:147. Wheel: no handler (H1). Focus: Scrim is not focusable. Screen reader: no role or name on Scrim. Programmatic: `runAction("dismiss")` in the unit reaches the same function.

**Sizes, empty, failure, cancellation.** Fills its parent (Scrim.qml:31, 46), no implicit size, no content. Dismiss while hidden or disabled reports nothing (Scrim.qml:27). The Dismiss action is enabled only while shown and enabled (Scrim.qml:24). `dismiss()` never writes `shown`; the host closes the modal (Dialog.qml:116 passes `dismissRequested` upward).

**Visual roles and palette.** Dim colour is `band` (Tokens.qml:6, #271e30) at `strength` 0.55 (Scrim.qml:32), composed with `opacity`. No text sits on the scrim. Dialog's card is `Style.overlay` (Tokens.qml:8, #534a5e, Dialog.qml:119 onward). Computed from the token hex values with the WCAG formula, not rendered: overlay on band 1.91:1, surface (#42394c) on band 1.46:1, overlay on surface 1.31:1.

**Motion and reduced motion.** One `Behavior on opacity` (Scrim.qml:38-43), duration `Motion.medium` = 260 ms (Tokens.qml:50), 100 ms under reduced motion (Motion.qml). Enter uses `Motion.standardEasing` (OutCubic), exit `Motion.exitEasing` (InCubic). Opacity only, no transform. The Behavior retargets from the current value.
Verdict under review-animations: enter, interruption and reduced motion pass (the fade is kept and shortened). Exit is Block: ease-in on UI is on the escalate list (C1), and exit runs the same 260 ms as entry (D4).

**Pointer geometry (modelled, not measured).**
- Input shape: MouseArea `anchors.fill: parent` (Scrim.qml:46). Painted shape: Rectangle `anchors.fill: parent` (Scrim.qml:31). They are identical and equal the parent. Assumed viewport 1920 x 1080 logical px (assumption).
- Task: dismiss by clicking the ground. Origin assumption: pointer at the card centre, the card centred by Dialog.qml:122. Card width 380 px (Tokens.qml:86 geometryControlWidth, Dialog.qml:36 default).
- D = 190 px, from the centre to the card edge. Width model: W is the ground strip's extent along the approach axis, from card edge to viewport edge, = (1920 - 380) / 2 = 770 px.
- D/W = 0.247. ID = log2(1 + 0.247) = 0.32 bits. Aiming is trivial, so the risk is misfire, not aim.
- Landing tolerance: 0 px inside the card. The scrim starts at the card's painted edge, so any card pixel with no handler of its own becomes a dismiss press (D1).
- Neighbouring interference: the card's non-interactive text and gaps. Its real controls accept first and are not affected.
- Popup corridor and timing: not a popup, no trigger corridor. Only the 260 ms fade.
- Label origins and weights: none.

**Findings: source-backed defects.**

- D1, major, open (deferred: the fix lives in Dialog.qml or Card.qml, outside Scrim's files). Scrim.qml:45-51 catches every press, and Dialog.qml:119 declares its Card after the scrim, so the card stacks above it. Card.qml and Surface.qml have no MouseArea, TapHandler or HoverHandler (checked by grep), so a press on the title, the body text, the padding or a gap between controls is not accepted above and falls through to the scrim, which emits `dismissed`. A person sees the dialog ask to close when they press its own title. Fix: the Dialog's card takes presses itself (in Dialog.qml or Card.qml, a MouseArea with `acceptedButtons: Qt.AllButtons` and an empty handler), so only the real controls and the card's own pixels act, and the ground does not. Also add a card above the scrim to workbench/units/Scrim.qml so the story can show this. Evidence: source-reviewed; the Qt delivery rule is assumed, not run.
- D2, minor, fixed (source-reviewed, load-checked; not owner-accepted): the MouseArea is now `enabled: root.shown` and the `dismiss()` guard stays. Scrim.qml:47 sets the catch to `root.shown && root.enabled`, while the dim paints from `shown` alone (Scrim.qml:33). A disabled, shown scrim dims the surface and lets clicks through. The file header (Scrim.qml:6-9, "modal in appearance only") and Scrim.md line 6 ("catches every button while shown") both say it must catch. Fix: choose the contract. Proposed: the MouseArea is `enabled: root.shown`, and the `dismiss()` guard at Scrim.qml:27 stays, so disabled catches and reports nothing. Then correct Scrim.md line 12 to match.
- D3, minor, shared=true. Scrim.qml:21 `property real strength: 0.55` is a number in a component. AGENTS requires every number to come from Style or Motion, and Scrim.md line 10 says "no local colours or measurements". Fix: a `Style` token for the scrim strength, backed by tokens/deep-night.json and generated with `npm run tokens`, and the default read from it.
- D4, minor, shared=true. Scrim.qml:38-43 uses `Motion.medium` for both directions, so exit is 260 ms, the same as entry. review-animations standard 4 asks exit to be about 80 percent of entry. Fix: a named exit duration in Style/Motion.qml, used on the exit side here (Dialog.qml uses the same pattern and is affected too).
- D5, minor, fixed (source-reviewed, load-checked; not owner-accepted): the unit ground is `Style.surface`. workbench/units/Scrim.qml:14 paints the unit ground with `Style.band`, the same colour as the dim (Scrim.qml:32). Band over band is 1.0:1 (computed), so the story shows the dim only on the Prose text, not on a ground. Fix: a ground in another role (e.g. `Style.surface` with content on it), inside the unit only.

**Source conflicts.**

- C1. Motion.qml's `exitEasing` is `Easing.InCubic`, and its comment calls accelerating away deliberate. review-animations standard 3 and its escalate list name ease-in on any UI as a block. Affects Scrim.qml:41 and Dialog.qml's exit curves. The owner decides which wins; until then the exit verdict stays Block.

**Hypotheses (not measured).**

- H1. No wheel handler (Scrim.qml:45-52). The event is not accepted, so it goes to ancestors, not to items under the scrim, and the list behind should not scroll. Scrim.md line 6 says wheel "stays with the content above", which the code does not express. Needs a runtime check.
- H2. The unit's disabled option sets the unit's `enabled` (workbench/units/Scrim.qml:40-41). Scrim's `dismiss()` guard reads its own `root.enabled` (Scrim.qml:27). If Qt reads the explicit value rather than the effective one, `runAction("dismiss")` emits while the unit is disabled. Qt semantics assumed, not run.
- H3. During the 260 ms exit the catch is already off (Scrim.qml:47) while the dim is still painted (visible while opacity > 0, Scrim.qml:36). Clicks reach the surface behind under a half-dim ground. Whether that is wanted depends on the D2 decision.
- H4. The card (overlay) separates from the scrimmed ground by a ratio that depends on the wallpaper under the scrim. The ground moves toward band; separation rises over a ground lighter than band and falls over a darker one. Needs a capture over a real wallpaper.
- H5. Scrim fills its parent. A host whose parent is smaller than the viewport catches less than the screen. No production consumer exists to check.

**Redesign proposals (taste, not defects).**

- P1. The dim colour is band at 0.55. A dedicated scrim role may read better than the frame colour. For comparison only, from memory and unverified against the current M3 spec: Material 3 documents a modal scrim at about 32 percent. Owner decision.
- P2. Five-state law: Scrim has an interactive Dismiss action and a press route but defines no hover, press or focus state (AGENTS definition of done, item 2). Decide whether Scrim is a background, where Dismiss is a host route and the law does not apply, or an interactive target. Recommended: background, since a ground should show no affordance.
- P3. Right-click on the ground dismisses (Scrim.qml:50, `Qt.AllButtons`). That is one more route for a dialog holding unsaved work; the host can refuse it. Keep it, but say so in Scrim.md.
- Side finding, outside this component: AGENTS states that each neutral ladder step is 1.30:1. From the token values, surface on band is 1.46:1 and overlay on surface is 1.31:1 (Tokens.qml:5-8). The owner should check which claim holds.

**Not examined.** Captures and tree dumps (none requested); runtime interaction, wheel and focus; the reduced-motion form at runtime; themes other than the deep-night tokens read here; real wallpapers; keyboard and screen-reader behaviour (a11y-audit's); Dialog's own states beyond its scrim (a separate Dialog audit).
