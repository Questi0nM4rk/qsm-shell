> Superseded component record; historical snapshot, not the current Rollout contract.

# Rollout

An edge reveal container that reports hover intent and stays open while the pointer is inside its hitbox plus a grace delay; it never closes itself.
states: revealed and hidden without reveal/retract overshoot; `suppressed` snaps shut; `hovered` is the pointer inside now and `keepOpen` adds the delay; `wantsOpen` combines trigger, hover and keep-open for the surface.
actions: none of its own; `triggered`, `hovered`, `keepOpen` and `wantsOpen` report upward and the surface owns `shouldBeActive`.
direction: `edges[0]` names the weld edge, therefore `left` opens left-to-right, `right` right-to-left, `top` top-to-bottom and `bottom` bottom-to-top. Extra adjacent edges square a corner; they do not add a second reveal axis.
placement: the owner positions `anchorItem` anywhere along the edge's free axis; Rollout centres on that item. `placementBounds` is the permitted host-space rectangle. With `nudgeToBounds: true` (default), only the free axis is clamped and `nudge` reports the exact correction; `false` preserves the anchor position even when it overflows. An interior floating surface is a Popover, not an edge Rollout.
open: a host sets `shouldBeActive` for a manual route, or binds `shouldBeActive: rollout.wantsOpen` for a hover route. `triggerAreas` opens while closed; `hoverAreas` holds the revealed body open, with the body itself as the default when the list is empty.
triggers: the library takes host-coordinate rectangles, so the host decides their visual form. A nudge rect rides the rollout's leading edge and stays visible as it opens; a capsule rect stays on the anchor item while its rollout opens beside it. Both use the same `triggerAreas` and `wantsOpen` route.
pointer: the `ShellBorder.pointer` must be a `ScenePointer` declared on the common ancestor; area rects are host coordinates. The component paints nothing and claims no events itself.
keyboard: none; it takes no keys and holds no focus.
screen reader: no role of its own; revealed content names itself.
size: the owner must supply `bodyWidth` and `bodyHeight`, including any padding; extrusion follows the declared edge. `anchorItem` centres the free axis on an item; `nudgeToBounds` clamps only that free axis to `placementBounds`, never across the weld edge.
modes: two explicit geometry contracts, chosen by one boolean. `borderExtrusion: false` (default) travels a full-size body under the fixed border, with free radii clamped to the full body. `borderExtrusion: true` opts into the accepted contour: the registered paint rect is the growing aperture, its free radii clamp to the CURRENT aperture half-extents, effective deformation is identity, and content sits at its full-size stationary HOST coordinates while the aperture grows. Opt-in is effective only while `_joined`, so a fullscreen-detached capsule keeps its existing geometry and its 5px compatibility offset untouched. Both modes share one origin mask, one blend/outness pair, one fill, one pass and one slot: no second rectangle, no new registry, no new uniform.
layers: `parentRollout` nests a child flush on the parent's free edge; a matching `childRollout` squares the parent's joining corners. A short child remains a separate T-junction; a child spanning the parent uses an exact parent seam but still melts into the frame. Shader rects retain the undeformed pivot; their origin tail stays part of the fill during deformation.
tokens: frameThickness, rolloutRadius, meltSmoothing, space2, space4 and radiusPill; no local colours or measurements.
motion: in the default travel mode, reveal and retract translate a full-size body under the fixed border; the shrinking clipping aperture is not the shader silhouette, free radii derive from body dimensions, and content/shader deformation share its translated centre. In border-extrusion mode the aperture grows into the same frame instead, radii follow the current aperture, and both the content transform and the shader's inverse/min-eigenvalue input are forced to identity so a matrix left by a prior travel cannot deform paint or content. Content settle scale is off by default; `animating` reports reveal and body-size morphs so a host can await settling. Goo is nearly critically damped and capped at 2%, and pauses under reduced motion; close delay is the hover grace.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| task/posture | A shell user finishes interacting and the auxiliary body retreats under its origin border | Owner rejects shrink-and-disappear closure | existing Rollout/offsetScale | owner reviews one desktop rollout |
| interaction | Full body translates; only the revealed aperture clips content and bounds input | A moving object keeps its identity/size | docs/12-mechanism reveal formulas | native silhouette/viewport facts through close |
| contour | `borderExtrusion` opts a caller into a growing aperture painted around stationary full-size content; unconverted callers keep full-body travel | The band should bulge, not carry a travelling slab | the same `registerBulge` slot, no second rectangle | owner accepted desktop OSD; left Network popout awaits review |
| hierarchy/system | Body radius and content size stay constant during reveal/retract; no default settle scaling | Changing corners/scale reads as collapse | Style.rolloutRadius, existing Motion curves | body dims/radii and mapped content transform |
| responsive/states | Apply same geometry to every edge and nested rollout, reversible close; suppression still snaps | One shared motion, not caller fixes | edges, parentRollout, suppressed | current item plus requested edge/reversal checks |
| polish | Preserve curves and capped goo, change no palette, token or public action | Root cause is geometry, not duration | Motion reveal/retract/deform tokens | owner judgement separate from native facts |
| polish/endpoint | Restore the incoming shader distance field with outness and gate only newly exposed stroke, not the fixed frame | Removing a hidden body must not relight the existing frame | existing outness, seamReach; docs/12-mechanism | requested live closing recording including settled tail |

