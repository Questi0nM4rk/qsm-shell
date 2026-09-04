import QtQuick

import qs.QsmShell.Style

Rectangle {
    property color surfaceColor: Style.surface
    property real surfaceOpacity: Style.surfaceOpacity

    color: Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, surfaceOpacity)
    radius: Style.radiusLg
}
