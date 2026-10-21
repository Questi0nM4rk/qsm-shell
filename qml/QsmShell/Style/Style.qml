pragma Singleton

import QtQuick
import qs.QsmShell.Style

// THE style surface. Components read this and nothing else — never `Tokens`
// directly, because a value read from Tokens is a value the consumer cannot
// theme, and a component library whose consumer cannot retheme it is a
// component library with two sources of truth.
//
// A scale value resolves the same way: the consumer's backend wins, the
// library's generated token is the fallback. `Tokens` is the DEFAULT theme,
// not the theme. A ROLE (a size preset, a glyph for its box, a stroke, a
// body radius, a recede) is derived from the scales and the size table, so a
// consumer reshapes it by theming those and never by naming the role.
//
// The scales are complete on purpose. Every gap here is a number typed into a
// component instead — that is where 16, 18 and 22 all became "the small icon"
// in three different files.
QtObject {
    id: root

    property var backend: null

    // ── mode ────────────────────────────────────────────────────────────
    readonly property bool reducedMotion: backend?.reducedMotion ?? false
    readonly property bool reducedEffects: backend?.reducedEffects ?? false

    // ── colour ──────────────────────────────────────────────────────────
    // The roles (AGENTS.md, "Surface ladder"). Three neutral steps separate
    // by lightness alone, 1.30:1 each: band is the one silhouette the shell
    // paints (frame and every rollout), surface a card inside it, overlay a
    // popout over a card. No rung is derived here: a theme generates all
    // three from one seed (the default's come from `scripts/ladder.mjs`), and
    // a component reads a role, never a lift.
    readonly property color band: backend?.band ?? Tokens.colorBand
    readonly property color surface: backend?.surface ?? Tokens.colorSurface
    readonly property color overlay: backend?.overlay ?? Tokens.colorOverlay
    readonly property color text: backend?.text ?? Tokens.colorText
    readonly property color textMuted: backend?.textMuted ?? Tokens.colorTextMuted
    // primary is the one filled action per surface and the active part of a
    // track; textOnPrimary is its text. accent is what is current (the selected
    // row, the active tab); focus is the keyboard ring. The three share a
    // pastel in the default theme, and the split is what lets a theme give
    // them different ones.
    readonly property color primary: backend?.primary ?? Tokens.colorPrimary
    readonly property color textOnPrimary: backend?.textOnPrimary ?? Tokens.colorTextOnPrimary
    readonly property color accent: backend?.accent ?? Tokens.colorAccent
    readonly property color focus: backend?.focus ?? Tokens.colorFocus
    // The status set, complete: a passive readout never spends the accent.
    readonly property color info: backend?.info ?? Tokens.colorInfo
    readonly property color success: backend?.success ?? Tokens.colorSuccess
    readonly property color warning: backend?.warning ?? Tokens.colorWarning
    readonly property color danger: backend?.danger ?? Tokens.colorDanger
    // The floating shadow is read by DataCapsule alone, for the one body with
    // nothing behind it but a client; nothing in the frame draws a shadow.
    // A key's cap measured against the BAND: 0.9 above it, which is what the
    // overlay step measures when it sits on a surface card on the band. A
    // cap therefore reads the same on the band, on a card and on a popout,
    // where the overlay rung itself vanished on the rung above it.
    readonly property color keycap: backend?.keycap ?? root.lift(root.band, 0.9)
    readonly property color shadow: backend?.shadow ?? Tokens.colorShadow
    // A pair, like the rest: a transparency checker is two greys, and a swatch
    // lays its colour over them so an alpha reads as alpha rather than as a
    // dimmer colour.
    readonly property color checkerLight: backend?.checkerLight ?? Tokens.colorCheckerLight
    readonly property color checkerDark: backend?.checkerDark ?? Tokens.colorCheckerDark
    readonly property real floatingShadowOpacity: backend?.floatingShadowOpacity ?? Tokens.opacityFloatingShadow
    readonly property real floatingShadowBlur: backend?.floatingShadowBlur ?? Tokens.geometryFloatingShadowBlur
    readonly property real floatingShadowOffset: backend?.floatingShadowOffset ?? Tokens.geometryFloatingShadowOffset
    readonly property int floatingShadowExtent: backend?.floatingShadowExtent ?? Tokens.geometryFloatingShadowExtent
    // A card in a list of cards lifts off the band by a slight shadow: the
    // body step separates it, the shadow only says where it ends.
    readonly property real cardShadowOpacity: backend?.cardShadowOpacity ?? Tokens.opacityCardShadow
    readonly property real cardShadowBlur: backend?.cardShadowBlur ?? Tokens.geometryCardShadowBlur
    readonly property real cardShadowOffset: backend?.cardShadowOffset ?? Tokens.geometryCardShadowOffset
    readonly property int cardShadowExtent: backend?.cardShadowExtent ?? Tokens.geometryCardShadowExtent

    // ── opacity ─────────────────────────────────────────────────────────
    readonly property real opacityDisabled: backend?.opacityDisabled ?? Tokens.opacityDisabled
    // The accent's strength over a layer when a body is selected (M3 state
    // layer 12 %, Radix step 5). One number, read by `selected()` alone.
    readonly property real opacitySelected: backend?.opacitySelected ?? Tokens.opacitySelected
    readonly property real surfaceOpacity: backend?.surfaceOpacity ?? Tokens.opacitySurface
    // "Not the one you are looking at." A list recedes its non-current rows so
    // the current one is the only thing at full strength; it is a different
    // number from `opacityDisabled`, because receding says "later" and
    // disabled says "never". It is the strength `recede()` blends by, the
    // lowest at which muted text still meets WCAG AA on the band.
    readonly property real opacityRecede: backend?.opacityRecede ?? Tokens.opacityRecede
    // A badge's tinted body: its tone at this strength over the layer.
    readonly property real badgeTintOpacity: backend?.badgeTintOpacity ?? Tokens.opacityBadgeTint
    // How far a tinted badge's reading is pulled from its tone toward `text`.
    // The tone alone on its own tint is below 4.5:1 at the badge's size; this
    // share clears it on band, surface and overlay.
    readonly property real badgeInkMix: backend?.badgeInkMix ?? Tokens.blendBadgeInk
    // A tinted callout's tone over the surface, and a divider's own line: both
    // are a quiet echo, never a fill, so each is its own number. A rule in a
    // surface and a rule in the band are the same line at two strengths, the
    // band's stronger because nothing but the rule groups what sits on it.
    readonly property real calloutTintOpacity: backend?.calloutTintOpacity ?? Tokens.opacityCalloutTint
    readonly property real dividerOpacity: backend?.dividerOpacity ?? Tokens.opacityDivider
    readonly property real dividerBandOpacity: backend?.dividerBandOpacity ?? Tokens.opacityDividerBand
    // The dim a modal lays over the surface beneath it.
    readonly property real scrimOpacity: backend?.scrimOpacity ?? Tokens.opacityScrim
    // The series colour under a sparkline's line, and the unlit remainder of a
    // spinner's ring.
    readonly property real areaFillOpacity: backend?.areaFillOpacity ?? Tokens.opacityAreaFill
    readonly property real ringTrackOpacity: backend?.ringTrackOpacity ?? Tokens.opacityRingTrack
    // A raised thumb's own shadow, under the thumb and over its track.
    readonly property real thumbShadowOpacity: backend?.thumbShadowOpacity ?? Tokens.opacityThumbShadow
    // A scroll mark shows while the list moves and all but disappears at rest.
    readonly property real scrollCueActiveOpacity: backend?.scrollCueActiveOpacity ?? Tokens.opacityScrollCueActive
    readonly property real scrollCueRestOpacity: backend?.scrollCueRestOpacity ?? Tokens.opacityScrollCueRest
    // The edge separation of the melt silhouette (owner 2026-10-18): a slight
    // line of this colour exactly at the merged shape's edge, fading inward
    // into the fill, drawn by the shader on top of the flat fill. Strength is
    // the colour's share at the very edge; it is gone edgeFade px inward.
    // Not a glow and not a stroke: no grain, no outline.
    readonly property color edgeColor: backend?.edgeColor ?? Tokens.colorEdge
    readonly property real edgeStrength: backend?.edgeStrength ?? Tokens.opacityEdgeStrength

    // THE way a control says "unavailable", as a colour rather than as
    // `opacity`. Opacity on a control applies to each CHILD separately, so a
    // dimmed composite is a stack of translucent layers: a thumb at 0.35
    // shows the 0.35 fill straight through itself and the two stop being two
    // things. This blends one colour toward the band by the same
    // `opacityDisabled` fraction and keeps it opaque, so the layers stay
    // layers and every part still hides what is behind it.
    //
    //     color: enabled ? c : Style.disabled(c)
    //
    // It is a function rather than a per-role token because the strength is
    // one fact and the roles it applies to are the caller's business.
    function disabled(c: color): color {
        return root._towardBand(c, root.opacityDisabled);
    }

    // "Not the current one", the same blend at `opacityRecede`: a row that
    // is merely later stays legible, which a disabled one need not.
    function recede(c: color): color {
        return root._towardBand(c, root.opacityRecede);
    }

    function _towardBand(c: color, k: real): color {
        const bg = root.band;
        return Qt.rgba(bg.r + (c.r - bg.r) * k,
                       bg.g + (c.g - bg.g) * k,
                       bg.b + (c.b - bg.b) * k,
                       1);
    }

    // THE state matrix, once. A body on a layer answers hover, press, selection
    // and unavailability with ONE colour, and every component used to write
    // its own version of this ternary (four of them disagreed on the tint).
    // Order matters and is the ladder's: selection is identity (the accent
    // over the layer), a lift stacks on top of it, and disabled dims whatever
    // came out. `Surface` binds this for the common case; a component with
    // its own Rectangle calls it directly.
    //
    //     color: Style.tone(Style.surface, hovered, pressed, selected, enabled)
    //
    function tone(base: color, hovered: bool, pressed: bool, selected: bool, enabled: bool, accent: color): color {
        let c = selected ? root.selected(base, accent) : base;
        if (pressed)
            c = root.lift(c, 0.8);
        else if (hovered)
            c = root.lift(c, 0.4);
        return enabled ? c : root.disabled(c);
    }

    // Selected is identity, not a lift: the accent at `opacitySelected` over
    // the layer. A transparent base yields a translucent accent, which is
    // what a segment sitting on its own container wants.
    function selected(base: color, accent: color): color {
        return _over(Qt.rgba(accent.r, accent.g, accent.b, root.opacitySelected), base);
    }

    // The press and hover tints `tone` stacks on a layer. `lift(c, 0.4)` is
    // `c` blended toward `text` until its WCAG contrast against `band` has
    // risen by 0.4. Luminance is not linear in the blend, so the fraction is
    // found by bisection rather than solved; twenty halvings land within a
    // quarter of an 8-bit step. No role is derived from it: the ladder's
    // three steps come whole from the theme.
    function contrast(a: color, b: color): real {
        const hi = Math.max(_luminance(a), _luminance(b));
        const lo = Math.min(_luminance(a), _luminance(b));
        return (hi + 0.05) / (lo + 0.05);
    }

    // A translucent `c` (a transparent segment, a selected tint) is measured as
    // it appears over the band, but the lift is returned as `text` laid over
    // `c` at the found fraction, so it keeps `c`'s own alpha and never paints
    // an opaque box on the layer it sits on.
    function lift(c: color, by: real): color {
        const seen = _over(c, root.band);
        const target = contrast(seen, root.band) + by;
        const t = root.text;
        let lo = 0, hi = 1;
        for (let i = 0; i < 20; i++) {
            const mid = (lo + hi) / 2;
            if (contrast(_over(Qt.rgba(t.r, t.g, t.b, mid), seen), root.band) < target)
                lo = mid;
            else
                hi = mid;
        }
        return _over(Qt.rgba(t.r, t.g, t.b, hi), c);
    }

    // `top` laid over `base`, both with their own alpha. Qt.tint mixes the
    // colour channels with the base's even when the base is transparent, which
    // turns "accent over nothing" into a dark accent.
    function _over(top: color, base: color): color {
        const a = top.a + base.a * (1 - top.a);
        if (a <= 0)
            return Qt.rgba(0, 0, 0, 0);
        const k = base.a * (1 - top.a);
        return Qt.rgba((top.r * top.a + base.r * k) / a, (top.g * top.a + base.g * k) / a,
                       (top.b * top.a + base.b * k) / a, a);
    }

    function _luminance(c: color): real {
        const lin = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
    }

    // ── type ────────────────────────────────────────────────────────────
    readonly property string fontFamily: backend?.fontFamily ?? Tokens.fontFamily
    readonly property string technicalFontFamily: backend?.technicalFontFamily ?? Tokens.fontTechnicalFamily
    readonly property int textXs: backend?.textXs ?? Tokens.typeXs
    readonly property int textSm: backend?.textSm ?? Tokens.typeSm
    readonly property int textMd: backend?.textMd ?? Tokens.typeMd
    readonly property int textLg: backend?.textLg ?? Tokens.typeLg
    readonly property int textXl: backend?.textXl ?? Tokens.typeXl
    // The top of the ladder. A big reading (a temperature, a ring's value) and
    // a number read from across the room (a clock) are different enough from
    // each other and from textXl that surfaces were inventing 28 and 44
    // locally rather than going without.
    readonly property int textDisplay: backend?.textDisplay ?? Tokens.typeDisplay
    readonly property int textHero: backend?.textHero ?? Tokens.typeHero
    // Line height is a RATIO, and it is the difference between a paragraph and
    // a stack of lines. Three roles, because that is how many kinds of text a
    // shell has: a label that must not add height, a heading that must hold
    // together, and a body that must be readable.
    readonly property real lineTight: backend?.lineTight ?? Tokens.lineTight
    readonly property real lineHeading: backend?.lineHeading ?? Tokens.lineHeading
    readonly property real lineBody: backend?.lineBody ?? Tokens.lineBody
    // The one letter-spacing in the system: what turns a small bold label into
    // a RULE over a group rather than just a small bold label.
    readonly property real trackingWide: backend?.trackingWide ?? Tokens.trackingWide
    readonly property int weightRegular: backend?.weightRegular ?? Font.Normal
    readonly property int weightMedium: backend?.weightMedium ?? Font.Medium
    readonly property int weightBold: backend?.weightBold ?? Font.DemiBold

    // ── icon ────────────────────────────────────────────────────────────
    readonly property int iconXs: backend?.iconXs ?? Tokens.iconXs
    readonly property int iconSm: backend?.iconSm ?? Tokens.iconSm
    readonly property int iconMd: backend?.iconMd ?? Tokens.iconMd
    readonly property int iconLg: backend?.iconLg ?? Tokens.iconLg
    // The display end: a glyph that is the content of a surface (a media
    // cover, a dashboard reading) rather than a mark beside one.
    readonly property int iconXl: backend?.iconXl ?? Tokens.iconXl
    readonly property int iconXxl: backend?.iconXxl ?? Tokens.iconXxl

    // ── space ───────────────────────────────────────────────────────────
    // spaceTight is the half-step below the grid: a glyph and its own reading
    // read as ONE thing at 2px and as two things at 4px.
    readonly property int spaceTight: backend?.spaceTight ?? Tokens.spaceTight
    readonly property int space1: backend?.space1 ?? Tokens.space1
    readonly property int space2: backend?.space2 ?? Tokens.space2
    readonly property int space3: backend?.space3 ?? Tokens.space3
    readonly property int space4: backend?.space4 ?? Tokens.space4
    readonly property int space5: backend?.space5 ?? Tokens.space5
    readonly property int space6: backend?.space6 ?? Tokens.space6

    // ── radius ──────────────────────────────────────────────────────────
    readonly property int radiusXs: backend?.radiusXs ?? Tokens.radiusXs
    readonly property int radiusSm: backend?.radiusSm ?? Tokens.radiusSm
    readonly property int radiusMd: backend?.radiusMd ?? Tokens.radiusMd
    readonly property int radiusLg: backend?.radiusLg ?? Tokens.radiusLg
    readonly property int radiusXl: backend?.radiusXl ?? Tokens.radiusXl
    readonly property int radius2xl: backend?.radius2xl ?? Tokens.radius2xl
    readonly property int radiusPill: backend?.radiusPill ?? Tokens.radiusPill

    // The table an unknown name already warned about, so a consumer typo
    // reports once rather than once per binding re-evaluation.
    readonly property var _warnedSizes: ({})

    // THE size table. A component knows its own PROPORTIONS; this is the one
    // absolute number a preset NAME resolves to -- `sizes.<Type>.<name>`, the
    // consumer's backend first, the theme's default second. A type the theme
    // gives no table of its own belongs to the `Control` family and shares its
    // ladder, so a preset name means one number across every field, button and
    // bar, and a consumer's `Control.xl` reaches all of them at once. An unknown
    // name falls back to "md" (warned once) rather than throwing, because a
    // typo'd preset should still render something.
    function size(type: string, name: string): real {
        const found = root._preset(type, name);
        if (found !== undefined)
            return found;

        const key = type + "." + name;
        if (!root._warnedSizes[key]) {
            root._warnedSizes[key] = true;
            console.warn(`Style.size: no "${name}" preset for "${type}" -- falling back to "md"`);
        }
        return root._preset(type, "md");
    }

    function _preset(type: string, name: string): var {
        const own = root.backend?.sizes?.[type]?.[name] ?? Tokens.sizes[type]?.[name];
        if (own !== undefined || Tokens.sizes[type] !== undefined)
            return own;
        return root.backend?.sizes?.Control?.[name] ?? Tokens.sizes.Control[name];
    }

    // The type-scale step nearest a wanted pixel size. A control scaled by a
    // size preset wants its reading to scale WITH it, but a glyph at 11.2px is
    // not on the scale; the nearest step is, and one type scale stays one.
    function textNear(px: real): int {
        return root._nearest(px, [root.textXs, root.textSm, root.textMd, root.textLg, root.textXl]);
    }

    // The icon-scale step nearest a wanted pixel size; same reason as
    // `textNear`, for glyphs.
    function iconNear(px: real): int {
        return root._nearest(px, [root.iconXs, root.iconSm, root.iconMd, root.iconLg, root.iconXl, root.iconXxl]);
    }

    // THE glyph for a box, so no call site picks one. A glyph alone in its
    // box (an icon button, a rail cell) fills half of it, and a glyph beside a
    // label or a text (a capsule, a segment, a field's leading mark) takes two
    // fifths, because the label carries the meaning and the glyph only marks
    // it. Neither goes under `iconSm`; 12 is a status mark, never a control's.
    function glyphAlone(box: real): int {
        return root.iconNear(Math.max(box * Tokens.geometryGlyphAloneRatio, root.iconSm));
    }

    function glyphBeside(box: real): int {
        return root.iconNear(Math.max(box * Tokens.geometryGlyphBesideRatio, root.iconSm));
    }

    // THE thickness of a line, in whole DEVICE pixels. A square Rectangle's
    // edges snap to the device grid, so one of logical height h at y paints
    // round((y + h) * dpr) - round(y * dpr) rows. When h * dpr is a whole
    // number m that is m for every y, so the line is the same thickness
    // wherever it sits and never anti-aliases into a second row. This returns
    // the logical thickness nearest `n` that is a whole device count, never
    // under one pixel. `dpr` is the item's own `Screen.devicePixelRatio`, read
    // where the line is drawn so it is right per monitor: it is not a
    // constant and not a global.
    //
    //     height: Style.stroke(1, Screen.devicePixelRatio)
    //
    function stroke(n: real, dpr: real): real {
        return Math.max(1, Math.round(n * dpr)) / dpr;
    }

    // A position on the device grid. Centring a curved thing (a pill track,
    // a ring) lands its edge between rows unless the offset is snapped.
    function snap(v: real, dpr: real): real {
        return Math.round(v * dpr) / dpr;
    }

    // A spacing snapped to the 4px rhythm, never below the half step. Insets
    // scaled by a size preset land between the grid lines otherwise.
    function rhythm(px: real): int {
        return Math.max(root.spaceTight, Math.round(px / root.space1) * root.space1);
    }

    function _nearest(px: real, steps: list<int>): int {
        let best = steps[0];
        for (const step of steps)
            if (Math.abs(step - px) < Math.abs(best - px))
                best = step;
        return best;
    }

    // ── control and surface geometry ────────────────────────────────────
    readonly property int controlHeight: backend?.controlHeight ?? root.size("Control", "md")
    readonly property int controlHeightSm: backend?.controlHeightSm ?? root.size("Control", "sm")
    readonly property int controlHeightLg: backend?.controlHeightLg ?? root.size("Control", "lg")
    // The Blueprint's pointer-target floor. A swatch paints a compact face
    // but answers on this square, so palette siblings never share a hit zone.
    readonly property int swatchTarget: backend?.swatchTarget ?? Tokens.geometrySwatchTarget
    // The slider, in one thickness and one thumb. A control that needs a
    // fatter track states it at the call site; the library keeps one default.
    readonly property int sliderTrackThickness: backend?.sliderTrackThickness
        ?? Tokens.geometrySliderTrackThickness
    readonly property int sliderThumbSize: backend?.sliderThumbSize ?? Tokens.geometrySliderThumbSize
    readonly property int sliderThumbLift: backend?.sliderThumbLift ?? Tokens.geometrySliderThumbLift
    // The unit every non-pointer route walks in. It is never 0: at 0 Qt's own
    // arrow keys fall back to 0.1 VALUE units (not 10% of the range) and the
    // accessibility increase/decrease actions go inert. So the step is the
    // token and the keyboard and page counts are whole numbers OF it, which is
    // also what lets a route step through Qt's own increase()/decrease().
    readonly property real sliderStep: backend?.sliderStep ?? Tokens.geometrySliderStep
    readonly property int sliderKeyboardUnits: backend?.sliderKeyboardUnits
        ?? Tokens.geometrySliderKeyboardUnits
    readonly property int sliderPageUnits: backend?.sliderPageUnits ?? Tokens.geometrySliderPageUnits
    // Natural length ALONG the axis. A slider's main-axis size is a constant,
    // the same way a text box's width is: it is not a function of its content,
    // and a call site that wants a different length states it.
    readonly property int sliderLength: backend?.sliderLength ?? Tokens.geometrySliderLength
    readonly property int sliderLengthVertical: backend?.sliderLengthVertical
        ?? Tokens.geometrySliderLengthVertical
    readonly property int rolloutRadius: backend?.rolloutRadius ?? Tokens.geometryRolloutRadius
    readonly property int frameThickness: backend?.frameThickness ?? Tokens.geometryFrameThickness
    readonly property int notificationWidth: backend?.notificationWidth ?? Tokens.geometryNotificationWidth
    // The natural width of a text-shaped control. Constant, never content-derived.
    readonly property int controlWidth: backend?.controlWidth ?? Tokens.geometryControlWidth
    readonly property int spinBoxWidth: backend?.spinBoxWidth ?? Tokens.geometrySpinBoxWidth
    readonly property int statWidth: backend?.statWidth ?? Tokens.geometryStatWidth
    readonly property int notificationCollapsedHeight: backend?.notificationCollapsedHeight
        ?? Tokens.geometryNotificationCollapsedHeight
    // Full compact message composition: headline plus two readable body lines.
    readonly property int notificationPreviewHeight: backend?.notificationPreviewHeight
        ?? Tokens.geometryNotificationPreviewHeight
    // Long message content scrolls inside this fixed expanded viewport.
    readonly property int notificationBodyViewportHeight: backend?.notificationBodyViewportHeight
        ?? Tokens.geometryNotificationBodyViewportHeight
    // The melt reach every join neck derives from (spec 01-frame), how close
    // a silhouette must come to a band before it fuses rather than leaves a
    // sliver, and how far a flush silhouette reaches into the neighbour it
    // seams against (see ShellBorder.overlapSeams), so the AA never finds a
    // zero-depth edge along the join.
    readonly property int meltSmoothing: backend?.meltSmoothing ?? Tokens.geometryMeltSmoothing
    readonly property int edgeSnapReach: backend?.edgeSnapReach ?? Tokens.geometryEdgeSnapReach
    // How far a hover trigger reaches past the shape it opens (owner
    // 2026-10-18: "musime to roztahnout, abych nemusel mit pixel perfect
    // aim"). A handle is a few pixels of paint; the pointer is found inside
    // that paint grown by this many pixels on every side, never inside the
    // paint alone. 20 makes the 8px dots handle a 48px target.
    readonly property int hoverReach: backend?.hoverReach ?? Tokens.geometryHoverReach
    // The zone a pointer must be inside to open what a painted shape opens:
    // `painted` grown by hoverReach on every side, clipped to `bounds` (the
    // window, past whose edge there is no pointer to find). One owner so no
    // handle grows its own zone differently.
    function hoverZone(painted: rect, bounds: rect): rect {
        const left = Math.max(bounds.x, painted.x - hoverReach)
        const top = Math.max(bounds.y, painted.y - hoverReach)
        const right = Math.min(bounds.x + bounds.width, painted.x + painted.width + hoverReach)
        const bottom = Math.min(bounds.y + bounds.height, painted.y + painted.height + hoverReach)
        return Qt.rect(left, top, Math.max(0, right - left), Math.max(0, bottom - top))
    }
    readonly property real seamOverlap: backend?.seamOverlap ?? Tokens.geometrySeamOverlap
    readonly property int edgeFade: backend?.edgeFade ?? Tokens.geometryEdgeFade

    // The "this one" mark: the same 3x18 pill the launcher, the menu rows, the
    // notification history and the device lists all use to say which row is
    // current. It is one idiom, so it is one pair of numbers.
    // A count riding a cell's corner, and the bar a progress or a level is
    // drawn on. Both were being typed as literals at the call sites that
    // needed them.
    // The ring, at the size a performance card wants it. A card fitting three
    // of them states its own; the library keeps one default.
    // A tile: an icon over its label, big enough to hit without aiming.
    readonly property int tileWidth: backend?.tileWidth ?? Tokens.geometryTileWidth
    readonly property int tileHeight: backend?.tileHeight ?? Tokens.geometryTileHeight
    // A notification's own geometry: the separator inset, the invisible
    // margin that lifts a small action label to a 24px hit target, how far a
    // vertical drag must travel before it counts as expand/collapse, and the
    // fraction of the card's own width a horizontal swipe must cross before
    // it counts as a dismiss rather than a spring-back.
    readonly property int notificationDividerInset: backend?.notificationDividerInset
        ?? Tokens.geometryNotificationDividerInset
    readonly property int notificationActionHitMargin: backend?.notificationActionHitMargin
        ?? Tokens.geometryNotificationActionHitMargin
    readonly property int notificationExpandDragPx: backend?.notificationExpandDragPx
        ?? Tokens.geometryNotificationExpandDragPx
    readonly property real notificationDismissFraction: backend?.notificationDismissFraction
        ?? Tokens.geometryNotificationDismissFraction

    readonly property int ringDiameter: backend?.ringDiameter ?? Tokens.geometryRingDiameter
    readonly property int ringStroke: backend?.ringStroke ?? Tokens.geometryRingStroke
    // A spinner's stroke as a share of its diameter: a fixed stroke is a disc
    // on a small one and a hairline on a large one.
    readonly property real spinnerStrokeRatio: backend?.spinnerStrokeRatio ?? Tokens.geometrySpinnerStrokeRatio

    readonly property int badgeHeight: backend?.badgeHeight ?? Tokens.geometryBadgeHeight
    readonly property int badgeDot: backend?.badgeDot ?? Tokens.geometryBadgeDot
    // The chip a count sits in: one width for every count up to "99+", so a
    // ticking number never resizes it.
    readonly property int badgeWidth: backend?.badgeWidth ?? Tokens.geometryBadgeWidth
    readonly property int trackThickness: backend?.trackThickness ?? Tokens.geometryTrackThickness

    readonly property int markThickness: backend?.markThickness ?? Tokens.geometryMarkThickness
    readonly property int markHeight: backend?.markHeight ?? Tokens.geometryMarkHeight

    // THE concentric rule, as a function rather than as arithmetic every call
    // site is expected to redo. A rounded thing inside a rounded thing must
    // curve at the outer radius MINUS the gap between them; give both the same
    // radius and the two curves read as a seam instead of as one surface
    // sitting inside another.
    //
    //     Rectangle { radius: Style.childRadius(this) }
    //
    // It reads the parent and the real inset, so it stays right when the
    // padding changes and there is no number to keep in sync. A parent that is
    // not rounded gives 0, which is the correct answer rather than a guess.
    function childRadius(item: Item): int {
        const parent = item?.parent ?? null;
        if (!parent || parent.radius === undefined)
            return 0;

        const inset = Math.min(item.x, item.y,
            parent.width - (item.x + item.width),
            parent.height - (item.y + item.height));
        return Math.max(0, parent.radius - Math.max(0, inset));
    }

    // The concentric rule for a row whose parent is a ListView: there the
    // parent's `radius` is not the surface's, so `childRadius` answers 0. A
    // row states how far its highlight sits from the rollout's edge and the
    // curve follows the rollout's own radius minus that inset.
    function insetRadius(inset: real): int {
        return Math.max(0, root.rolloutRadius - Math.max(0, inset));
    }

    // What a rollout leaves between its edge and its content on every side,
    // and the radius a body sitting directly in that inset takes: derived, so
    // a card, a field, a tile and a row's pill are all concentric with the
    // rollout and none of them picks a corner by eye.
    readonly property int rolloutPadding: root.space4
    readonly property int radiusBody: root.insetRadius(root.rolloutPadding)
}
