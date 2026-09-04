import QtQuick

// Portable application icon presentation. Consumers resolve desktop-entry or
// icon-theme names before passing source; the library supplies only its fallback.
Image {
    property url sourceUrl: ""
    property url fallbackSource: Qt.resolvedUrl("../assets/icons/application.svg")

    source: sourceUrl.toString().length > 0 ? sourceUrl : fallbackSource
    asynchronous: true
    fillMode: Image.PreserveAspectFit
}
