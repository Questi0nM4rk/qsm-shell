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
    property var backend: null

    // ── mode ────────────────────────────────────────────────────────────
    readonly property bool reducedMotion: backend?.reducedMotion ?? false

    // ── colour ──────────────────────────────────────────────────────────
    readonly property color accent: backend?.accent ?? Tokens.colorAccent
    readonly property color secondary: backend?.secondary ?? Tokens.colorSecondary
    readonly property color success: backend?.success ?? Tokens.colorSuccess
    readonly property color danger: backend?.danger ?? Tokens.colorDanger
    readonly property color outline: backend?.outline ?? Tokens.colorOutline
    readonly property color background: backend?.background ?? Tokens.colorBackground
    readonly property color surface: backend?.surface ?? Tokens.colorSurface
    readonly property color surfaceHover: backend?.surfaceHover ?? Tokens.colorSurfaceHover
    readonly property color surfaceRaised: backend?.surfaceRaised ?? Tokens.colorSurfaceRaised
    readonly property color text: backend?.text ?? Tokens.colorText
    readonly property color textMuted: backend?.textMuted ?? Tokens.colorTextMuted

    // ── opacity ─────────────────────────────────────────────────────────
    readonly property real opacityDisabled: backend?.opacityDisabled ?? Tokens.opacityDisabled
    readonly property real surfaceOpacity: backend?.surfaceOpacity ?? Tokens.opacitySurface

    // ── type ────────────────────────────────────────────────────────────
    readonly property string fontFamily: backend?.fontFamily ?? Tokens.fontFamily
    readonly property string technicalFontFamily: backend?.technicalFontFamily ?? Tokens.fontTechnicalFamily
    readonly property int textXs: backend?.textXs ?? Tokens.typeXs
    readonly property int textSm: backend?.textSm ?? Tokens.typeSm
    readonly property int textMd: backend?.textMd ?? Tokens.typeMd
    readonly property int textLg: backend?.textLg ?? Tokens.typeLg
    readonly property int textXl: backend?.textXl ?? Tokens.typeXl
    // Line height is a RATIO, and it is the difference between a paragraph and
    // a stack of lines. Three roles, because that is how many kinds of text a
    // shell has: a label that must not add height, a heading that must hold
    // together, and a body that must be readable.
    readonly property real lineTight: backend?.lineTight ?? Tokens.lineTight
    readonly property real lineHeading: backend?.lineHeading ?? Tokens.lineHeading
    readonly property real lineBody: backend?.lineBody ?? Tokens.lineBody
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
    readonly property int rolloutRadius: backend?.rolloutRadius ?? Tokens.geometryRolloutRadius
    readonly property int frameThickness: backend?.frameThickness ?? Tokens.geometryFrameThickness
    readonly property int notificationWidth: backend?.notificationWidth ?? Tokens.geometryNotificationWidth
    readonly property int notificationCollapsedHeight: backend?.notificationCollapsedHeight
        ?? Tokens.geometryNotificationCollapsedHeight

    // The "this one" mark: the same 3x18 pill the launcher, the menu rows, the
    // notification history and the device lists all use to say which row is
    // current. It is one idiom, so it is one pair of numbers.
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
