# DataCapsule

An auxiliary data container for a quick reading without leaving the application.
It is not the Capsule button or a Rollout: no edge joins, translation, deformation,
services or window policy. The desktop hosts it above fullscreen when appropriate.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture/task | Glance at a reading; optionally open its owning view | Quiet Luminous; application remains primary | auxiliary, non-modal | fullscreen host and click outcome |
| ia | Caller content in one clipped slot; fixed cross-axis size and preferred length, either orientation | Host owns the infoblock, long content must not grow the capsule | `Style.size("DataCapsule", size)`, `Style.controlWidth` | horizontal/vertical, small/large and explicit host sizing |
| interaction | Host owns `shown`; `timeout <= 0` is persistent; positive timeout requests dismissal once | AGENTS host-owned state; Radix Toast controlled visibility and pause pattern | `timeoutRequested`, `restart`, `reset` | real timer, reset and repeated presentation |
| interaction | `hoverStay` pauses the remaining timeout; focus always holds it | Pointer and keyboard users must finish interacting | ancestor HoverHandler, content FocusScope | nested control hover/focus and resume |
| hierarchy/token | Border material, no rim or passive accent; optional whole-body action; diffuse shadow outside body | Owner's requested same material as Rollout/border, levitating rather than edge-joined | `Surface`, `Style.bandFill`, `Style.rolloutRadius`, floating-shadow roles | resting/hover/pressed/focus/disabled states |
| responsive | Host sets position/anchors at any screen edge and actual footprint; component sizes its body, never a screen | Screen placement and infoblock sizes are host decisions | `orientation`, `size`, `bodySize`, `preferredLength`, `sizeScale`, `padding` | compact and larger content hosts |
| responsive | Centre the complete content group inside the padded slot; sound composition fits its natural group instead of reserving an unrelated long strip | Owner rejected off-centre and overflowing capsule content | caller layout, `contentItem`, `Style.rhythm`, shared padding | live sound, OSD and notification bodies include their complete content envelope |
| responsive | Orientation chooses the composition, not the text's rotation: horizontal content is a centred text group; vertical content is a glyph with its reading | A wide text composition in a narrow column leaves nothing legible in the clip | caller layout, `contentItem`, `Style.textNear`/`iconNear`/`rhythm`, `sizeScale`, reactive `TextMetrics` | horizontal and vertical at sm/md/lg with short, default and long length; widths round up, then stay slot-bounded and elide |
| state | Empty remains an empty slot; loading/error/readings belong to content; `interactive: false` remains legible | Report-only is not unavailable | `interactive`, `enabled`, Accessible grouping/button | passive, unavailable and nested action routes |
| polish | Opacity only, reversible fade, no growth or positional animation | Owner request; blueprint purposeful motion | `Motion.medium`, `Motion.micro`, enter/exit easing | fade reversal and reduced motion |

`activate()` emits `activated` only when shown, enabled and interactive. Pointer,
Return, Enter, Space and the exposed action share it. Nested controls keep their
own action; the empty body is the whole-capsule action. `reset()` cancels pending
timeout work without changing host visibility; `restart()` refreshes its budget.
`pointerHovered`, `keepOpen`, `present`, `acceptsInput` and `remainingTime()` expose facts
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
level independent of mute, and a level write unmutes as in the desktop service.
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
