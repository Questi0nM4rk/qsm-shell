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
    readonly property int indicatorIconSize: Style.glyphAlone(root.fieldHeight)
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
    // The wheel steps the value only while the field has focus, the way a
    // number field does everywhere else: a pointer passing over it while a
    // panel scrolls must not change a setting, so an unfocused field hands the
    // wheel to the scroller beneath it.
    wheelEnabled: root.enabled && root.focused
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

    // One native step as long as the distance, with wrapping off so it clamps
    // on the bound instead of wrapping past it. The two writes are Bindings
    // that give the property back when they release, so a host's binding on
    // `stepSize` or `wrap` survives, and a range of a million steps is one
    // call instead of two million (5.1 s of a frozen window measured).
    Binding { id: jumpStep; target: root; property: "stepSize"; when: false }
    Binding { id: jumpWrap; target: root; property: "wrap"; value: false; when: jumpStep.when }

    function _toBound(target: real): bool {
        if (!root.enabled || root.value === target)
            return false;
        jumpStep.value = Math.abs(target - root.value);
        jumpStep.when = true;
        if (target > root.value)
            root.increase();
        else
            root.decrease();
        jumpStep.when = false;
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
        radius: Style.radiusBody
        hovered: root.enabled && (root.hovered || root.focused)
        enabled: root.enabled
        border.width: root.failed ? Style.stroke(Style.indicatorWidth, root) : 0
        border.color: root.enabled ? Style.danger : Style.disabled(Style.danger)
    }

    contentItem: Item {
        // Qt accepts an edit by reading the `text` of its content item when
        // Return is pressed or focus leaves. This wrapper clips the editor, so
        // it states the editor's text itself: without it a typed value was
        // never taken and the field kept the old one.
        property alias text: editor.text
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

            // A value too long for the fixed viewport shows its head while
            // nobody is typing. Scrolled to a caret at the end it read 3,456.7
            // for 123,456.7: losing digits from the right keeps the magnitude,
            // losing them from the left changes it.
            // Deferred: `contentWidth` still measures the previous text while
            // `textChanged` is being delivered.
            function showHead(): void {
                if (!editor.activeFocus && editor.contentWidth > editor.width)
                    editor.cursorPosition = 0;
            }
            onActiveFocusChanged: Qt.callLater(editor.showHead)
            onTextChanged: Qt.callLater(editor.showHead)

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
            width: Style.stroke(Style.indicatorWidth, root)
            height: editor.cursorRectangle.height
            color: root.enabled ? Style.accent : Style.disabled(Style.accent)
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
            size: root.indicatorIconSize + 2 * glyphLayer.growth
            color: indicator.available ? Style.textMuted : Style.disabled(Style.textMuted)
        }

        StateLayer {
            id: glyphLayer
            anchors.fill: parent
            host: indicator.node
            interactive: indicator.available
            focused: false
            extent: root.indicatorIconSize
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
        focused: root.focused && !root._pointerFocus
        focusRadius: Style.radiusBody
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
