import QtQuick
import qs.QsmShell.Style

// Full-size content and a source-attached clip aperture are separate geometries.
// ShellBorder paints their contour; this item owns placement and reports intent.
Item {
    id: root

    default property alias content: inner.data
    readonly property alias contentItem: inner

    // The host hosting this rollout — owner of both registries.
    required property var host
    // Registry key; unique per rollout within a host.
    required property string rolloutId
    // Window side(s) this rollout is flush with: one edge, or two ADJACENT
    // edges for a corner rollout. Anchor the item to the same sides.
    property var edges: ["top"]
    // An item on the attached band that determines the rollout's free-axis
    // centre. The declared edge remains the weld edge; an anchor never turns a
    // left-band rollout into a right-band rollout.
    property Item anchorItem: null
    // The host-space area an anchored rollout may occupy. Nudge only corrects
    // the free axis: moving across the weld edge would detach the silhouette
    // from the band it emerged from.
    property rect placementBounds: Qt.rect(0, 0, host ? host.width : 0, host ? host.height : 0)
    property bool nudgeToBounds: true
    // A nested rollout welds its declared edge to the free edge of its parent.
    // The parent names the child too, because only it can square the corners
    // that disappear under a full-span child.
    property var parentRollout: null
    property var childRollout: null
    // Reveal intent. The one input consumers drive. A child rollout that is
    // still painted keeps this source revealed through its own `childRollout`
    // link, NOT by being folded in here: intent that outlives its meaning
    // cannot be told apart from intent that is still open.
    property bool shouldBeActive: false
    // While the host is fullscreen the surface hides INSTANTLY, no retract.
    property bool suppressed: false
    // A rollout reached by a key, or seen a hundred times a day, takes no
    // motion in the direction named: the aperture jumps to its target in one
    // frame. Each direction is its own fact, because a surface may appear at
    // once and still leave at the pace of its timer.
    property bool instantReveal: false
    property bool instantRetract: false
    // The reveal tier: "large" for a big panel or a modal, "small" for a
    // popout or a readout. Motion owns each tier's duration.
    property string tier: "large"
    // A modal that owns a bigger catch region (a full-scene click-anywhere-
    // closes) registers its OWN hit rect instead; the silhouette bulge is
    // always registered here regardless.
    property bool registerHitRect: true
    // Negative means automatic; nonnegative overrides apply to both axes.
    property real edgeInset: -1
    property real edgeInsetH: edgeInset >= 0 ? edgeInset
        : attached("left") ? (host?.leftEdge ?? host?.edge ?? Style.frameThickness)
        : (host?.edge ?? Style.frameThickness)
    property real edgeInsetV: edgeInset >= 0 ? edgeInset
        : (host?.edge ?? Style.frameThickness)
    property real padding: 0
    required property real bodyWidth
    required property real bodyHeight
    // Allowlisted native-fullscreen surfaces use the same content but a
    // detached capsule geometry. Normal rollouts never consult these values.
    property bool fullscreenDetached: false
    property bool fullscreenCapsule: true
    property real fullscreenInset: Style.rolloutPadding
    property real fullscreenRadius: Style.radiusPill
    // Scales the speed-driven stretch of a detached presentation; attached
    // content never travels or deforms.
    property real deformScale: Motion.rolloutDeformScale
    property bool settleContent: false
    // Animated child extents already provide the size transition.
    property bool animateBodySize: true

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
    readonly property var pointer: root.host?.pointer ?? null
    readonly property bool triggered: !!root.pointer
        && root.triggerAreas.length > 0
        && root.triggerAreas.some(area => root.pointer.contains(area))

    // True while the pointer sits inside a hover area right now. No delay of
    // any kind: false when there is no pointer, no host, or the rollout is
    // not showing. `triggerAreas` count here too -- the nub that opened the
    // rollout does not stop being part of it once the body reveals, and a
    // consumer forced to repeat the nub rect in `hoverAreas` would eventually
    // forget to. The own-silhouette fallback still only fires when
    // `hoverAreas` itself is empty.
    readonly property bool hovered: root.visible && (!!root.pointer &&
        [...root.triggerAreas, ...(root.hoverAreas.length > 0 ? root.hoverAreas
            : [root.rectInHost(0, 0, root.width, root.height)])]
            .some(area => root.pointer.contains(area)) || root._childHovered)
    readonly property bool _childHovered: childRollout?.visible === true
        && childRollout.parentRollout === root && childRollout.hovered

    // The keep-open verdict a consumer reads: `hovered`, extended by
    // `closeDelay` after it drops. Kept separate from `hovered` on purpose --
    // a `hovered` that stayed true for `closeDelay` after the pointer left
    // would be a name that lies. This component only REPORTS — never
    // `shouldBeActive = false` here. The surface holding this rollout decides
    // what `keepOpen` means.
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

    onVisibleChanged: {
        syncRegistries()
        if (!visible)
            closeDelayTimer.stop()
        else if (!hovered)
            closeDelayTimer.restart()
    }
    onSuppressedChanged: {
        if (suppressed) {
            closeDelayTimer.stop()
            widthMorph.complete()
            heightMorph.complete()
        }
        syncRegistries()
    }
    onPointerChanged: {
        if (!pointer || !pointer.inside)
            closeDelayTimer.stop()
    }

    onHoveredChanged: {
        if (root.hovered || !root.visible || root.suppressed)
            closeDelayTimer.stop();
        else
            closeDelayTimer.restart();
    }

    function attached(side: string): bool {
        return edges.includes(side);
    }

    readonly property bool _anchored: anchorItem !== null || parentRollout !== null
    readonly property rect _parentRect: parentRollout
        ? (_joined ? parentRollout.settledBodyRect
            : parentRollout.rectInHost(0, 0, parentRollout.width, parentRollout.height))
        : Qt.rect(0, 0, 0, 0)
    readonly property rect _placementArea: parentRollout ? _parentRect : placementBounds
    readonly property rect _anchorRect: anchorItem && host && typeof host.mapFromItem === "function"
        ? (() => {
            // mapFromItem does not notify when its source moves after loading.
            anchorItem.x;
            anchorItem.y;
            const point = host.mapFromItem(anchorItem, 0, 0);
            return Qt.rect(point.x, point.y, anchorItem.width, anchorItem.height);
        })()
        : _parentRect
    // The anchor in host coordinates is the one rect a host needs to keep a
    // capsule trigger live alongside the revealed body.
    readonly property rect anchorRect: _anchorRect
    readonly property real _anchorCenterX: _anchorRect.x + _anchorRect.width / 2
    readonly property real _anchorCenterY: _anchorRect.y + _anchorRect.height / 2

    // Half the body's height, held once the card is open on its anchor. A side
    // card is centred on its anchor once; a list that grows or shrinks
    // afterwards (a row expands, an inline submenu opens) then grows from a
    // fixed top instead of re-centring, which would move the row the pointer
    // just clicked. The anchor still carries the card when it moves, because
    // only the half-height is held.
    //
    // The hold starts when the reveal is near-settled, never earlier: a host
    // that swaps content on open (the rail's popouts) states its size only
    // after the reveal begins, so a hold taken while hidden or at its first
    // frame centres the card on a stale height. A different anchor is a new
    // placement: the half follows the body through its size morph, then holds.
    property real _pinHalf: 0
    property bool _pinned: false
    Binding {
        target: root
        property: "_pinHalf"
        value: root.bodyHeight / 2
        when: !root._pinned
        restoreMode: Binding.RestoreNone
    }
    function _hold(): void {
        if (_inputReady && !heightMorph.running)
            _pinned = true;
    }
    on_InputReadyChanged: {
        if (_inputReady)
            _hold();
        else
            _pinned = false;
    }
    onAnchorItemChanged: _pinned = false
    // Deferred: a morph re-targeted by a faster pointer stops and restarts
    // within one turn, and only a morph that stayed stopped is finished.
    Connections {
        target: heightMorph
        function onRunningChanged() { Qt.callLater(() => root._hold()); }
    }

    function _clampCross(value: real, span: real, start: real, length: real): real {
        return Math.max(start, Math.min(start + Math.max(0, length - span), value));
    }

    // The unnudged rect is observable so a host can decide whether a displaced
    // item deserves a different treatment. The nudge itself is never guessed
    // from pixels: it is the exact difference between ideal and placed origin.
    readonly property real _rawPlacementX: revealHorizontal
        ? (parentRollout
            ? (attached("left") ? _parentRect.x + _parentRect.width : _parentRect.x - width)
            : (attached("left") ? placementBounds.x + edgeInsetH : placementBounds.x + placementBounds.width - edgeInsetH - width))
        : _anchorCenterX - width / 2
    readonly property real _rawPlacementY: revealHorizontal
        ? _anchorCenterY - _pinHalf
        : (parentRollout
            ? (attached("top") ? _parentRect.y + _parentRect.height : _parentRect.y - height)
            : (attached("top") ? placementBounds.y + edgeInsetV : placementBounds.y + placementBounds.height - edgeInsetV - height))
    readonly property real _placementX: revealHorizontal || !nudgeToBounds
        ? _rawPlacementX
        : _clampCross(_rawPlacementX, width, _placementArea.x, _placementArea.width)
    readonly property real _placementY: !revealHorizontal || !nudgeToBounds
        ? _rawPlacementY
        : _clampCross(_rawPlacementY, height, _placementArea.y, _placementArea.height)
    readonly property point nudge: Qt.point(_placementX - _rawPlacementX, _placementY - _rawPlacementY)
    // Placement is computed in host space even when the item's QML parent is
    // a translated scene container. Keep the semantic source separate from it.
    readonly property point _placementInParent: host && parent
        && typeof host.mapFromItem === "function"
        && typeof parent.mapFromItem === "function"
        ? parent.mapFromItem(host, _placementX, _placementY)
        : Qt.point(_placementX, _placementY)

    Binding {
        target: root
        property: "x"
        value: root._placementInParent.x
        when: root._anchored
    }
    Binding {
        target: root
        property: "y"
        value: root._placementInParent.y
        when: root._anchored
    }

    // Per-corner radius for the silhouette (CSS border-radius order: tl, tr,
    // br, bl): rolloutRadius on free corners, 0 ONLY on the DECLARED
    // attached edge(s), CLAMPED to half the current size so a budding
    // window grows organically (caelestia clamps the same way).
    // Attached paint is the aperture; detached paint retains its full body.
    readonly property real clampedRadius: Math.max(0, Math.min(Style.rolloutRadius,
        (_joined ? viewportRect.width : body.width) / 2,
        (_joined ? viewportRect.height : body.height) / 2))
    readonly property bool _childSpansCross: childRollout?.visible === true
        && childRollout.parentRollout === root
        && (revealHorizontal
            ? childRollout.height >= height - Style.space1
            : childRollout.width >= width - Style.space1)
    function _coveredByChild(side: string): bool {
        return _childSpansCross
            && ((side === "left" && childRollout.attached("right"))
                || (side === "right" && childRollout.attached("left"))
                || (side === "top" && childRollout.attached("bottom"))
                || (side === "bottom" && childRollout.attached("top")));
    }
    readonly property bool flushToParent: parentRollout !== null
        && (revealHorizontal
            ? height >= _parentRect.height - Style.space1
            : width >= _parentRect.width - Style.space1)
    readonly property int _childSeamBits: _coveredByChild("left") ? 1
        : _coveredByChild("right") ? 2
        : _coveredByChild("top") ? 4
        : _coveredByChild("bottom") ? 8 : 0
    readonly property vector4d cornerRadii: Qt.vector4d(
        (attached("top") || attached("left") || _coveredByChild("top") || _coveredByChild("left")) ? 0 : clampedRadius,
        (attached("top") || attached("right") || _coveredByChild("top") || _coveredByChild("right")) ? 0 : clampedRadius,
        (attached("bottom") || attached("right") || _coveredByChild("bottom") || _coveredByChild("right")) ? 0 : clampedRadius,
        (attached("bottom") || attached("left") || _coveredByChild("bottom") || _coveredByChild("left")) ? 0 : clampedRadius)

    // Optional centring in the body-plus-band shape pulls content half a band
    // toward each contact. Detached capsules and nested expansions have no
    // source frame band to include in their content centre.
    readonly property bool _joined: !(fullscreenDetached && host.fullscreen)
    readonly property real contentCenterOffsetX: !_joined || parentRollout !== null ? 0
        : ((attached("right") ? edgeInsetH : 0) - (attached("left") ? edgeInsetH : 0)) / 2
    readonly property real contentCenterOffsetY: !_joined || parentRollout !== null ? 0
        : ((attached("bottom") ? edgeInsetV : 0) - (attached("top") ? edgeInsetV : 0)) / 2

    // Consumers describe trigger/hover areas in host coordinates. Keep the
    // fallback silhouette and registry rects in that same space when a
    // rollout is nested below another item.
    function rectInHost(localX: real, localY: real, width: real, height: real): rect {
        if (root.host && typeof root.host.mapFromItem === "function") {
            const point = root.parent
                ? root.host.mapFromItem(root.parent, root.x + localX, root.y + localY)
                : Qt.point(root.x + localX, root.y + localY);
            return Qt.rect(point.x, point.y, width, height);
        }
        return Qt.rect(root.x + localX, root.y + localY, width, height);
    }

    // One attached aperture feeds paint and input before paint-only welds.
    readonly property rect silhouetteRect: _joined ? viewportRect
        : rectInHost(body.x, body.y, body.width, body.height)
    readonly property rect viewportRect: rectInHost(0, 0, width, height)
    // The source's final edge must not drift with its animated aperture. Use
    // the parked body position rather than its current aperture.
    readonly property rect settledBodyRect: rectInHost(
        revealHorizontal && attached("right") ? width - bodyWidth : 0,
        !revealHorizontal && attached("bottom") ? height - bodyHeight : 0,
        bodyWidth, bodyHeight)

    // The reveal animates along ONE axis only — the FIRST declared edge's
    // axis: a corner rollout scaling both axes reads as a popup zoom, not a
    // roll. A second attached edge only affects flushness and corner
    // squaring.
    readonly property bool revealHorizontal: edges.length > 0
        && (edges[0] === "left" || edges[0] === "right")

    // The WINDOW: full size on the free axis, growing from 0 to body along
    // the reveal axis as progress grows.
    implicitWidth: revealHorizontal ? Math.max(0, bodyWidth * revealProgress) : bodyWidth
    implicitHeight: !revealHorizontal ? Math.max(0, bodyHeight * revealProgress) : bodyHeight
    width: fullscreenDetached && host.fullscreen ? bodyWidth : implicitWidth
    height: fullscreenDetached && host.fullscreen ? bodyHeight : implicitHeight
    clip: true

    // Retain the picture through retract; input follows semantic intent instead.
    //
    // A child that is still painted is a REASON to keep this source revealed,
    // and never this rollout's own intent: the child owns its own retract, so
    // until it finishes this source is held, not open, and it retracts the
    // instant that child hides.
    readonly property bool _sourceRetained: !shouldBeActive && !suppressed
        && childRollout?.visible === true

    // 0 shown, 1 hidden. It is moved by `_moveOffset`, not by a Behavior: a
    // Behavior copies the animation's easing when the value changes, and that
    // is before a curve bound to the same intent has switched direction, so a
    // retract ran the whole way on the reveal curve and was over in 100 ms.
    property real offsetScale: 1
    readonly property real _offsetTarget: ((shouldBeActive || _sourceRetained) && !suppressed) ? 0 : 1
    property bool _ready: false
    on_OffsetTargetChanged: {
        if (_ready)
            _moveOffset();
    }
    function _moveOffset(): void {
        revealAnim.stop();
        const revealing = _offsetTarget === 0;
        if (suppressed || (revealing ? instantReveal : instantRetract)) {
            offsetScale = _offsetTarget;
            return;
        }
        const entry = tier === "small" ? Motion.revealSmall : Motion.revealLarge;
        revealAnim.from = offsetScale;
        revealAnim.to = _offsetTarget;
        revealAnim.duration = revealing ? entry : Motion.exit(entry);
        // Reveal decelerates hard, retract never overshoots: no springs.
        revealAnim.easing.bezierCurve = revealing ? Motion.revealCurve : Motion.retractCurve;
        revealAnim.start();
    }
    // At rest means the motion is finished AND nothing is holding this source
    // open for a child. Reporting a retained source as settled tells a host
    // that is waiting for the retract that the picture it sees is finished.
    readonly property bool animating: revealAnim.running || widthMorph.running
        || heightMorph.running || _sourceRetained
    visible: !suppressed && (revealAnim.running || offsetScale < 1)
    // Even a custom offset must never grow past the flush body extent.
    readonly property real _detachedTravel: _joined ? 0 : Math.max(0, offsetScale)
    readonly property real revealProgress: Math.max(0, Math.min(1, 1 - offsetScale))
    // Anchor-item placement and explicit QML anchors share the same
    // source wall; only the aperture depth changes with reveal.
    anchors.topMargin: attached("top") ? edgeInsetV : 0
    anchors.bottomMargin: attached("bottom") ? edgeInsetV : 0
    anchors.leftMargin: attached("left") ? edgeInsetH : 0
    anchors.rightMargin: attached("right") ? edgeInsetH : 0

    NumberAnimation {
        id: revealAnim
        target: root
        property: "offsetScale"
        easing.type: Easing.BezierSpline
    }

    // Size MORPH (10-motion popout glide, 250ms). A rollout that stays open
    // while its content changes — the panel switching tabs — must RESIZE; a
    // size that jumps reads as a second surface replacing the first. Gated on
    // being settled, because during the reveal the size IS the animation and a
    // second one fighting it produces exactly the jitter the back limit exists
    // to prevent.
    Behavior on bodyWidth {
        enabled: root.animateBodySize && root.visible && root.offsetScale <= 0 && !revealAnim.running
        NumberAnimation {
            id: widthMorph
            duration: Motion.morphGlide
            easing.type: Motion.emphasizedEasing
        }
    }

    Behavior on bodyHeight {
        enabled: root.animateBodySize && root.visible && root.offsetScale <= 0 && !revealAnim.running
        NumberAnimation {
            id: heightMorph
            duration: Motion.morphGlide
            easing.type: Motion.emphasizedEasing
        }
    }

    // Paint survives retract; input is only the near-settled active aperture.
    // The content slot and the hit region share this one predicate, so nothing
    // clipped out of view can take a key or a click while the reveal runs.
    readonly property bool _inputReady: shouldBeActive && !suppressed && revealProgress >= 0.9
    readonly property bool hitActive: registerHitRect && _inputReady && visible

    // Melt-blend factor: the neck's reach grows with the window's size, so
    // the join closes exactly as the window vanishes into the wall.
    readonly property real protrusion: revealHorizontal ? width : height
    readonly property real meltBlend: Math.max(0, Math.min(1, protrusion / Style.meltSmoothing))
    // A detached integrator's stale state cannot affect attached paint/content.
    readonly property real effectiveDm00: _joined ? 1 : 1 + meltBlend * (dm00 - 1)
    readonly property real effectiveDm01: _joined ? 0 : meltBlend * dm01
    readonly property real effectiveDm11: _joined ? 1 : 1 + meltBlend * (dm11 - 1)
    readonly property vector3d effectiveDeform: Qt.vector3d(effectiveDm00, effectiveDm01, effectiveDm11)

    // Detached compatibility only: a symmetric 2x2 deform matrix
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
            && !root._joined
        onTriggered: root.stepGoo(frameTime)
    }

    function stepGoo(dt: real): void {
        const cx = x + body.x + body.width / 2;
        const cy = y + body.y + body.height / 2;
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
            const stretch = 1 + Math.min((speed / 1000) * deformScale, Motion.rolloutDeformLimit);
            const compress = 1 / stretch;
            const c = vx / speed;
            const s = vy / speed;
            t00 = stretch * c * c + compress * s * s;
            t01 = (stretch - compress) * c * s;
            t11 = stretch * s * s + compress * c * c;
        }

        // Implicit damping — unconditionally stable at any dt.
        const stiffness = Motion.rolloutDeformStiffness;
        const damping = Motion.rolloutDeformDamping;
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
            const cx = body.x + body.width / 2;
            const cy = body.y + body.height / 2;
            return Qt.matrix4x4(
                root.effectiveDm00, root.effectiveDm01, 0,
                    cx - root.effectiveDm00 * cx - root.effectiveDm01 * cy,
                root.effectiveDm01, root.effectiveDm11, 0,
                    cy - root.effectiveDm01 * cx - root.effectiveDm11 * cy,
                0, 0, 1, 0,
                0, 0, 0, 1);
        }
    }

    function syncRegistries() {
        if (!host)
            return;
        const sceneRect = silhouetteRect;
        if (visible && !suppressed) {
            // CPU-precomputed inverse 2x2 (row-major) + min eigenvalue.
            const det = effectiveDm00 * effectiveDm11 - effectiveDm01 * effectiveDm01;
            const safeDet = Math.abs(det) < 0.0001 ? 0.0001 : det;
            const inverse = Qt.vector4d(effectiveDm11 / safeDet, -effectiveDm01 / safeDet,
                -effectiveDm01 / safeDet, effectiveDm00 / safeDet);
            const mean = (effectiveDm00 + effectiveDm11) / 2;
            const dev = Math.sqrt(((effectiveDm00 - effectiveDm11) / 2) ** 2
                + effectiveDm01 * effectiveDm01);
            // Origin sides extend fill through the source; child-facing
            // continuations only overlap the seam (12-mechanism).
            const edgeBits = (attached("left") ? 1 : 0) + (attached("right") ? 2 : 0)
                + (attached("top") ? 4 : 0) + (attached("bottom") ? 8 : 0);
            // outness is the same ratio here: a Rollout's melt and its
            // emergence are one number. They are separate arguments because a
            // nested host sets blend to 0 for an exact union while being fully
            // out (`flushToParent`).
            host.registerBulge(rolloutId, sceneRect, cornerRadii,
                flushToParent ? 0 : meltBlend, inverse, mean - dev, edgeBits, _childSeamBits,
                false, meltBlend);
            if (fullscreenDetached && host.fullscreen && fullscreenCapsule)
                host.registerFullscreenCapsule(rolloutId,
                    viewportRect, fullscreenRadius);
            else
                host.unregisterFullscreenCapsule(rolloutId);
        } else {
            host.unregisterBulge(rolloutId);
            host.unregisterFullscreenCapsule(rolloutId);
        }
        if (hitActive)
            host.registerRolloutRegion(rolloutId, viewportRect);
        else
            host.unregisterRolloutRegion(rolloutId);
    }

    onXChanged: syncRegistries()
    onYChanged: syncRegistries()
    onWidthChanged: syncRegistries()
    onHeightChanged: syncRegistries()
    onHitActiveChanged: syncRegistries()
    onFullscreenDetachedChanged: syncRegistries()
    onFullscreenCapsuleChanged: syncRegistries()
    onChildRolloutChanged: syncRegistries()
    onSilhouetteRectChanged: syncRegistries()
    onViewportRectChanged: syncRegistries()
    onCornerRadiiChanged: syncRegistries()
    onMeltBlendChanged: syncRegistries()
    onEffectiveDeformChanged: syncRegistries()
    onFlushToParentChanged: syncRegistries()
    on_ChildSeamBitsChanged: syncRegistries()

    Connections {
        target: body
        function onXChanged() { root.syncRegistries(); }
        function onYChanged() { root.syncRegistries(); }
        function onWidthChanged() { root.syncRegistries(); }
        function onHeightChanged() { root.syncRegistries(); }
    }

    Connections {
        target: root.childRollout
        function onVisibleChanged() { root.syncRegistries(); }
        function onWidthChanged() { root.syncRegistries(); }
        function onHeightChanged() { root.syncRegistries(); }
        function onParentRolloutChanged() { root.syncRegistries(); }
    }

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
        offsetScale = _offsetTarget;
        _ready = true;
        if (visible && !hovered && !suppressed)
            closeDelayTimer.restart();
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

    // Full-size attached content stays at its final HOST coordinate while the
    // aperture grows. Right/bottom local offsets cancel the moving clip origin:
    //   right:  hostX = (wall - root.width) + (root.width - bodyWidth)
    //                 = wall - bodyWidth                      (constant)
    //   left:   hostX = edgeInsetH + 0                        (constant)
    //   bottom: hostY = (wall - root.height) + (root.height - bodyHeight)
    //                 = wall - bodyHeight                   (constant)
    //   top:    hostY = edgeInsetV + 0                        (constant)
    // Detached fullscreen presentation alone retains its travelling offset.
    Item {
        id: body
        width: root.bodyWidth
        height: root.bodyHeight
        x: !root.revealHorizontal ? 0
            : root.attached("left")
                ? -(root.bodyWidth + 5) * root._detachedTravel
                : root.width - root.bodyWidth
                    + (root.bodyWidth + 5) * root._detachedTravel
        y: root.revealHorizontal ? 0
            : root.attached("top")
                ? -(root.bodyHeight + 5) * root._detachedTravel
                : root.height - root.bodyHeight
                    + (root.bodyHeight + 5) * root._detachedTravel

        Item {
            id: inner
            x: root.padding
            y: root.padding
            width: Math.max(0, root.bodyWidth - root.padding * 2)
            height: Math.max(0, root.bodyHeight - root.padding * 2)
            // A rollout that appears at once has no half-revealed state to
            // keep input out of, and a body that flips enabled on the frame it
            // appears would fade its colours in from the disabled blend.
            enabled: root.instantReveal || root._inputReady
            scale: root._joined || !root.settleContent ? 1
                : (root.shouldBeActive && !root.suppressed ? 1 : Motion.microPopScale)
            transformOrigin: Item.Center

            Behavior on scale {
                enabled: !root.suppressed && !root._joined
                NumberAnimation { duration: Motion.microPopDuration; easing.type: Motion.emphasizedEasing }
            }
        }
    }
}
