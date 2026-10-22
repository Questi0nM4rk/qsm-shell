import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

T.Control {
    id: root

    required property string icon
    // A Control preset name (xs, sm, md, lg). The box is the preset and the
    // glyph follows the box, so a call site never states either.
    property string size: "md"
    property color color: Style.text
    // A toggle that is on: the accent tint over the layer and an accent glyph,
    // the identity every selected body wears; the host owns the state.
    property bool selected: false
    // What a screen reader speaks. A glyph's file name is not a word, so there
    // is no default: the host states one, or the console says so.
    property string accessibleName: ""
    readonly property real _box: Style.size("IconButton", root.size)
    readonly property int _glyph: Style.glyphAlone(root._box)
    // play.svg is the polygon 6,3 20,12 6,21 on a 24 box: its centroid is
    // (6 + 20 + 6) / 3 = 10.67, which is (12 - 10.67) / 24 = 1/18 of the box
    // left of centre, so the glyph shifts right by its size / 18.
    // Whole DEVICE pixels, because a fractional offset blurs the triangle's edges.
    property real opticalOffset: root.icon === "play" ? Style.snap(root._glyph / 18, root) : 0
    readonly property color glyphColor: root.selected ? Style.accent : root.color
    readonly property color paintedColor: root.enabled ? root.glyphColor : Style.disabled(root.glyphColor)
    signal clicked

    focusPolicy: Qt.StrongFocus

    implicitWidth: root._glyph + leftPadding + rightPadding
    implicitHeight: root._glyph + topPadding + bottomPadding
    padding: (root._box - root._glyph) / 2

    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName
    Accessible.onPressAction: root.activate()

    Component.onCompleted: {
        if (root.Accessible.name.length === 0)
            console.warn("IconButton: \"" + root.icon + "\" has no accessibleName -- a screen reader hears an unnamed button")
    }

    function activate(): void {
        if (root.enabled)
            root.clicked()
    }

    readonly property list<T.Action> actions: [
        T.Action { text: root.accessibleName; enabled: root.enabled; onTriggered: root.activate() }
    ]

    contentItem: Item {
        implicitWidth: root._glyph
        implicitHeight: root._glyph

        SvgIcon {
            id: glyph
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.opticalOffset
            name: root.icon
            size: root._glyph
            color: root.paintedColor
        }
    }

    // Under the glyph, and under the hover disc: the selected tint over a
    // transparent base stays a translucent accent on whatever ground it sits,
    // disabled included (the blend keeps the tint's alpha, so it never paints
    // an opaque box on the card behind it).
    Rectangle {
        z: -2
        anchors.fill: parent
        radius: Style.radiusPill
        color: Style.tone(Qt.rgba(0, 0, 0, 0), false, false, true, root.enabled, Style.accent)
        opacity: root.selected ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }

    // Under the glyph: the hover disc is a body, the glyph stands on it.
    StateLayer {
        z: -1
        anchors.fill: parent
        extent: root._glyph
        hoverTint: true
        pressScale: Motion.pressScale
        focusRadius: Style.radiusPill
        manualPressOverride: keys.held
        onClicked: {
            root.forceActiveFocus()
            root.activate()
        }
    }

    ActivationKeys {
        id: keys
        available: root.enabled
        onActivated: root.activate()
    }
    Keys.forwardTo: [keys]
}
