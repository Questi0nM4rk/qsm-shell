import QtQuick
import QtQuick.Effects

import qs.QsmShell.Style

// A bundled icon, tinted to the theme.
//
// It resolves against the LIBRARY's own tree, so a consumer never has to
// expose its application root or ship a second copy of the set. The shipped
// SVGs are one stroke set normalised to a WHITE stroke, because MultiEffect
// colorises by multiplying luminance: white tints exactly to `color`, and a
// black or currentColor stroke would stay black.
//
// It is a picture and nothing else: no input, no focus and no accessible
// role, so a control that carries it names itself.
Item {
    id: root

    // NOT required. An empty name is a legitimate "nothing to draw here" —
    // a button with a label and no glyph, a row whose leading slot is filled
    // by something else. Required, it meant `Capsule { label: "Discard" }`
    // failed to construct at all, which is the most ordinary button there is.
    property string name: ""
    property int size: Style.iconMd
    property color color: Style.text
    // The glyph is on screen: false for an empty name and while one loads.
    readonly property bool ready: base.status === Image.Ready

    width: size
    height: size
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
        // QML cannot throw out of a binding, so a missing glyph says so on the
        // error stream instead of drawing nothing in silence.
        onStatusChanged: {
            if (status === Image.Error)
                console.error(`SvgIcon: no bundled icon "${root.name}"`);
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: base
        colorization: 1
        colorizationColor: root.color
    }
}
