pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// One bounded floating-point value. Qt owns stepping, wrapping, editing,
// locale conversion, press-and-hold and accessibility; this type owns the
// shell's geometry, states and the action enumeration.
T.DoubleSpinBox {
    id: root

    property string size: "md"
    property real fieldHeight: Style.size("SpinBox", size)
    property real naturalWidth: Style.spinBoxWidth
    property bool failed: false
    property string accessibleName: ""

    readonly property real _s: root.fieldHeight / Style.size("SpinBox", "md")
    readonly property real sizeScale: root._s
    readonly property int fieldTextSize: Style.textNear(Style.textMd * root._s)
    readonly property int indicatorIconSize: Style.iconNear(Style.iconSm * root._s)
    readonly property int _inset: Style.rhythm(Style.space3 * root._s)
    readonly property real _minimum: Math.min(root.from, root.to)
    readonly property real _maximum: Math.max(root.from, root.to)
    readonly property bool _canDecrease: root.enabled && (root.wrap || root.value > root._minimum)
    readonly property bool _canIncrease: root.enabled && (root.wrap || root.value < root._maximum)
    readonly property bool focused: root.activeFocus || editor.activeFocus
    // Ring for keyboard focus only; a click keeps the caret as the mark. The
    // editor holds the focus, so Qt's `visualFocus` cannot say how it came:
    // a press on the editor or an indicator latches `_pointerFocus` until
    // the focus leaves.
    property bool _pointerFocus: false
    onFocusedChanged: if (!root.focused) root._pointerFocus = false
    onPressedChanged: if (root.pressed) root._pointerFocus = true
    readonly property bool pressed: root.up.pressed || root.down.pressed
    readonly property bool acceptableInput: editor.acceptableInput

    editable: true
    hoverEnabled: root.enabled
    wheelEnabled: root.enabled
    focusPolicy: Qt.StrongFocus
    Accessible.name: root.accessibleName

    implicitWidth: Math.max(Style.rhythm(root.naturalWidth * root._s),
        root.leftPadding + root.rightPadding + root._inset * 2)
    implicitHeight: root.fieldHeight
    padding: 0
    leftPadding: root.down.indicator ? root.down.indicator.width : 0
    rightPadding: root.up.indicator ? root.up.indicator.width : 0

    // These wrappers are the programmatic route. Qt's pointer, wheel,
    // keyboard and accessibility routes call the same C++ increase/decrease
    // methods, which preserve a consumer's binding on `value`.
    function stepUp(): bool { return root._step(true); }
    function stepDown(): bool { return root._step(false); }

    function _step(upwards: bool): bool {
        if (!root.enabled)
            return false;
        const before = root.value;
        if (upwards)
            root.increase();
        else
            root.decrease();
        if (root.value === before)
            return false;
        root.valueModified();
        return true;
    }

    function _toBound(target: real): bool {
        if (!root.enabled || root.value === target)
            return false;
        const unit = Math.abs(root.stepSize) || 1;
        const upwards = target > root.value;
        const count = Math.ceil(Math.abs(target - root.value) / unit);
        for (let i = 0; i < count; i++) {
            if (upwards)
                root.increase();
            else
                root.decrease();
        }
        root.valueModified();
        return true;
    }

    function toMinimum(): bool { return root._toBound(root._minimum); }
    function toMaximum(): bool { return root._toBound(root._maximum); }

    readonly property list<T.Action> actions: [
        T.Action { text: "Increase"; enabled: root._canIncrease; onTriggered: root.stepUp() },
        T.Action { text: "Decrease"; enabled: root._canDecrease; onTriggered: root.stepDown() },
        T.Action { text: "Minimum"; enabled: root.enabled && root.value > root._minimum; onTriggered: root.toMinimum() },
        T.Action { text: "Maximum"; enabled: root.enabled && root.value < root._maximum; onTriggered: root.toMaximum() }
    ]

    function _handleBoundKey(event): void {
        // An editable field keeps Home and End for the caret; the bounds stay
        // reachable through toMinimum() and toMaximum().
        if (!root.enabled || root.editable || root.inputMethodComposing)
            return;
        if (event.key === Qt.Key_Home) {
            root.toMinimum();
            event.accepted = true;
        } else if (event.key === Qt.Key_End) {
            root.toMaximum();
            event.accepted = true;
        }
    }

    Keys.onPressed: event => root._handleBoundKey(event)

    background: Surface {
        objectName: "spinBoxSurface"
        radius: Style.radiusMd
        hovered: root.enabled && (root.hovered || root.focused)
        enabled: root.enabled
        border.width: root.failed ? 1 : 0
        border.color: root.enabled ? Style.danger : Style.disabled(Style.danger)
    }

    contentItem: Item {
        clip: true

        TextInput {
            id: editor
            objectName: "spinBoxInput"
            anchors.fill: parent
            // The template's paddings already reserve the equal indicator
            // targets. Keeping this input unpadded makes the remaining area
            // the fixed centre viewport, so a fitting value is centred while
            // a longer one scrolls inside it instead of being clipped early.
            enabled: root.enabled
            readOnly: !root.editable
            text: root.displayText
            validator: root.validator
            inputMethodHints: root.inputMethodHints
            selectByMouse: true
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            color: root.enabled ? Style.text : Style.disabled(Style.text)
            selectionColor: Style.accent
            selectedTextColor: Style.textOnPrimary
            font.family: Style.technicalFontFamily
            font.pixelSize: root.fieldTextSize
            cursorDelegate: Item {}

            // Passive: sees the press that focuses the editor without taking it.
            TapHandler {
                onPressedChanged: if (pressed) root._pointerFocus = true
            }

            Keys.onPressed: event => root._handleBoundKey(event)
        }

        Rectangle {
            id: caret
            property bool holdSolid: false
            readonly property int halfPeriod: Application.styleHints.cursorFlashTime / 2
            x: Math.round(editor.x + editor.cursorRectangle.x)
            y: editor.y + editor.cursorRectangle.y
            width: Style.spaceTight
            height: editor.cursorRectangle.height
            color: root.enabled ? Style.accent : Style.disabled(Style.accent)
            radius: Style.radiusXs
            visible: editor.activeFocus && root.editable

            onVisibleChanged: opacity = 1

            Connections {
                target: editor
                function onCursorPositionChanged(): void {
                    caret.opacity = 1;
                    caret.holdSolid = true;
                    holdTimer.restart();
                }
            }

            Timer {
                id: holdTimer
                interval: caret.halfPeriod
                onTriggered: caret.holdSolid = false
            }

            Timer {
                running: caret.visible && !caret.holdSolid
                    && caret.halfPeriod > 0 && !Style.reducedMotion
                repeat: true
                interval: caret.halfPeriod
                onTriggered: caret.opacity = caret.opacity === 1 ? 0 : 1
            }
        }
    }

    component Indicator: Item {
        id: indicator
        required property bool increasing
        required property var node
        readonly property bool available: increasing ? root._canIncrease : root._canDecrease

        implicitWidth: root.fieldHeight
        implicitHeight: root.fieldHeight
        width: implicitWidth
        height: root.height
        enabled: available

        SvgIcon {
            id: glyph
            anchors.centerIn: parent
            name: indicator.increasing ? "plus" : "minus"
            size: root.indicatorIconSize
            color: indicator.available ? Style.textMuted : Style.disabled(Style.textMuted)
        }

        StateLayer {
            anchors.fill: parent
            host: indicator.node
            interactive: indicator.available
            focused: false
            target: glyph
            pressScale: Motion.pressScale
        }
    }

    down.indicator: Indicator {
        increasing: false
        node: root.down
        x: root.mirrored ? root.width - width : 0
    }

    up.indicator: Indicator {
        increasing: true
        node: root.up
        x: root.mirrored ? 0 : root.width - width
    }

    StateLayer {
        objectName: "spinBoxLayer"
        z: -0.5
        width: root.width
        height: root.height
        host: root
        target: null
        focused: root.focused && !root._pointerFocus
        focusRadius: Style.radiusMd
        focusColor: root.failed ? Style.danger : Style.accent
    }

    HoverHandler {
        id: cursorReader
        cursorShape: {
            const point = cursorReader.point.position;
            const upItem = root.up.indicator;
            const downItem = root.down.indicator;
            if (upItem && upItem.contains(upItem.mapFromItem(root, point)))
                return root._canIncrease ? Qt.PointingHandCursor : Qt.ArrowCursor;
            if (downItem && downItem.contains(downItem.mapFromItem(root, point)))
                return root._canDecrease ? Qt.PointingHandCursor : Qt.ArrowCursor;
            return root.editable && root.enabled ? Qt.IBeamCursor : Qt.ArrowCursor;
        }
    }
}
