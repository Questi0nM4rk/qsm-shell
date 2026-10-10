> Superseded travelling design. Historical material; use the active rollout-expansion design.

## Context

Rollout currently registers root.width/height as the shader bulge while its body
content translates at full size. Radius and deformation pivot also follow the
aperture. Desktop content retention corrected earlier did not address this layer.

## Goals / Non-Goals

Goal: shared full-size body retracts under its stationary origin border. Non-goals:
timing tweaks, new service/input policy, alternative desktop motion or shader rewrite.

## Decisions

Use existing body.x/y and full bodyWidth/Height for the undeformed shader rect,
mapped into host coordinates. Expose silhouette and viewport as actual geometry
facts; keep input registration on viewport. Clamp radii against full body size.
QML matrix, inverse shader and velocity sampler share the translated body centre.
Keep existing nested edge squaring/joins and detached fullscreen compatibility.
Settle-content remains an explicit compatibility option but defaults off; no
caller override is required for the corrected attached motion. The normative
docs/12-mechanism.md has been amended before code.

### Exact origin-wall endpoint

The owner rejects overtravel followed by late border recovery. Attached body
travel is exactly bodySize*slideScale, with no 5px parking allowance. Effective
deformation gates to identity with outness, using the same matrix for QML and
shader. Shader slots at outness zero are skipped before all fill/rim/stroke
merges; frame-join reach scales with outness and uses exact min at zero reach.
This changes the shader endpoint formula, so its .frag and generated .qsb must
be updated together. Shader compilation is an implementation artifact step,
not a test or visual acceptance. No new timers, easing or host-specific offsets.

### Preserve body geometry through registration

ShellBorder's automatic snap must not clip a declared origin side to the screen.
The origin mask already provides squared corners, weld caps and shader fill
continuation. Snap only non-origin contacts; retain the complete translated body
behind the origin band. Otherwise registration truncates a retracting 56px OSD
body toward the 16px band while retaining 28px free radii and changes the shader
pivot. Removing that malformed slot restores the frame as a visible snap back.
This registration correction leaves other edge contacts, nested seams and the
input viewport separate.

### Continuous paint endpoint

The reloaded recording confirms a 56px full body in the registry, but shows the
frame stroke disappearing and returning near closure. The old emergence mask
gated the existing frame boundary as well as the new body's edge. Restrict it
with smoothstep(0, seamReach, incomingSdf), where incomingSdf precedes the slot.
Compose the slot into a candidate distance field and mix from the incoming field
with outness; do the same for the exact-union rim. This preserves the entire
incoming field at zero, not just its contour: slot removal cannot change stroke
depth or lighting gradient. Fully-out and zero-blend nested composition keep
their existing formulas. No opacity fade, timing workaround or border sink.
Update the normative formulas first and compile only the changed shader artifact.

Caelestia's OSD wrapper and drawer osdBg keep full body dimensions separately from
the clipped wrapper. That separation informs this fix; its opacity fade, extra
parking travel and shader border sink do not match the owner's accepted contract.

## Risks / Trade-offs

Offscreen excursion must not be clamped or become an input region. Deformation
must not double-transform the registered rect. A close reversal keeps the same
body identity. All runtime/visual judgement remains owner opt-in; code does not
claim accepted motion merely because registry data is structurally correct.
