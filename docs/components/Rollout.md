# Rollout

An edge reveal container that reports hover intent and stays open while the pointer is inside its hitbox plus a grace delay; it never closes itself.
states: revealed and hidden with overshoot on the way out; `suppressed` snaps shut; `hovered` is the pointer inside now and `keepOpen` adds the delay; `wantsOpen` combines trigger, hover and keep-open for the surface.
actions: none of its own; `triggered`, `hovered`, `keepOpen` and `wantsOpen` report upward and the surface owns `shouldBeActive`.
direction: `edges[0]` names the weld edge, therefore `left` opens left-to-right, `right` right-to-left, `top` top-to-bottom and `bottom` bottom-to-top. Extra adjacent edges square a corner; they do not add a second reveal axis.
placement: the owner positions `anchorItem` anywhere along the edge's free axis; Rollout centres on that item. `placementBounds` is the permitted host-space rectangle. With `nudgeToBounds: true` (default), only the free axis is clamped and `nudge` reports the exact correction; `false` preserves the anchor position even when it overflows. An interior floating surface is a Popover, not an edge Rollout.
open: a host sets `shouldBeActive` for a manual route, or binds `shouldBeActive: rollout.wantsOpen` for a hover route. `triggerAreas` opens while closed; `hoverAreas` holds the revealed body open, with the body itself as the default when the list is empty.
triggers: the library takes host-coordinate rectangles, so the host decides their visual form. A nudge rect rides the rollout's leading edge and stays visible as it opens; a capsule rect stays on the anchor item while its rollout opens beside it. Both use the same `triggerAreas` and `wantsOpen` route.
pointer: the `ShellBorder.pointer` must be a `ScenePointer` declared on the common ancestor; area rects are host coordinates. The component paints nothing and claims no events itself.
keyboard: none; it takes no keys and holds no focus.
screen reader: no role of its own; revealed content names itself.
size: the body viewport plus padding on every side; extrusion follows the declared edge. `anchorItem` centres the free axis on an item; `nudgeToBounds` clamps only that free axis to `placementBounds`, never across the weld edge.
layers: `parentRollout` nests a child flush on the parent's free edge; a matching `childRollout` squares the parent's joining corners. A short child remains a separate T-junction; a child spanning the parent uses an exact, unblended seam.
tokens: frameThickness, rolloutRadius, meltSmoothing, space2, space4 and radiusPill; no local colours or measurements.
motion: reveal and retract curves on offset with a settle scale on content; the goo deform pauses under reduced motion; close delay is the hover grace.
not designed: placement policy, the revealed content, and any local colour. Dismissal is NOT in this list: a consumer supplies AREAS and this component decides the keep-open verdict and the grace period. A consumer that re-derives the union of its own areas, its own close timer or its own pointer test is shipping a second implementation of a rule with one owner; it belongs in `docs/BACKLOG.md` as a component gap instead, and a corridor that needs a diagonal becomes a named area type here, never a second predicate in a scene. See ADR 0002.
