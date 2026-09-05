import QtQuick
import QtQuick.Effects

import qs.QsmShell.Style

// Bundled library icon. Unlike qsm-desktop's copy, this resolves against the
// library tree so consumers do not need to expose their shell root.
Item {
    id: root

    // NOT required. An empty name is a legitimate "nothing to draw here" —
    // a button with a label and no glyph, a row whose leading slot is filled
    // by something else. Required, it meant `Capsule { label: "Discard" }`
    // failed to construct at all, which is the most ordinary button there is.
    property string name: ""
    property int size: Style.iconMd
    property color color: Style.text

    implicitWidth: size
    implicitHeight: size

    Image {
        id: base
        anchors.fill: parent
        source: root.name.length > 0
            ? Qt.resolvedUrl("../assets/icons/" + root.name + ".svg")
            : ""
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: base
        colorization: 1
        colorizationColor: root.color
    }
}
