pragma Singleton

import QtQuick
import qs.QsmShell.Style

// THE style surface. Components read this and nothing else — never `Tokens`
// directly, because a value read from Tokens is a value the consumer cannot
// theme, and a component library whose consumer cannot retheme it is a
// component library with two sources of truth.
//
// Every value below resolves the same way: the consumer's backend wins, the
// library's generated token is the fallback. `Tokens` is the DEFAULT theme,
// not the theme.
//
// The scales are complete on purpose. Every gap here is a number typed into a
// component instead — that is where 16, 18 and 22 all became "the small icon"
// in three different files.
QtObject {
    id: root

    property var backend: null

    // ── mode ────────────────────────────────────────────────────────────
    readonly property bool reducedMotion: backend?.reducedMotion ?? false

    // ── colour ──────────────────────────────────────────────────────────
    readonly property color accent: backend?.accent ?? Tokens.colorAccent
    readonly property color secondary: backend?.secondary ?? Tokens.colorSecondary
    readonly property color success: backend?.success ?? Tokens.colorSuccess
    // The semantic status set, complete. It shipped with success and danger
    // only, so a surface with a degraded state or an informational one had
    // nowhere to put it and reached for the accent -- which is the accent
    // budget being spent on a passive readout, and the interactive world going
    // grey as a result.
    readonly property color warning: backend?.warning ?? Tokens.colorWarning
    readonly property color info: backend?.info ?? Tokens.colorInfo
    readonly property color danger: backend?.danger ?? Tokens.colorDanger
    readonly property color background: backend?.background ?? Tokens.colorBackground
    readonly property color surface: backend?.surface ?? Tokens.colorSurface
    // The surface ladder (AGENTS.md). Every layer above the resting surface is
    // DERIVED from it by contrast against the background, so a theme tunes
    // `surface` once and hover, raised and outline follow: raised sits a half
    // step (+0.2) above rest, hover a whole step (+0.4), outline and pressed
    // two steps (+0.8). Hand-tuned tokens drifted -- raised had sunk to the
    // resting value and the lift was gone -- and a backend cannot override
    // these, because a raised colour below hover is a ladder with a rung
    // missing.
    readonly property color surfaceRaised: lift(surface, 0.2)
    readonly property color surfaceHover: lift(surface, 0.4)
    readonly property color outline: lift(surface, 0.8)
    readonly property color text: backend?.text ?? Tokens.colorText
    readonly property color textMuted: backend?.textMuted ?? Tokens.colorTextMuted
    // The band's own fill: the one colour drawn from the wallpaper's darkness
    // rather than the palette ramp (spec 01-frame), so the melt silhouette
    // reads as a frame around the content, not a panel floating on it.
    readonly property color bandFill: backend?.bandFill ?? Tokens.colorBandFill
    // Edge-readability rim and glass-edge stroke on the melt silhouette. Both
    // default to an EXISTING role rather than a private hex, mirroring the
    // consumer theme this was measured against: the rim is the outline
    // colour, the stroke is the text colour, at low strength.
    readonly property color bandRim: backend?.bandRim ?? outline
    readonly property color bandStroke: backend?.bandStroke ?? text

    // ── opacity ─────────────────────────────────────────────────────────
    readonly property real opacityDisabled: backend?.opacityDisabled ?? Tokens.opacityDisabled
    // The accent's strength over a layer when a body is selected (M3 state
    // layer 12 %, Radix step 5). One number, read by `selected()` alone.
    readonly property real opacitySelected: backend?.opacitySelected ?? Tokens.opacitySelected
    readonly property real surfaceOpacity: backend?.surfaceOpacity ?? Tokens.opacitySurface
    // "Not the one you are looking at." A list recedes its non-current rows so
    // the current one is the only thing at full strength; it is a different
    // number from `opacityDisabled`, because receding says "later" and
    // disabled says "never".
    readonly property real opacityRecede: backend?.opacityRecede ?? Tokens.opacityRecede
    // Melt silhouette rim and glass-edge strengths (LIVE-TUNE): 0 disables
    // the rim entirely — the band separates by fill, not by a lit edge.
    readonly property real bandRimStrength: backend?.bandRimStrength ?? Tokens.opacityBandRimStrength
    readonly property real bandStrokeStrength: backend?.bandStrokeStrength
        ?? Tokens.opacityBandStrokeStrength

    // THE way a control says "unavailable", as a colour rather than as
    // `opacity`. Opacity on a control applies to each CHILD separately, so a
    // dimmed composite is a stack of translucent layers: a thumb at 0.35
    // shows the 0.35 fill straight through itself and the two stop being two
    // things. This blends one colour toward the background by the same
    // `opacityDisabled` fraction and keeps it opaque, so the layers stay
    // layers and every part still hides what is behind it.
    //
    //     color: enabled ? c : Style.disabled(c)
    //
    // It is a function rather than a per-role token because the strength is
    // one fact and the roles it applies to are the caller's business.
    function disabled(c: color): color {
        const k = root.opacityDisabled;
        const bg = root.background;
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
        return Qt.tint(base, Qt.rgba(accent.r, accent.g, accent.b, root.opacitySelected));
    }

    // THE way a layer says "above this one". `lift(c, 0.4)` is `c` blended
    // toward `text` until its WCAG contrast against `background` has risen by
    // 0.4; the ladder in AGENTS.md is written in that unit (raised +0.2,
    // hover +0.4, outline and pressed +0.8), so a rung is one call and a
    // theme tunes `surface` alone. Luminance is not linear in the blend, so
    // the fraction is found by bisection rather than solved; twenty halvings
    // land within a quarter of an 8-bit step.
    function contrast(a: color, b: color): real {
        const hi = Math.max(_luminance(a), _luminance(b));
        const lo = Math.min(_luminance(a), _luminance(b));
        return (hi + 0.05) / (lo + 0.05);
    }

    function lift(c: color, by: real): color {
        const target = contrast(c, root.background) + by;
        const toward = root.text;
        let lo = 0, hi = 1;
        for (let i = 0; i < 20; i++) {
            const mid = (lo + hi) / 2;
            if (contrast(_blend(c, toward, mid), root.background) < target)
                lo = mid;
            else
                hi = mid;
        }
        return _blend(c, toward, hi);
    }

    function _blend(a: color, b: color, t: real): color {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
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
    // consumer's backend first, the theme's default second. An unknown name
    // falls back to "md" (warned once) rather than throwing, because a typo'd
    // preset should still render something.
    function size(type: string, name: string): real {
        const fromBackend = root.backend?.sizes?.[type]?.[name];
        if (fromBackend !== undefined)
            return fromBackend;
        const fromTokens = Tokens.sizes[type]?.[name];
        if (fromTokens !== undefined)
            return fromTokens;

        const key = type + "." + name;
        if (!root._warnedSizes[key]) {
            root._warnedSizes[key] = true;
            console.warn(`Style.size: no "${name}" preset for "${type}" -- falling back to "md"`);
        }
        return Tokens.sizes[type].md;
    }

    // ── control and surface geometry ────────────────────────────────────
    readonly property int controlHeight: backend?.controlHeight ?? Tokens.geometryControlHeight
    readonly property int controlHeightSm: backend?.controlHeightSm ?? Tokens.geometryControlHeightSm
    readonly property int controlHeightLg: backend?.controlHeightLg ?? Tokens.geometryControlHeightLg
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
    readonly property int notificationCollapsedHeight: backend?.notificationCollapsedHeight
        ?? Tokens.geometryNotificationCollapsedHeight
    // The melt reach every join neck derives from (spec 01-frame), how close
    // a silhouette must come to a band before it fuses rather than leaves a
    // sliver, and the rim/stroke thicknesses drawn on the merged shape.
    readonly property int meltSmoothing: backend?.meltSmoothing ?? Tokens.geometryMeltSmoothing
    readonly property int edgeSnapReach: backend?.edgeSnapReach ?? Tokens.geometryEdgeSnapReach
    readonly property int bandRimWidth: backend?.bandRimWidth ?? Tokens.geometryBandRimWidth
    readonly property int bandStrokeWidth: backend?.bandStrokeWidth ?? Tokens.geometryBandStrokeWidth
    // How far a flush silhouette reaches into the neighbour it seams against
    // (see ShellBorder.overlapSeams): derived from the stroke width, not its
    // own token, because the seam only has to outrun the stroke's own depth.
    readonly property real seamOverlap: bandStrokeWidth * 4

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

    readonly property int badgeHeight: backend?.badgeHeight ?? Tokens.geometryBadgeHeight
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
}
