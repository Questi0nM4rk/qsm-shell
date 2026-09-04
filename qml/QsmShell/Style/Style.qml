pragma Singleton

import QtQuick
import qs.QsmShell.Style

// Consumers may override selected defaults with a plain backend object.
QtObject {
    property var backend: null
    readonly property bool reducedMotion: backend?.reducedMotion ?? false
    readonly property color accent: backend?.accent ?? Tokens.colorAccent
    readonly property color secondary: backend?.secondary ?? Tokens.colorSecondary
    readonly property color success: backend?.success ?? Tokens.colorSuccess
    readonly property color outline: backend?.outline ?? Tokens.colorOutline
    readonly property color background: backend?.background ?? Tokens.colorBackground
    readonly property color surface: backend?.surface ?? Tokens.colorSurface
    readonly property color surfaceHover: backend?.surfaceHover ?? Tokens.colorSurfaceHover
    readonly property color surfaceRaised: backend?.surfaceRaised ?? Tokens.colorSurfaceRaised
    readonly property color text: backend?.text ?? Tokens.colorText
    readonly property color textMuted: backend?.textMuted ?? Tokens.colorTextMuted
    readonly property color danger: backend?.danger ?? Tokens.colorDanger
    readonly property real opacityDisabled: backend?.opacityDisabled ?? Tokens.opacityDisabled
    readonly property string fontFamily: backend?.fontFamily ?? Tokens.fontFamily
    readonly property int textXs: Tokens.typeXs
    readonly property int textSm: Tokens.typeSm
    readonly property int iconMd: Tokens.typeIconMd
    readonly property int iconLg: Tokens.iconLg
    readonly property int iconXs: Tokens.iconXs
    readonly property int space3: Tokens.space3
    readonly property int space4: Tokens.space4
    readonly property int radiusLg: Tokens.radiusLg
    readonly property int radiusPill: Tokens.radiusPill
    readonly property int rolloutRadius: Tokens.geometryRolloutRadius
    readonly property int frameThickness: Tokens.geometryFrameThickness
    readonly property real surfaceOpacity: backend?.surfaceOpacity ?? Tokens.opacitySurface
    readonly property int weightBold: Font.DemiBold
    readonly property int weightRegular: Font.Normal
    readonly property int space2: Tokens.space2
    readonly property int space1: Tokens.space1
    readonly property int levelThumbSize: backend?.levelThumbSize ?? Tokens.geometryLevelThumbSize
    readonly property int levelTrackHeight: backend?.levelTrackHeight ?? Tokens.geometryLevelTrackHeight
    readonly property int controlHeight: backend?.controlHeight ?? Tokens.geometryControlHeight
    readonly property int controlHeightSm: backend?.controlHeightSm ?? Tokens.geometryControlHeightSm
    readonly property int weightMedium: Font.Medium
    readonly property string technicalFontFamily: backend?.technicalFontFamily ?? Tokens.fontTechnicalFamily
}
