# DataCapsule

An auxiliary data container for a quick reading without leaving the application.
It is not the Capsule button or a Rollout: no edge joins, translation, deformation,
services or window policy. A host places it above fullscreen when appropriate.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture/task | Glance at a reading; optionally open its owning view | Quiet Luminous; application remains primary | auxiliary, non-modal | fullscreen host and click outcome |
| ia | Caller content in one clipped slot; fixed cross-axis size and preferred length, either orientation | Host owns the infoblock, long content must not grow the capsule | `Style.size("DataCapsule", size)`, `Style.controlWidth` | horizontal/vertical, small/large and explicit host sizing |
| interaction | Host owns `shown`; `timeout <= 0` is persistent; positive timeout requests dismissal once | AGENTS host-owned state; Radix Toast controlled visibility and pause pattern | `timeoutRequested`, `restart`, `reset` | real timer, reset and repeated presentation |
| interaction | `hoverStay` pauses the remaining timeout; keyboard focus (never a click's focus) holds it | Pointer and keyboard users must finish interacting | ancestor HoverHandler, content FocusScope | nested control hover/focus and resume |
| hierarchy/token | Border material, no rim or passive accent; optional whole-body action; diffuse shadow outside body | Owner's requested same material as Rollout/border, levitating rather than edge-joined | `Surface`, `Style.band`, `Style.rolloutRadius`, floating-shadow roles | resting/hover/pressed/focus/disabled states |
| responsive | Host sets position/anchors at any screen edge and actual footprint; component sizes its body, never a screen | Screen placement and infoblock sizes are host decisions | `orientation`, `size`, `bodySize`, `preferredLength`, `sizeScale`, `padding` | compact and larger content hosts |
| responsive | Centre the complete content group inside the padded slot; sound composition fits its natural group instead of reserving an unrelated long strip | Owner rejected off-centre and overflowing capsule content | caller layout, `contentItem`, `Style.rhythm`, shared padding | live sound, OSD and notification bodies include their complete content envelope |
| responsive | Orientation chooses the composition, not the text's rotation: horizontal content is a centred text group; vertical content is a glyph with its reading | A wide text composition in a narrow column leaves nothing legible in the clip | caller layout, `contentItem`, `Style.textNear`/`iconNear`/`rhythm`, `sizeScale`, reactive `TextMetrics` | horizontal and vertical at sm/md/lg with short, default and long length; widths round up, then stay slot-bounded and elide |
| state | Empty remains an empty slot; loading/error/readings belong to content; `interactive: false` remains legible | Report-only is not unavailable | `interactive`, `enabled`, Accessible grouping/button | passive, unavailable and nested action routes |
| polish | Opacity only, reversible fade, no growth or positional animation | Owner request; blueprint purposeful motion | `Motion.medium`, `Motion.micro`, enter/exit easing | fade reversal and reduced motion |

`activate()` emits `activated` only when shown, enabled and interactive. Pointer,
Return, Enter, Space and the exposed action share it. Nested controls keep their
own action; the empty body is the whole-capsule action. `reset()` cancels pending
timeout work without changing host visibility; `restart()` refreshes its budget.
`pointerHovered`, `keepOpen`, `present`, `animating`, `acceptsInput` and `remainingTime()` expose facts
needed by a window host; a fading-out picture must not retain an input mask.

## Expected

The neutral base must show short/long/empty caller content on a labelled mock
screen. Edge, alignment, inset, orientation, size, length, lifetime, retention,
elevation and availability controls operate the real container. The workbench's
simulated fullscreen context changes the mock application/frame, not the actual
window, capsule identity or content state. The owner judges this base first.
Control axes are separate labelled groups, not mixed option grids: edge,
alignment, inset, orientation, size, length, content, lifetime, retention,
elevation and availability. Presentation commands have their own group.

The neutral base was runtime-exercised in a visible Workbench window after the
reactive text-metrics fix: six native-frame-polished horizontal and vertical
short-content states cover sm/md/lg, with long content elided and empty content
remaining empty. Short text fits all sizes; lg's ten-character reading is legible.
Natural sizing, centred content and preset propagation were exercised. The
owner accepted the appearance of the capsule composition they watched; this
acceptance is limited to that visual review and does not imply unviewed states,
catalog-wide acceptance or service integration. Attached Rollout acceptance is
separate.

The base's content is one auxiliary task — the current workspace and whether its
details are ready to open — composed two ways because the two cross axes are
different shapes, never by rotating one text layout. Horizontal: a centred
title over its supporting status, elided where the sentence is longer than the
slot; on a short cross axis (sm) the same task collapses to one legible line
instead of two squeezed ones. Vertical: a known workspace glyph with its reading
under it, sized for a 32-96px column; the long sentence is left out rather than
crammed into a width that cannot hold it. Every group is centred in the padded
slot and bounded by it, all text goes through `Style.textNear`, `iconNear` and
`rhythm` against the capsule's `sizeScale`, and the whole task is announced once
through `accessibleName` whichever way it is painted. Empty content is still an
empty slot, and interactive, report-only and disabled states change only who
answers, never the reading.

Owner-requested declaration correction is implemented and base flow passes;
the generic renderer's stable geometry and elastic inspector belong to workbench.
The owner authorized progression from the neutral base to Compose.

After base acceptance, a separate `capsule-sound` Compose must use actual nested
nodes and the real Slider: reading in its thumb, mute as its label action, stored
level independent of mute, and a level write unmutes, as a host's audio service typically does.
Fresh child events route to the container's open/restart action; one host lifetime
handles expiry. Screen placement belongs to the shared provider fixture, never
the library. No production audio service is invoked.

Contract: `openspec/changes/fullscreen-capsule-composition/`. Production
notification and OSD capsules were exercised in a compositor-fullscreen run:
notification rows measured 380x36 collapsed and 380x74 expanded inside
396x52/396x90 bodies with 8px inset; the 56x650 OSD body contained all three
channels' thumbs, labels and glyphs. The watched capsule appearance is owner-
accepted; these measurements and runtime flows do not extend that acceptance to
unseen states or unrelated service routes. Audio/brightness mutation routes
were not invoked. CPU/memory wiring remains separate.

Size presets: sm 32, md 64, lg 96 cross-axis pixels; lengths and padding scale from
md, radius stays constant and Qt clamps it to the painted body's short side.
Slots use `sizeScale` and Style's snapped scales; orientation does not rotate text
or invent a layout for arbitrary content. `elevated` controls the diffuse shadow;
`Style.reducedEffects` removes it. Shadow is never included in the input footprint.

New tokens: shadow colour black, floating shadow opacity 0.28, blur 0.6, downward
offset 8px and extent 24px. They form one rethemeable floating-elevation role.
The border-material default intentionally supersedes the ordinary raised-body
default for this owner-requested container; the component takes `surfaceColor`.
Caelestia StyledTextField supplies the template/content/background
separation; Radix Toast supplies controlled timeout/pause semantics, not styling.

## Evidence

The neutral base's targeted 53-step flow exercises real input, activation
and host consequence, simulated environment changes, report-only behavior and
lifetime/reset cancellation. Boundary and mock-screen checks exercise shared
context/identity and placement. Sound Compose's 28-step sound flow and existing
57-step lifecycle flow exercise actual node input, component/route provenance,
independent mute and level, repeated presentation, timer cancellation and simulated
environment changes. The lifecycle flow predates the fresh reactive-metrics fix,
which does not affect sound behavior.
Focused native unit checks cover containers and sound targets. Production
compositor-fullscreen geometry and input were exercised separately from the
Workbench simulation. The recorded native content/fade capture averaged about
25 fps; that cadence is sufficient for this simple motion and is not 60 fps.

## UIX audit

Evidence: source-reviewed only. Read: `qml/QsmShell/Components/DataCapsule.qml`, `workbench/units/DataCapsule.qml`, `Surface.qml`, `StateLayer.qml`, `Prose.qml`, `Style/Style.qml`, `Style/Motion.qml`, `Style/Tokens.qml`, and caelestia `modules/osd/Wrapper.qml`. No Workbench session, preview, capture, test or tree dump was run. Runtime and acceptance statements above are not re-verified here. Numbers are computed from `Tokens.qml`; they describe a model, not a render.

### Purpose and consequence

A transient, non-modal reading that finishes one task: the reading is glanceable, and when interactive one action leads to its owning view. If it fails, the person misses a reading (lifetime wrong), cannot act on it (activation or focus wrong), or cannot tell what it says (name wrong).

### Controls and valid states

- Properties: `shown`, `timeout` (0 persistent, >0 timed), `hoverStay`, `interactive` (default false), `enabled`, `actionLabel`, `accessibleName` (default ""), `size` (sm/md/lg = 32/64/96 cross-axis), `orientation`, `preferredLength`, `radius` (`Style.rolloutRadius`, 28), `surfaceColor` (`Style.band`), `elevated`.
- Actions (line 40 to 46): Open (`activate`), Restart timeout, Cancel timeout (`reset`).
- Facts: `pointerHovered`, `keepOpen`, `present`, `animating`, `acceptsInput`, `remainingTime()`.
- Valid states: shown x interactive x enabled x timeout x hoverStay x orientation x size x content (empty, short, long). All are implemented in source. The unit exposes presentation, lifetime, retention, elevation and availability (`controls`); edge and alignment belong to `MockScreen`.

### Routes

- Pointer: the body MouseArea (line 170 to 178) activates; slot children (z 1) take their own pointer first. Hover is read by the ancestor HoverHandler (line 131 to 136).
- Keyboard: `focusPolicy` is StrongFocus only when `acceptsInput && interactive` (line 55). Tab reaches the root. Return, Enter and Space activate (line 180 to 182). Escape does nothing.
- Wheel: none on the container. Scrollable content inside the slot takes it.
- Focus: presenting never takes focus (interruption does not move it). Hiding clears focus (line 105).
- Accessibility: role Button when interactive, Grouping otherwise (line 57). Name (line 58). Accessible press action (line 59).

### Sizes, empty, long, failure and cancellation

- Sizes: cross-axis 32/64/96 (`Tokens.sizes`). Padding is `rhythm(space3 * sizeScale)`: sm 8, md 12, lg 20 (`Style.qml` 284 to 286). Default length `Style.controlWidth` 380; short `rhythm(190)` = 192; long `rhythm(570)` = 572.
- Empty: the body keeps its natural size; the slot is empty. Natural size is constant, as the law requires.
- Long: horizontal `Prose` roles other than body are NoWrap with ElideRight (`Prose.qml` 114 to 118), so text elides inside the slot. The slot clips with `clip: true` (line 161 to 166) and gives no cue for overflow from arbitrary children.
- Failure: `activate()` returns false while not accepting input (line 62). Timer expiry emits `timeoutRequested` once (line 122 to 126) and leaves visibility to the host. A host that ignores it keeps the capsule visible with no timer until `restart()`.
- Cancellation: `reset()` cancels the timer and does not touch host visibility. "Cancel timeout" is always enabled (line 46), even when no timer is armed.

### Visual roles, palette pairs and states (tokens, computed)

| state | body | feedback |
| --- | --- | --- |
| rest | `band` #271e30 | none |
| hover | `Surface.tone` lift, colour only; `StateLayer target: null` (line 155), so no growth | colour |
| pressed | `Surface.pressed` from `body.pressed` (line 137 to 141); `pressScale` 1 | colour |
| focus | ring from `StateLayer` via `host.visualFocus`; 2 px gap, 2 px stroke, outer radius 32 at md, outside the body | keyboard only |
| disabled | `Style.disabled` colour (`Surface.qml` 29 to 31, 40) | colour |

Pairs: `text` #f0ecf5 on band 13.71:1; `textMuted` #c5bad1 on band 8.61:1; `accent` #d9b4ea on band 8.87:1 (the ring's neighbour is application content, not band, see H2); band on white 15.97:1; band on #1e1e1e 1.04:1 (H1).
Elevation: `Style.shadow` black at 0.28, blur 0.6, offset 8, extent 24 (`Tokens.qml`), skipped under `reducedEffects` (`elevated` on the layer).

### Motion and its reduced-motion form

- Show: opacity 0 to 1 over `Motion.medium` 260 ms with `standardEasing` OutCubic (line 115; `Motion.qml` 120).
- Hide: opacity to 0 over `Motion.micro` 130 ms with `exitEasing` InCubic (`Motion.qml` 125).
- Colour on hover and press: `Surface` `Behavior on color`, `Motion.micro` (`Surface.qml` 42 to 44). Ring fade: `Motion.micro`.
- No position or scale animation.
- Reduced motion: `Motion.medium` becomes 100 ms and `micro` 60 ms (`Motion.qml` 58 and 26). The opacity-only fade stays, which the law allows. Reduced effects removes the shadow.
- The motion verdict is review-animations' (see SC-2 and P2).

### Pointer geometry (model, assumptions labelled)

- Input shape: the root rectangle, `preferredLength x bodySize` horizontal or `bodySize x preferredLength` vertical. The painted body is the same rectangle, since the background Surface fills the control. Painted size equals input shape for the body. The shadow (up to 24 px) and the ring (4 px) lie outside and are not in the input shape.
- Origin assumption (assumed, not measured): the pointer starts in the screen interior. Distances D = 400 px and 800 px are placeholders, not human data.
- Width model: perpendicular approach to an edge capsule gives W = cross-axis size. Along-edge approach gives W = length (380 default).
- Difficulty, ID = log2(1 + D/W), perpendicular:

| size | W (px) | ID at D=400 (bits) | ID at D=800 (bits) |
| --- | --- | --- | --- |
| sm | 32 | 3.75 | 4.70 |
| md | 64 | 2.86 | 3.75 |
| lg | 96 | 2.37 | 3.22 |

Along-edge at W = 380: 1.04 bits (D=400), 1.63 bits (D=800).
- Landing tolerance: a perpendicular approach lands anywhere in the 64 px band at md. The host inset (unit default 16 px, `space4`) puts the body off the screen edge, so a pointer driven into the edge stops 16 px beyond the target and the edge is not an infinite target.
- Neighbouring interference: nested controls take their own pointer first. The padding (8 to 20 px) and any gap between nested controls activate the whole capsule, so a mis-click there fires the capsule action.
- Corridor and timing: not applicable. There is no trigger and no hover-open. Hover only pauses the timer (`keepOpen`). The time budget is the host timeout (unit "timed" 1000 ms) plus the 130 ms exit. Reach time is not measured, and no human average is claimed.

### Findings

Source conflicts (owner decides which wins):

- **SC-1. Hover growth.** AGENTS' Definition of done (item 2) and the StateLayer header say hover grows and changes colour. `DataCapsule.qml:155` sets `target: null`, so the body only changes colour. The record's polish row ("no growth") is about the fade, so the intent is unclear. Shared: no.
- **SC-2. Exit curve.** `Motion.qml` 125 sets `exitEasing` to InCubic, and its comment argues for ease-in. review-animations standard 3 says enter and exit use ease-out, and its escalation list names "ease-in on any UI". Both apply to every component, so the fix is in the token. Shared: yes (`qml/QsmShell/Style/Motion.qml`).
- **SC-3. Shadow as separation.** AGENTS says no shadow separates containers. This capsule uses a floating shadow (line 143 to 150) as its only separation from the application beneath it, which the ladder does not cover. Owner ruling needed.

Hypotheses (unmeasured, not in the defect list):

- **H1.** Band on dark application content: 1.04:1 computed (#271e30 against #1e1e1e). Separation then rests on the shadow. Needs a capture over a dark window.
- **H2.** The focus ring's neighbour is application content behind a 2 px gap. Its contrast is unmeasured and WCAG 1.4.11 asks for 3:1 against that neighbour.
- **H3.** The shadow may not draw outside the body. The layer MultiEffect (line 143 to 150) sets no `paddingRect`, and the installed Qt 6.12 headers expose it (`/usr/include/qt6/QtQuickEffects/6.12.0/QtQuickEffects/private/qquickmultieffect_p.h:37`). Whether a 24 px shadow is clipped without padding is unverified.
- **H4.** Role Button (line 57) wraps nested controls in the sound composition. The accessibility tree may nest interactive children under a button. Needs `qsm-uix a11y-tree`.
- **H5.** Return and Space from a nested text input may reach the root handlers (line 180 to 182) if the child does not accept the key. No text input is in the current compositions.
- **H6.** A disabled capsule keeps role Button and its name (line 57 and 58). Whether Qt reports the disabled state is unverified.

Not examined: every runtime state, pixel and contrast value, theme beyond the default token set, reduced-effects visuals, scale factors, screen-reader output, wheel, touch, the notification and OSD hosts at runtime.

Proposals (taste and redesign, no defect):

- **P1.** The sm composition in the unit uses 10 px (`textNear(7)` snaps to `typeXs` 10, `Style.qml` 272 to 274). That is the smallest step, a legibility call for ui-design. sm padding rounds 6 to 8 (`Style.qml` 284 to 286), leaving a 16 px slot.
- **P2.** Exit is 130 ms against an entry of 260 ms (line 115). review-animations standard 4 asks for about 80 percent of entry, roughly 208 ms. The verdict is review-animations'.
- **P3.** Escape to dismiss an interactive capsule. Focus currently holds the timer for as long as it stays (line 29). Owner decision.
- **P4.** Disable "Cancel timeout" (line 46) when no timer is armed.
- **P5.** The slot clips without elision (line 161 to 166). A long custom child is cut with no cue.
- **P6.** `accessibleName` defaults to "", so a consumer that omits it gets an unnamed Grouping. Default it to `actionLabel` or require it.
- **P7.** A constant radius of 28 gives sm a full pill (clamped to 16) and lg a rounded rectangle. AGENTS allows a constant radius; this is a taste call.
- **P8.** Hover pauses the timer for as long as the pointer rests on the capsule (line 29). Radix Toast does the same. Caelestia's OSD hide timer also defers while hovered (`modules/osd/Wrapper.qml` 84 to 89) but has no focus hold; the focus hold is this library's own addition.
