import QtQuick

// Example consumer backend. A real desktop assigns this object to Style.backend
// during its own bootstrap; it remains outside the library's component logic.
QtObject {
    property bool reducedMotion: false
    property color accent: "#c5a5e9"
    property color surface: "#21142b"
    property color surfaceHover: "#382a48"
    property color surfaceRaised: "#2d1f3a"
    property color text: "#f6f1f9"
    property color textMuted: "#b6a8c2"
    property color background: "#1c0e27"
    property color danger: "#ff8b94"
    property string fontFamily: "sans-serif"
    property string technicalFontFamily: "monospace"
    property real surfaceOpacity: 0.9
    property real opacityDisabled: 0.35
    property int levelThumbSize: 16
    property int levelTrackHeight: 4
    property int controlHeight: 40
    property int controlHeightSm: 32
}
