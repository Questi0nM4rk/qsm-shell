import QtQuick
import qs.QsmShell.Style

// THE rollout component (spec 02-rollouts): every edge surface reveals
// through this one mechanism; consumers only provide content, declared
// attached edge(s), and a size tier.
//
// The canonical value is `offsetScale` (0 = fully shown, 1 = fully hidden;
// 12-mechanism). It ALONE drives: position offset along every attached edge,
// whole-surface opacity (content rides fully drawn — nothing fades
// separately), the silhouette rect the host's shader sees (live and
// unclamped, including the off-screen excursion), and the input hit-rect
// (which activates only near-settled, past ~90% revealed; 09-input).
// A reveal reversed mid-flight retargets smoothly — the Behavior animates
// the one value from wherever it currently is.
//
// This component paints NOTHING. The body is the melt shader's fill
// (02-rollouts silhouette law: no backdrops, no chrome — content sits
// directly on the silhouette). Goo deform (phase 8) will feed the host's
// deform/param slots; until then the host holds them at identity.
Item {
    id: root

    default property alias content: inner.data

    // The host hosting this rollout — owner of both registries.
    required property var host
    // Registry key; unique per rollout within a host.
    required property string rolloutId
    // Window side(s) this rollout is flush with: one edge, or two ADJACENT
    // edges for a corner rollout. Anchor the item to the same sides.
    property var edges: ["top"]
    // Reveal intent. The one input consumers drive.
    property bool shouldBeActive: false
    // Fullscreen (09-input DEFAULT): surfaces hide INSTANTLY, no retract.
    property bool suppressed: false
    // "large" = 500ms tier (top panel, launcher, session, notifications);
    // "small" = 250ms tier (rail popouts, OSD, calendar). 02-rollouts.
    property string tier: "large"
    // Goo intensity (10-motion RATIFIED map: popouts 0.10, OSD 0.25,
    // notifications 0.15, top panel 0.10, launcher 0.10, session 0.20).
    property real deformScale: 0.1
    // A modal that owns a bigger catch region (launcher's full-scene
    // click-anywhere-closes) registers its OWN hit rect instead; the
    // silhouette bulge is always registered here regardless.
    property bool registerHitRect: true
    // The spawn border's inner wall, measured from the anchored screen edge:
    // the band the rollout spawns FROM (rail popouts: the 60px left band;
    // everything else: its 16px band). The rollout is a WINDOW at this wall
    // that grows outward while the content slides out of the band inside it
    // (caelestia's ClipWrapper mechanic — extrusion, never a rect placed
    // onto the border). bodyWidth/bodyHeight are the fully-shown size.
    property real edgeInset: Style.frameThickness
    // Corner rollouts attach to two bands of different depths.
    property real edgeInsetH: edgeInset
    property real edgeInsetV: edgeInset
    property real padding: 0
    property real bodyWidth: inner.childrenRect.width + padding * 2
    property real bodyHeight: inner.childrenRect.height + padding * 2
    // Allowlisted native-fullscreen surfaces use the same content but a
    // detached capsule geometry. Normal rollouts never consult these values.
    property bool fullscreenDetached: false
    property bool fullscreenCapsule: true
    property real fullscreenInset: Style.space4
    property real fullscreenRadius: Style.radiusPill
    // One shared content settle applies to every consumer by default. A
    // surface whose CONTENT animates its own entrance (the notification
    // stack's cards) opts out here, so the two never compose into a
    // double-pop on the first appearance.
    property bool settleContent: true

    // ── keep-open: the most ordinary thing on the web — a hover
    // area larger than the item, covering the approach corridors a pointer
    // sweeps through to reach it. While the pointer is anywhere in that
    // area the rollout stays open; once it leaves, a grace period runs
    // before the rollout may close ──
    //
    // Rects, in the HOST's coordinates, that keep this rollout open. A LIST
    // rather than one rect: a rail popout is covered by its anchor cell, the
    // band it grew from, its own card, and any open child card, and
    // unioning those is the CONSUMER's business, not a shape this library
    // should try to know. Empty means "my own silhouette" -- the honest
    // default for a rollout nobody has told anything else about.
    property var hoverAreas: []
    // How long `keepOpen` stays true after the pointer leaves every hover
    // area. See Motion.hoverGrace for why this does not shorten under
    // reduced motion.
    property int closeDelay: Motion.hoverGrace

    // Rects, in the HOST's coordinates, that OPEN this rollout -- the nub
    // bulging out of the frame, or the rail cell a pointer points at. Unlike
    // `hoverAreas`, empty means "no pointer trigger", never a fallback to the
    // rollout's own silhouette: the honest default for a rollout something
    // else opens (a keybind, a modal, an IPC call).
    property var triggerAreas: []

    // True while the pointer sits inside a trigger area right now. No delay
    // of any kind -- the same honesty rule that split `hovered` from
    // `keepOpen`. Deliberately NOT gated on `root.visible`: the whole point
    // of a trigger area is to be found by a pointer BEFORE anything shows.
    readonly property bool triggered: !!root.host && !!root.host.pointer
        && root.triggerAreas.length > 0
        && root.triggerAreas.some(area => root.host.pointer.contains(area))

    // True while the pointer sits inside a hover area right now. No delay of
    // any kind: false when there is no pointer, no host, or the rollout is
    // not showing. `triggerAreas` count here too -- the nub that opened the
    // rollout does not stop being part of it once the body reveals, and a
    // consumer forced to repeat the nub rect in `hoverAreas` would eventually
    // forget to. The own-silhouette fallback still only fires when
    // `hoverAreas` itself is empty.
    readonly property bool hovered: root.visible && !!root.host && !!root.host.pointer
        && [...root.triggerAreas, ...(root.hoverAreas.length > 0 ? root.hoverAreas
            : [Qt.rect(root.x, root.y, root.width, root.height)])]
            .some(area => root.host.pointer.contains(area))

    // The keep-open verdict a consumer reads: `hovered`, extended by
    // `closeDelay` after it drops. Kept separate from `hovered` on purpose --
    // a `hovered` that stayed true for `closeDelay` after the pointer left
    // would be a name that lies, and this library has already been bitten by
    // a name that said where a type was used rather than what it was. This
    // component only REPORTS — never `shouldBeActive = false` here. The
    // surface holding this rollout decides what `keepOpen` means; a
    // component that closed itself would be the exact law this library
    // breaks nowhere else.
    readonly property bool keepOpen: root.visible && (hovered || closeDelayTimer.running)

    // The verdict a surface binds `shouldBeActive` against: open because the
    // pointer is on the trigger right now (which works even while closed),
    // or open because `keepOpen` says so (which only ever applies once
    // already showing). This component still never assigns
    // `shouldBeActive` itself -- it only reports.
    readonly property bool wantsOpen: root.triggered || root.keepOpen

    Timer {
        id: closeDelayTimer
        interval: root.closeDelay
    }

    onHoveredChanged: {
        if (root.hovered || !root.visible)
            closeDelayTimer.stop();
        else
            closeDelayTimer.restart();
    }

    function attached(side: string): bool {
        return edges.includes(side);
    }

    // Per-corner radius for the silhouette (CSS border-radius order: tl, tr,
    // br, bl): rolloutRadius on free corners, 0 ONLY on the DECLARED
    // attached edge(s), CLAMPED to half the current size so a budding
    // window grows organically (caelestia clamps the same way).
    readonly property real clampedRadius: Math.max(0, Math.min(Style.rolloutRadius,
        width / 2, height / 2))
    readonly property vector4d cornerRadii: Qt.vector4d(
        (attached("top") || attached("left")) ? 0 : clampedRadius,
        (attached("top") || attached("right")) ? 0 : clampedRadius,
        (attached("bottom") || attached("right")) ? 0 : clampedRadius,
        (attached("bottom") || attached("left")) ? 0 : clampedRadius)

    // ── centring against the WHOLE shape ────────────────────────────────
    // A rollout is not a panel sitting next to the band; it is the band
    // BULGING. The shader melts the two into one silhouette, and a person
    // reads that silhouette as one object -- so content that centres itself
    // must centre in the whole object, band included, not in the body alone.
    //
    // The body's own centre sits half a band-depth away from the shape's, on
    // the side the rollout is attached to. Centring in the body therefore
    // pushes content half a band AWAY from the edge, every time, on every
    // rollout: the OSD's three sliders sat 8px left of the middle of the
    // shape they were drawn in, and the session column sat 8px left of its
    // own. Both had been "fixed" once by eye -- the OSD carried a bare `4`.
    //
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     anchors.horizontalCenterOffset: rollout.contentCenterOffsetX
    //
    // Only the attached axis is corrected: on the free axis the body and the
    // shape already share a centre.
    // Signed contributions from BOTH sides, not a ternary picking one. A
    // corner rollout attached to two opposite bands gets equal pulls that
    // cancel; a ternary would have shifted it half an inset toward whichever
    // side it happened to test first.
    //
    // Fullscreen is the other exception, and it is not academic: a detached
    // capsule has no band to be part of, so correcting toward one puts the
    // content half an inset off in exactly the mode where nothing anchors it.
    readonly property bool _joined: !(fullscreenDetached && host.fullscreen)
    readonly property real contentCenterOffsetX: !_joined ? 0
        : ((attached("right") ? edgeInsetH : 0) - (attached("left") ? edgeInsetH : 0)) / 2
    readonly property real contentCenterOffsetY: !_joined ? 0
        : ((attached("bottom") ? edgeInsetV : 0) - (attached("top") ? edgeInsetV : 0)) / 2

    // The reveal animates along ONE axis only — the FIRST declared edge's
    // axis (owner: a corner rollout scaling both axes reads as a popup
    // zoom, not a roll). A second attached edge only affects flushness and
    // corner squaring.
    readonly property bool revealHorizontal: edges.length > 0
        && (edges[0] === "left" || edges[0] === "right")

    // The WINDOW: full size on the free axis, growing from 0 to body along
    // the reveal axis as offsetScale falls.
    implicitWidth: revealHorizontal ? Math.max(0, bodyWidth * (1 - slideScale)) : bodyWidth
    implicitHeight: !revealHorizontal ? Math.max(0, bodyHeight * (1 - slideScale)) : bodyHeight
    width: fullscreenDetached && host.fullscreen ? bodyWidth : implicitWidth
    height: fullscreenDetached && host.fullscreen ? bodyHeight : implicitHeight
    clip: true

    // 12-mechanism reveal choreography, verbatim shape. No opacity binding:
    // content rides fully drawn and OPAQUE — the surface disappears by
    // sliding into the edge (02-rollouts no-opacity-ramp law). Visible until
    // the animation SETTLES, not until the value crosses 1: the overshoot
    // curve crosses 1 mid-retract, and cutting off there unregisters the
    // bulge while the band sink is still easing — the jitter law.
    property real offsetScale: (shouldBeActive && !suppressed) ? 0 : 1
    visible: revealAnim.running || offsetScale < 1
    // Back limit (02-rollouts): the curve overshoots past 0, but position
    // clamps at FLUSH — letting it cross detaches the attached edge from
    // the band and the melt eats the corner behind it (owner-caught).
    readonly property real slideScale: Math.max(0, offsetScale)
    // The window's attached edge sits FIXED at the spawn wall; only its
    // size changes (extrusion). Content inside slides toward/out of the
    // band, so the content's leading part emerges first — rolling out of
    // the border, never a rect placed onto it.
    anchors.topMargin: attached("top") ? edgeInsetV : 0
    anchors.bottomMargin: attached("bottom") ? edgeInsetV : 0
    anchors.leftMargin: attached("left") ? edgeInsetH : 0
    anchors.rightMargin: attached("right") ? edgeInsetH : 0

    Behavior on offsetScale {
        // Suppression must snap (no retract animation on fullscreen).
        enabled: !root.suppressed
        NumberAnimation {
            id: revealAnim
            duration: root.tier === "small" ? Motion.revealSmall : Motion.revealLarge
            easing.type: Easing.BezierSpline
            // Reveal decelerates hard, retract never overshoots (10-motion,
            // owner-amended: NO springs anywhere).
            easing.bezierCurve: (root.shouldBeActive && !root.suppressed)
                ? Motion.revealCurve : Motion.retractCurve
        }
    }

    // Size MORPH (10-motion popout glide, 250ms). A rollout that stays open
    // while its content changes — the panel switching tabs — must RESIZE; a
    // size that jumps reads as a second surface replacing the first. Gated on
    // being settled, because during the reveal the size IS the animation and a
    // second one fighting it produces exactly the jitter the back limit exists
    // to prevent.
    Behavior on bodyWidth {
        enabled: root.visible && root.offsetScale <= 0 && !revealAnim.running
        NumberAnimation {
            duration: Motion.morphGlide
            easing.type: Motion.emphasizedEasing
        }
    }

    Behavior on bodyHeight {
        enabled: root.visible && root.offsetScale <= 0 && !revealAnim.running
        NumberAnimation {
            duration: Motion.morphGlide
            easing.type: Motion.emphasizedEasing
        }
    }

    // Registry feed: silhouette rect while anything is visible (the live
    // rect, off-screen excursion included — the shader melts around the
    // moving rect every frame); hit rect only near-settled (09-input law).
    readonly property bool hitActive: registerHitRect && visible && offsetScale <= 0.1

    // Melt-blend factor: the neck's reach grows with the window's size, so
    // the join closes exactly as the window vanishes into the wall.
    readonly property real protrusion: revealHorizontal ? width : height
    readonly property real meltBlend: Math.max(0, Math.min(1, protrusion / Style.meltSmoothing))

    // --- Goo physics (12-mechanism): a symmetric 2x2 deform matrix
    // spring-driven by the rect's own scene-space velocity, applied to the
    // content transform AND handed to the shader (inverse + minEig) so
    // silhouette and content deform together. Reduced motion disables goo.
    property real dm00: 1
    property real dm01: 0
    property real dm11: 1
    // Non-notifying integrator state.
    property var goo: ({ v00: 0, v01: 0, v11: 0, px: 0, py: 0 })
    readonly property bool gooIdentity: dm00 === 1 && dm01 === 0 && dm11 === 1

    FrameAnimation {
        running: root.visible && !Style.reducedMotion && root.deformScale > 0
        onTriggered: root.stepGoo(frameTime)
    }

    function stepGoo(dt: real): void {
        const cx = x + width / 2;
        const cy = y + height / 2;
        const state = goo;
        // dt outside [0.001, 0.1]: skip INTEGRATION only; resample position
        // so the next frame's velocity is sane.
        if (!(dt >= 0.001 && dt <= 0.1)) {
            state.px = cx;
            state.py = cy;
            return;
        }

        const vx = (cx - state.px) / dt;
        const vy = (cy - state.py) / dt;
        state.px = cx;
        state.py = cy;
        const speed = Math.sqrt(vx * vx + vy * vy);

        let t00 = 1;
        let t01 = 0;
        let t11 = 1;
        if (speed > 5.0) {
            const stretch = 1 + Math.min((speed / 1000) * deformScale, 0.35);
            const compress = 1 / stretch;
            const c = vx / speed;
            const s = vy / speed;
            t00 = stretch * c * c + compress * s * s;
            t01 = (stretch - compress) * c * s;
            t11 = stretch * s * s + compress * c * c;
        }

        // Implicit damping — unconditionally stable at any dt.
        const stiffness = 200;
        const damping = 16;
        const invDamp = 1 / (1 + damping * dt);
        state.v00 = (state.v00 - stiffness * (dm00 - t00) * dt) * invDamp;
        state.v01 = (state.v01 - stiffness * (dm01 - t01) * dt) * invDamp;
        state.v11 = (state.v11 - stiffness * (dm11 - t11) * dt) * invDamp;
        let n00 = dm00 + state.v00 * dt;
        let n01 = dm01 + state.v01 * dt;
        let n11 = dm11 + state.v11 * dt;

        // Rest snap: kill the endless sub-pixel wobble.
        const nearRest = Math.abs(n00 - 1) < 0.002 && Math.abs(n01) < 0.002
            && Math.abs(n11 - 1) < 0.002;
        const slow = Math.abs(state.v00) < 0.05 && Math.abs(state.v01) < 0.05
            && Math.abs(state.v11) < 0.05;
        if (nearRest && slow && speed < 5.0) {
            n00 = 1;
            n01 = 0;
            n11 = 1;
            state.v00 = 0;
            state.v01 = 0;
            state.v11 = 0;
        }

        if (n00 !== dm00 || n01 !== dm01 || n11 !== dm11) {
            dm00 = n00;
            dm01 = n01;
            dm11 = n11;
            syncRegistries();
        }
    }

    // Content deform: translate(center) · M · translate(-center).
    transform: Matrix4x4 {
        matrix: {
            const cx = root.width / 2;
            const cy = root.height / 2;
            return Qt.matrix4x4(
                root.dm00, root.dm01, 0, cx - root.dm00 * cx - root.dm01 * cy,
                root.dm01, root.dm11, 0, cy - root.dm01 * cx - root.dm11 * cy,
                0, 0, 1, 0,
                0, 0, 0, 1);
        }
    }

    function syncRegistries() {
        if (!host)
            return;
        if (visible) {
            // CPU-precomputed inverse 2x2 (row-major) + min eigenvalue.
            const det = dm00 * dm11 - dm01 * dm01;
            const safeDet = Math.abs(det) < 0.0001 ? 0.0001 : det;
            const inverse = Qt.vector4d(dm11 / safeDet, -dm01 / safeDet,
                -dm01 / safeDet, dm00 / safeDet);
            const mean = (dm00 + dm11) / 2;
            const dev = Math.sqrt(((dm00 - dm11) / 2) ** 2 + dm01 * dm01);
            // Attached-edge bits (1 left, 2 right, 4 top, 8 bottom): the
            // shader extends the RIM copy of the rect through its band so
            // no rim seam draws where the rollout meets its border.
            const edgeBits = (attached("left") ? 1 : 0) + (attached("right") ? 2 : 0)
                + (attached("top") ? 4 : 0) + (attached("bottom") ? 8 : 0);
            // outness is the same ratio here: a Rollout's melt and its
            // emergence are one number. They are separate arguments because a
            // nested host sets blend to 0 for an exact union while being fully
            // out (BarPopouts.flushToParent).
            host.registerBulge(rolloutId, Qt.rect(x, y, width, height), cornerRadii,
                meltBlend, inverse, mean - dev, edgeBits, 0, false, meltBlend);
            if (fullscreenDetached && host.fullscreen && fullscreenCapsule)
                host.registerFullscreenCapsule(rolloutId,
                    Qt.rect(x, y, width, height), fullscreenRadius);
            else
                host.unregisterFullscreenCapsule(rolloutId);
        } else {
            host.unregisterBulge(rolloutId);
            host.unregisterFullscreenCapsule(rolloutId);
        }
        if (hitActive)
            host.registerRolloutRegion(rolloutId, Qt.rect(x, y, width, height));
        else
            host.unregisterRolloutRegion(rolloutId);
    }

    onXChanged: syncRegistries()
    onYChanged: syncRegistries()
    onWidthChanged: syncRegistries()
    onHeightChanged: syncRegistries()
    onVisibleChanged: syncRegistries()
    onHitActiveChanged: syncRegistries()
    onFullscreenDetachedChanged: syncRegistries()
    onFullscreenCapsuleChanged: syncRegistries()

    Connections {
        target: root.host
        function onFullscreenChanged() { root.syncRegistries(); }
    }

    Component.onDestruction: {
        if (host) {
            host.unregisterBulge(rolloutId);
            host.unregisterRolloutRegion(rolloutId);
            host.unregisterFullscreenCapsule(rolloutId);
        }
    }

    Component.onCompleted: {
        // 1..3 edges: edges[0] names the REVEAL axis; the rest are flush
        // contacts (squared corners + rim burial). An opposite pair is only
        // legal on the CROSS axis (a full-extent column/strip).
        const valid = ["bottom", "top", "left", "right"];
        const opposedOnReveal = revealHorizontal
            ? (attached("left") && attached("right"))
            : (attached("top") && attached("bottom"));
        const bad = edges.length < 1 || edges.length > 3
            || edges.some(side => !valid.includes(side))
            || opposedOnReveal;
        if (bad)
            console.warn("Rollout: invalid edges", JSON.stringify(edges));
        syncRegistries();
    }

    // Content viewport (caelestia's ClipWrapper): the body-sized content
    // slides toward the wall as the window shrinks, so its LEADING part
    // emerges first on reveal and disappears last on retract.
    Item {
        id: body
        width: root.bodyWidth
        height: root.bodyHeight
        // Content slides only along the REVEAL axis; a second attached edge
        // just pins alignment.
        x: !root.revealHorizontal ? 0
            : root.attached("left") ? -(root.bodyWidth + 5) * root.slideScale
            : root.width - root.bodyWidth + (root.bodyWidth + 5) * root.slideScale
        y: root.revealHorizontal ? 0
            : root.attached("top") ? -(root.bodyHeight + 5) * root.slideScale
            : root.height - root.bodyHeight + (root.bodyHeight + 5) * root.slideScale

        Item {
            id: inner
            x: root.padding
            y: root.padding
            width: root.bodyWidth - root.padding * 2
            height: root.bodyHeight - root.padding * 2
            // One shared content settle for every rollout consumer. Geometry,
            // edge attachment, clipping, and the handle still come solely from
            // the canonical extrusion above; this only adds the small visual
            // settle once content has emerged. Consumers whose content owns
            // its own entrance set settleContent false and stay at full scale.
            scale: !root.settleContent ? 1
                : (root.shouldBeActive && !root.suppressed ? 1 : Motion.microPopScale)
            transformOrigin: Item.Center

            Behavior on scale {
                enabled: !root.suppressed
                NumberAnimation { duration: Motion.microPopDuration; easing.type: Motion.emphasizedEasing }
            }
        }
    }
}
