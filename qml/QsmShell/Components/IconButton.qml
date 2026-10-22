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
    property string accessibleName: icon
    readonly property real _box: Style.size("IconButton", root.size)
    readonly property int _glyph: Style.glyphAlone(root._box)
    // play.svg is the polygon 6,3 20,12 6,21 on a 24 box: its centroid is
    // (6 + 20 + 6) / 3 = 10.67, which is (12 - 10.67) / 24 = 1/18 of the box
    // left of centre, so the glyph shifts right by its size / 18.
    // Whole DEVICE pixels, because a fractional offset blurs the triangle's edges.
    property real opticalOffset: root.icon === "play" ? Style.snap(root._glyph / 18, root) : 0
    readonly property color paintedColor: root.enabled ? root.color : Style.disabled(root.color)
    // A key is down: the button reads as pressed until it is released.
    property bool _keyHeld: false
    signal clicked

    focusPolicy: Qt.StrongFocus

    implicitWidth: root._glyph + leftPadding + rightPadding
    implicitHeight: root._glyph + topPadding + bottomPadding
    padding: (root._box - root._glyph) / 2

    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName
    Accessible.onPressAction: root.activate()

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

    // Under the glyph: the hover disc is a body, the glyph stands on it.
    StateLayer {
        z: -1
        anchors.fill: parent
        extent: root._glyph
        hoverTint: true
        pressScale: Motion.pressScale
        focusRadius: Style.radiusPill
        manualPressOverride: root._keyHeld
        onClicked: {
            root.forceActiveFocus()
            root.activate()
        }
    }

    // Space, Return and Enter act on release, as a native button does: the
    // press shows, a held key repeats nothing, and losing focus mid-press
    // cancels it.
    function _isActivationKey(key: int): bool {
        return key === Qt.Key_Space || key === Qt.Key_Return || key === Qt.Key_Enter;
    }
    Keys.onPressed: event => {
        if (!root._isActivationKey(event.key))
            return;
        event.accepted = true;
        root._keyHeld = root.enabled;
    }
    Keys.onReleased: event => {
        if (!root._isActivationKey(event.key) || !root._keyHeld)
            return;
        event.accepted = true;
        root._keyHeld = false;
        root.activate();
    }
    onActiveFocusChanged: if (!root.activeFocus) root._keyHeld = false
}