Endpoint: attached travel parks the body's free edge exactly at the origin wall,
without overtravel. Effective goo reaches identity with outness, and zero-outness
shader slots contribute nothing before unregistering. Border restoration is not
a second animation; the original border remains the endpoint. The same rule
applies on all attached edges and nested seams; fullscreen-detached placement stays.
The border registry must preserve the full body on declared origin sides rather
than truncate it to the screen. Automatic snapping is only for other contacts;
otherwise shrinking shader dimensions with fixed free radii produces endpoint
recovery even when the Rollout's own translation is correct.

In border-extrusion mode the endpoint is reached by the same progress value and
the same terminal handoff, not by a second animation: outness falls to zero
before unregistering, so the incoming fill/rim field and lighting are preserved.
Scope of acceptance is deliberately narrow. The owner accepted the extruded
desktop OSD's appearance and behaviour on the live desktop. The first-level
left Network popout opts into the same mechanism for the next owner comparison;
its mode follows retained `renderKind` through retract, not the dismissed
controller's empty kind. Other rail entries and nested details keep travel mode.
The Network popout and other edges/nested cases are not owner-accepted; no
automated checks or exhaustive input-route verification are implied.
Reference comparison: Caelestia `modules/osd/Wrapper.qml`,
`modules/drawers/ContentWindow.qml`'s `osdBg` and
`modules/bar/popouts/ClipWrapper.qml` retain full content/background dimensions
while translating inside a clipped wrapper. Reuse that separation, not its
opacity fade, 5px overtravel or shader border sink; those conflict with the
owner's opaque body and stationary origin-wall requirement. Interaction,
hierarchy, sizing and accessibility are unchanged; this revision is endpoint
polish only and proposes no tokens.

Not designed: new pointer/keyboard/accessibility policy, size presets or shader
effects. Existing routes/states/sizes remain; no new tokens. The boundary and
terminal handoff are defined in `docs/12-mechanism.md#render-boundary-and-terminal-handoff`;
motion belongs to the full body, clipping/input to its exposed viewport. No audit
or runtime check is automatically authorized by this record.
expected: rectangular and named triangular areas use ScenePointer containment; an open descendant keeps its ancestor hovered without host geometry copies. One grace timer covers leaving and initial reveal outside all areas, stops on suppression/teardown, and reports `keepOpen` without dismissing. Callers supply the required `bodyWidth` and `bodyHeight`; they are not inferred from moving/clipped children. Keyboard retention is host policy. See ADR 0002 acceptance.
not designed: placement policy, the revealed content, and any local colour. Dismissal is NOT in this list: a consumer supplies AREAS and this component decides the keep-open verdict and the grace period. A consumer that re-derives the union of its own areas, its own close timer or its own pointer test is shipping a second implementation of a rule with one owner; it belongs in `docs/BACKLOG.md` as a component gap instead, and a corridor that needs a diagonal becomes a named area type here, never a second predicate in a scene. See ADR 0002.
