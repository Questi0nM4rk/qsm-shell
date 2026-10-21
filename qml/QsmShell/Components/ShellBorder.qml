import QtQuick
import qs.QsmShell.Style

// THE host: the seven-call contract a Rollout requires, the melt shader that
// paints the merged silhouette, and nothing else. The window, the layer shell,
// the input mask, and every specific surface stay with the consumer. This type
// never names Wayland, a monitor, or a Region: it publishes plain rectangles
// (`maskRects`) and paints the silhouette; what a consumer does with either is
// its own business.
Item {
    id: root

    // Consumer suppression hook (11c gap: a second consumer's fullscreen or
    // focus-mode policy is exactly the Wayland-shaped knowledge this type may
    // never hold, per the design's boundary decision — yet a registration can
    // outlive the moment such a consumer already decided it must stop
    // painting/masking. `Rollout.suppressed` unregisters INSTANTLY for a
    // caller built on it; a caller that talks to registerBulge or
    // registerFullscreenCapsule directly, or one torn down through an async
    // callback, can leave an entry behind for a frame the consumer already
    // ruled out. `entryFilter` is a predicate over a registry id, applied to
    // every derived view below (never to the raw registries themselves, so a
    // trace or a dump still sees the truth). Absent (null, the default)
    // filters nothing — the pre-hook behaviour.
    property var entryFilter: null

    // The pointer reader every Rollout's `hovered`/`keepOpen` needs (the
    // keep-open rule). ShellBorder cannot declare its own `ScenePointer`:
    // that reader has to sit on the ANCESTOR of the surfaces it watches, and
    // ShellBorder is a SIBLING of those surfaces, not their ancestor -- so
    // the consumer assigns its own here. Null is legal: a host with none
    // assigned simply reports `keepOpen` false on every Rollout under it.
    property var pointer: null

    // ── the seven-call contract ─────────────────────────────────────────
    // Registration mechanism for rollout mask rects. Keyed by caller-owned
    // id; reassigned rather than mutated so bindings re-evaluate.
    property var rolloutRegions: ({})
    // The union of hit rects the consumer needs, as plain Qt.rect values.
    // A `readonly property`, not a signal: a binding cannot forget to
    // subscribe, and cannot deliver an update the consumer drops (ADR
    // "transport"). What the consumer does with these — a Wayland Region, a
    // mask, nothing at all — is the one thing this type may never know.
    readonly property var maskRects: Object.keys(rolloutRegions)
        .filter(id => !root.entryFilter || root.entryFilter(id))
        .map(id => rolloutRegions[id])

    function registerRolloutRegion(id, rect) {
        const next = Object.assign({}, rolloutRegions);
        next[id] = rect;
        rolloutRegions = next;
    }

    function unregisterRolloutRegion(id) {
        if (!(id in rolloutRegions))
            return;

        const next = Object.assign({}, rolloutRegions);
        delete next[id];
        rolloutRegions = next;
    }

    // Bulge registry: a SECOND registration mechanism next to
    // registerRolloutRegion above. Mask rects are hit-test areas; the melt
    // shader instead needs each open rollout's actual VISUAL silhouette, so
    // it gets its own registry, keyed and reassigned the same way. Shares the
    // 8-slot ceiling with the shader's uniform cap (and with rolloutRegions
    // above) so the mask and the melt never disagree about how many rollouts
    // fit. (The eight-slot budget itself is not redesigned here — ADR "not
    // designed".)
    property var bulgeRegions: ({})
    readonly property var bulgeEntries: Object.keys(bulgeRegions)
        .filter(id => !root.entryFilter || root.entryFilter(id))
        .map(id => bulgeRegions[id])
    readonly property int maxBulgeSlots: 8

    // Native fullscreen paint is a separate silhouette set. It deliberately
    // has no frame operand: only detached allowlisted capsules reach this set.
    //
    // A REGISTRATION IS NOT A PAINT ORDER, and one consumer needs the two to
    // differ. A surface that paints a REAL body of its own over a fullscreen
    // client — a DataCapsule — still needs its inner rects as INPUT holes so
    // the rows under it stay clickable, but handing those same rects to the
    // melt shader paints a stack of separate capsule bodies around content
    // that already has one. `paint: false` on the registration is that
    // separation, and it is the ONLY separation:
    // `fullscreenCapsuleEntries` stays every registered hole (input), while
    // `fullscreenPaintEntries` is the subset the shader may draw.
    property var fullscreenCapsules: ({})
    readonly property var fullscreenCapsuleEntries: Object.keys(fullscreenCapsules)
        .filter(id => !root.entryFilter || root.entryFilter(id))
        .map(id => fullscreenCapsules[id])
    readonly property var fullscreenPaintEntries: Object.keys(fullscreenCapsules)
        .filter(id => (!root.entryFilter || root.entryFilter(id))
            && fullscreenCapsules[id].paint !== false)
        .map(id => fullscreenCapsules[id])
    readonly property int maxFullscreenCapsuleSlots: 8

    // `paint` defaults to true, so every existing caller (a Rollout's own
    // detached capsule) is byte-for-byte the pre-flag behaviour.
    function registerFullscreenCapsule(id, rect, radius, paint = true) {
        const next = Object.assign({}, fullscreenCapsules);
        next[id] = { rect: rect, radius: radius, paint: paint !== false };
        fullscreenCapsules = next;
    }

    function unregisterFullscreenCapsule(id) {
        if (!(id in fullscreenCapsules))
            return;
        const next = Object.assign({}, fullscreenCapsules);
        delete next[id];
        fullscreenCapsules = next;
    }

    // The shader's slot accessors read the PAINTED view, not every hole: an
    // entry registered with `paint: false` exists for input only and must
    // consume no capsule slot. `fullscreenCapsuleEntries` stays the complete
    // input set for the consumer's mask.
    function fullscreenRectAt(index) {
        return index < root.fullscreenPaintEntries.length
            ? root.fullscreenPaintEntries[index].rect : Qt.rect(0, 0, 0, 0);
    }

    function fullscreenRadiusAt(index) {
        return index < root.fullscreenPaintEntries.length
            ? root.fullscreenPaintEntries[index].radius : 0;
    }

    // radius: per-corner, in CSS border-radius order — (top-left, top-right,
    // bottom-right, bottom-left) — as a vector4d. A Rollout derives this from
    // its own `edges`; a non-Rollout consumer (e.g. a popout Card that
    // touches no screen edge) passes the same radius on all four corners.
    // The shader's edgemelt.frag reads this order via its own bulgeRadius0..7
    // uniforms — keep both sides of that contract in sync.
    // blend: [0,1] scale on the melt reach for this bulge's neck — Rollouts
    // shrink it with their protrusion so absorbed bodies stop bridging.
    // deform: inverse 2x2 of the goo matrix (row-major vec4) + its minEig.
    // EDGE SNAP. A silhouette that stops just short of a
    // screen edge leaves a sliver the shader is already half-bridging — the
    // melt reach IS the distance at which two shapes fuse, so anything inside
    // it reads as a pinched neck rather than a deliberate gap. Rather than tune
    // that away per surface, close it here: every silhouette in the shell
    // passes through registerBulge, so the rule lives in exactly one place.
    //
    // Only the SILHOUETTE grows. Content never moves (it is laid out
    // independently of the rect it registers) and the hit rect is a separate
    // registry, so input stays where the content is — a shape that merely
    // touches an edge does not become clickable there.
    //
    // Corners on a snapped edge go square: they are inside the merged body
    // now, and a radius there draws a notch at the seam.
    function snapToEdges(rect, radius, edgeBits) {
        const reach = root.edgeSnapReach;
        let x = rect.x, y = rect.y, w = rect.width, h = rect.height;
        // radius order is CSS: top-left, top-right, bottom-right, bottom-left.
        let tl = radius.x, tr = radius.y, br = radius.z, bl = radius.w;
        let bits = edgeBits;

        // Gaps are measured to the BAND'S INNER FACE, not the screen edge. The
        // band is what a silhouette fuses with, so measuring to the screen
        // made a rollout that stopped short of the band look further short of
        // "an edge" and fall outside the threshold. Once inside the reach the
        // rect extends all the way THROUGH the band to the screen edge, so
        // the two become one body.
        // The threshold is `<= reach` with NO lower bound, so flush (gap
        // exactly 0) and already-overlapping (negative) both count as merged.
        // A strict `> 0` was the bug behind a nudge in a tall popout's
        // bottom-right corner: a card clamped to rest ON the band's inner face
        // has a gap of precisely zero, fell through every branch, and kept its
        // corner radius — so the silhouette curved away before it reached the
        // band and the melt bridged the sliver it left. Zero is the most
        // likely gap of all, not an edge case: it is where the clamp parks
        // anything too tall for the space.
        // Origin fill continues in the shader. Snapping that side to the screen
        // would truncate the full moving body and displace its deformation pivot.
        if (!(edgeBits & 1) && x - root.leftEdge <= reach) {
            w += x; x = 0; bits |= 1; tl = 0; bl = 0;
        }
        const rightGap = (width - root.edge) - (x + w);
        if (!(edgeBits & 2) && rightGap <= reach) {
            w = width - x; bits |= 2; tr = 0; br = 0;
        }
        if (!(edgeBits & 4) && y - root.edge <= reach) {
            h += y; y = 0; bits |= 4; tl = 0; tr = 0;
        }
        const bottomGap = (height - root.edge) - (y + h);
        if (!(edgeBits & 8) && bottomGap <= reach) {
            h = height - y; bits |= 8; bl = 0; br = 0;
        }

        return {
            rect: Qt.rect(x, y, w, h),
            radius: Qt.vector4d(tl, tr, br, bl),
            edgeBits: bits,
            // A WELD CANNOT BE THICKER THAN WHAT IT WELDS.
            //
            // Where a silhouette is snapped through a band it meets that band's
            // inner face at a right angle, and the melt puts an arc fillet on
            // that concave junction whose radius is `meltSmoothing`. Side bands
            // are thin, so a fillet equal to the melt reach can consume the
            // entire band depth and the silhouette's edge starts curving away
            // BEFORE it reaches the band — which is exactly what "it rounds
            // earlier than it merges" looks like.
            //
            // So the fillet is capped at half the thinnest band this rect
            // crosses: half, not full, because a fillet equal to the band still
            // rounds the joint across its whole depth and leaves no straight
            // run of band to read as a band.
            blendCap: root.weldCap(bits)
        };
    }

    // Half the thinnest band the given edge bits touch, as a fraction of the
    // melt reach. 1 when nothing thinner than the reach is involved.
    function weldCap(bits) {
        let thinnest = Infinity;
        if (bits & 1)
            thinnest = Math.min(thinnest, root.leftEdge);
        if (bits & 2)
            thinnest = Math.min(thinnest, root.edge);
        if (bits & 4)
            thinnest = Math.min(thinnest, root.edge);
        if (bits & 8)
            thinnest = Math.min(thinnest, root.edge);
        if (!isFinite(thinnest))
            return 1;

        return Math.max(0.05, Math.min(1, (thinnest / 2) / root.meltSmoothing));
    }

    // `edgeBits` and `seamBits` are DIFFERENT QUESTIONS and must stay separate.
    //
    // edgeBits answers "which screen BAND is this rect welded through" — it
    // drives weldCap, which caps the melt fillet to half the thinnest band
    // crossed. seamBits answers "on which side does a NEIGHBOURING SILHOUETTE
    // continue", so the rect overlaps it instead of merely touching.
    //
    // They were one field, and overloading it cost a real bug: setting the
    // right bit for a parent popout's flush child made weldCap believe the
    // rect crossed the right band and visibly shrank the fillet where it joins
    // a DIFFERENT edge entirely.
    // A flush seam has to OVERLAP, not merely touch.
    //
    // Square corners and blend 0 give an exact union, which removes the dip and
    // the bulge -- but an exact union of two rects that share an edge leaves the
    // merged SDF at ZERO all along it. Zero is the shader's definition of "edge"
    // in two independent places: `alpha` (a ~0.5 dip, so the wallpaper shows
    // through as a translucent hairline) and the edge separation (depth ~ 0,
    // so a full-strength tint is painted down the join). Both are computed
    // from `mergedSdf` alone, so the overlap has to be in the rect itself.
    //
    // seamBits already names the sides where a neighbouring silhouette continues,
    // so it is the same question and needs no new argument. Reaching into the
    // neighbour is invisible: that side is covered by its body by definition.
    // Applied AFTER snapToEdges so weldCap still sees the rect's true size --
    // the bug that cost a round when edgeBits and seamBits were one field.
    function overlapSeams(rect, seamBits) {
        if (!seamBits)
            return rect;

        const o = root.seamOverlap;
        let x = rect.x;
        let y = rect.y;
        let w = rect.width;
        let h = rect.height;
        if (seamBits & 1) { x -= o; w += o; }
        if (seamBits & 2) { w += o; }
        if (seamBits & 4) { y -= o; h += o; }
        if (seamBits & 8) { h += o; }
        return Qt.rect(x, y, w, h);
    }

    // `outness` is HOW FAR OUT the body is, 0..1 — a different fact from
    // `blend`. blend is the melt radius and a caller may legitimately set it
    // to 0 to ask for an exact union (a flush nested host does exactly that);
    // outness says whether this body has emerged at all, which is what the
    // edge glow is allowed to draw on. Conflating them makes a settled flush
    // child look like something still coming out of the wall.
    function registerBulge(id, rect, radius, blend, deform, minEig, edgeBits, seamBits,
            detached = false, outness = 1) {
        const snapped = detached
            ? { rect: rect, radius: radius ?? Qt.vector4d(0, 0, 0, 0),
                edgeBits: edgeBits ?? 0, blendCap: 1 }
            : root.snapToEdges(rect, radius ?? Qt.vector4d(0, 0, 0, 0), edgeBits ?? 0);
        const next = Object.assign({}, bulgeRegions);
        next[id] = {
            rect: root.overlapSeams(snapped.rect, seamBits ?? 0),
            radius: snapped.radius,
            blend: (blend === undefined ? 1 : blend) * snapped.blendCap,
            deform: deform ?? Qt.vector4d(1, 0, 0, 1),
            minEig: minEig === undefined ? 1 : minEig,
            outness: outness === undefined ? 1 : Math.max(0, Math.min(1, outness)),
            originBits: edgeBits ?? 0,
            edgeBits: snapped.edgeBits | (seamBits ?? 0)
        };
        bulgeRegions = next;
    }

    function unregisterBulge(id) {
        if (!(id in bulgeRegions))
            return;

        const next = Object.assign({}, bulgeRegions);
        delete next[id];
        bulgeRegions = next;
    }

    function bulgeRectAt(index) {
        return index < root.bulgeEntries.length ? root.bulgeEntries[index].rect : Qt.rect(0, 0, 0, 0);
    }

    function bulgeRadiusAt(index) {
        return index < root.bulgeEntries.length ? root.bulgeEntries[index].radius : Qt.vector4d(0, 0, 0, 0);
    }

    // Low side bits are the seam bits; high side bits extend the origin's fill.
    function bulgeParamAt(index) {
        return index < root.bulgeEntries.length
            ? Qt.vector4d(root.bulgeEntries[index].minEig ?? 1, root.bulgeEntries[index].blend,
                (root.bulgeEntries[index].edgeBits ?? 0)
                    + (root.bulgeEntries[index].originBits ?? 0) * 16,
                root.bulgeEntries[index].outness ?? 1)
            : Qt.vector4d(1, 1, 0, 1);
    }

    function bulgeDeformAt(index) {
        return index < root.bulgeEntries.length
            ? (root.bulgeEntries[index].deform ?? Qt.vector4d(1, 0, 0, 1))
            : Qt.vector4d(1, 0, 0, 1);
    }

    // Fullscreen: consumers gate their own instant-hide on this and Rollout
    // reads it directly (`fullscreenDetached &&
    // host.fullscreen`). A plain settable property, not readonly: the
    // consumer is the one thing that can know whether its own monitor is
    // showing a native fullscreen client.
    property bool fullscreen: false

    // ── band geometry ────────────────────────────────────────────────────
    // The consumer's own band thicknesses and viewport rounding. Defaults are
    // Style's own frame numbers so this type renders standalone in a preview.
    property real leftEdge: Style.frameThickness
    property real edge: Style.frameThickness
    property real viewportRadius: Style.radius2xl
    property real meltSmoothing: Style.meltSmoothing
    property real edgeSnapReach: Style.edgeSnapReach
    property real seamOverlap: Style.seamOverlap

    // The band's fill: the one colour the melt shader paints, the frame and
    // every rollout; and the edge separation the shader draws on top of it
    // (12-mechanism "Edge separation").
    property color band: Style.band
    property color edgeColor: Style.edgeColor
    property real edgeStrength: Style.edgeStrength
    property real edgeFade: Style.edgeFade

    // Handle circle (12-mechanism): a dedicated circle SDF the shader folds
    // in alongside the slots, (cx, cy, radius, blend) with radius 0 = absent
    // — this type owns no OSD nub (consumer surface), so a consumer that
    // wants one sets it here; the absent default draws nothing.
    property vector4d handle0: Qt.vector4d(0, 0, 0, 0)

    // Shader slot packing (12-mechanism): rect = (centerX, centerY, halfW,
    // halfH) of the UNDEFORMED live item rect.
    function rectToSlot(r) {
        return Qt.vector4d(r.x + r.width / 2, r.y + r.height / 2, r.width / 2, r.height / 2);
    }

    // registerBulge callers pass CSS border-radius order (tl, tr, br, bl).
    // The shader's sdRoundedBox4 quadrant-select in y-down pixel space lands
    // its slots on (bottom-right, top-right, bottom-left, top-left) — pack
    // to match. Keep in sync with shaders/edgemelt.frag.
    function radiiToShaderOrder(css) {
        return Qt.vector4d(css.z, css.y, css.w, css.x);
    }

    // The silhouette shader (docs/12-mechanism.md, NORMATIVE): band + every
    // rollout as one merged SDF, fill-only. Uniforms are named per-slot —
    // QML arrays bind to GLSL array uniforms as silent zeros on this stack.
    // Deform and param slots ride at identity until goo physics drives them.
    ShaderEffect {
        id: meltShader
        visible: true
        anchors.fill: parent
        // Qt keeps a ShaderEffect binary cached by URL. State-qualify the URL
        // so entering native fullscreen reloads the capsule-capable qsb rather
        // than retaining a shader compiled before hot reload.
        fragmentShader: Qt.resolvedUrl("../shaders/edgemelt.frag.qsb?fullscreen="
            + (root.fullscreen ? "1" : "0"))

        property size resolution: Qt.size(root.width, root.height)
        property real leftEdge: root.leftEdge
        property real edge: root.edge
        property real viewportRadius: root.viewportRadius
        property real smoothFactor: root.meltSmoothing
        property int occupied: Math.min(root.bulgeEntries.length, root.maxBulgeSlots)
        property vector4d fillColor: Qt.vector4d(root.band.r, root.band.g,
            root.band.b, root.band.a)
        // The edge separation rides the same merged silhouette.
        property vector4d edgeColor: Qt.vector4d(root.edgeColor.r, root.edgeColor.g,
            root.edgeColor.b, root.edgeStrength)
        property real edgeFade: root.edgeFade
        property int fullscreenMode: root.fullscreen ? 1 : 0
        property int capsuleOccupied: Math.min(root.fullscreenPaintEntries.length,
            root.maxFullscreenCapsuleSlots)
        property vector4d handle0: root.handle0
        property vector4d rect0: root.rectToSlot(root.bulgeRectAt(0))
        property vector4d rect1: root.rectToSlot(root.bulgeRectAt(1))
        property vector4d rect2: root.rectToSlot(root.bulgeRectAt(2))
        property vector4d rect3: root.rectToSlot(root.bulgeRectAt(3))
        property vector4d rect4: root.rectToSlot(root.bulgeRectAt(4))
        property vector4d rect5: root.rectToSlot(root.bulgeRectAt(5))
        property vector4d rect6: root.rectToSlot(root.bulgeRectAt(6))
        property vector4d rect7: root.rectToSlot(root.bulgeRectAt(7))
        property vector4d radii0: root.radiiToShaderOrder(root.bulgeRadiusAt(0))
        property vector4d radii1: root.radiiToShaderOrder(root.bulgeRadiusAt(1))
        property vector4d radii2: root.radiiToShaderOrder(root.bulgeRadiusAt(2))
        property vector4d radii3: root.radiiToShaderOrder(root.bulgeRadiusAt(3))
        property vector4d radii4: root.radiiToShaderOrder(root.bulgeRadiusAt(4))
        property vector4d radii5: root.radiiToShaderOrder(root.bulgeRadiusAt(5))
        property vector4d radii6: root.radiiToShaderOrder(root.bulgeRadiusAt(6))
        property vector4d radii7: root.radiiToShaderOrder(root.bulgeRadiusAt(7))
        property vector4d deform0: root.bulgeDeformAt(0)
        property vector4d deform1: root.bulgeDeformAt(1)
        property vector4d deform2: root.bulgeDeformAt(2)
        property vector4d deform3: root.bulgeDeformAt(3)
        property vector4d deform4: root.bulgeDeformAt(4)
        property vector4d deform5: root.bulgeDeformAt(5)
        property vector4d deform6: root.bulgeDeformAt(6)
        property vector4d deform7: root.bulgeDeformAt(7)
        property vector4d param0: root.bulgeParamAt(0)
        property vector4d param1: root.bulgeParamAt(1)
        property vector4d param2: root.bulgeParamAt(2)
        property vector4d param3: root.bulgeParamAt(3)
        property vector4d param4: root.bulgeParamAt(4)
        property vector4d param5: root.bulgeParamAt(5)
        property vector4d param6: root.bulgeParamAt(6)
        property vector4d param7: root.bulgeParamAt(7)
        property vector4d capsule0: root.rectToSlot(root.fullscreenRectAt(0))
        property vector4d capsule1: root.rectToSlot(root.fullscreenRectAt(1))
        property vector4d capsule2: root.rectToSlot(root.fullscreenRectAt(2))
        property vector4d capsule3: root.rectToSlot(root.fullscreenRectAt(3))
        property vector4d capsule4: root.rectToSlot(root.fullscreenRectAt(4))
        property vector4d capsule5: root.rectToSlot(root.fullscreenRectAt(5))
        property vector4d capsule6: root.rectToSlot(root.fullscreenRectAt(6))
        property vector4d capsule7: root.rectToSlot(root.fullscreenRectAt(7))
        property real capsuleRadius0: root.fullscreenRadiusAt(0)
        property real capsuleRadius1: root.fullscreenRadiusAt(1)
        property real capsuleRadius2: root.fullscreenRadiusAt(2)
        property real capsuleRadius3: root.fullscreenRadiusAt(3)
        property real capsuleRadius4: root.fullscreenRadiusAt(4)
        property real capsuleRadius5: root.fullscreenRadiusAt(5)
        property real capsuleRadius6: root.fullscreenRadiusAt(6)
        property real capsuleRadius7: root.fullscreenRadiusAt(7)
    }
}
