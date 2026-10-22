pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import qs.QsmShell.Style

// One exclusive choice made of `Radio` children. The group is the keyboard and
// screen-reader half of it: one Tab stop for the whole group (the checked
// radio, else the first available one), arrows that move focus AND select,
// Home and End. The host still owns the value: `currentIndex` goes in, and
// `selected(index)` reports intent; the group never writes it. The group does
// set each child's `checked` from `currentIndex`, so a child inside it carries
// no `checked` binding of its own.
//
//     RadioGroup {
//         label: "Scale"; currentIndex: root.scale
//         onSelected: index => root.scale = index
//         Radio { Prose { text: "Fit" } }
//         Radio { Prose { text: "Fill" } }
//     }
T.Control {
    id: root

    property string label: ""
    // The index of the checked child, -1 for none. Host-owned.
    property int currentIndex: -1
    // Ends are visible landmarks: a group that must stop there sets false.
    property bool wrapNavigation: true
    property real optionSpacing: Style.space2
    default property alias content: options.data

    signal selected(int index)

    property var radios: []
    property var _wired: []

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight
    padding: 0
    focusPolicy: Qt.NoFocus

    Accessible.role: Accessible.Grouping
    Accessible.name: root.label
    // The screen reader hears the group's label, then the checked option.
    Accessible.description: root.radios[root.currentIndex]?.Accessible.name ?? ""

    function _isAvailable(index: int): bool {
        const radio = root.radios[index];
        return root.enabled && radio !== undefined && radio.enabled;
    }

    function _firstAvailable(): int {
        for (let i = 0; i < root.radios.length; i++) {
            if (root._isAvailable(i))
                return i;
        }
        return -1;
    }

    function _lastAvailable(): int {
        for (let i = root.radios.length - 1; i >= 0; i--) {
            if (root._isAvailable(i))
                return i;
        }
        return -1;
    }

    // The radio that holds the group's one Tab stop.
    function _tabStop(): int {
        return root._isAvailable(root.currentIndex) ? root.currentIndex : root._firstAvailable();
    }

    function _focusedIndex(): int {
        for (let i = 0; i < root.radios.length; i++) {
            if (root.radios[i].activeFocus)
                return i;
        }
        return -1;
    }

    // Reads the children and gives them the group's state. Runs when a child
    // arrives, becomes (un)available, or the host moves `currentIndex`.
    function _sync(): void {
        const found = [];
        for (let i = 0; i < options.children.length; i++) {
            const child = options.children[i];
            if (typeof child.select === "function" && child.selectionRequested !== undefined)
                found.push(child);
        }
        root.radios = found;
        const stop = root._tabStop();
        for (let i = 0; i < found.length; i++) {
            const radio = found[i];
            if (!root._wired.includes(radio)) {
                root._wired.push(radio);
                radio.selectionRequested.connect(() => root.selected(root.radios.indexOf(radio)));
                radio.enabledChanged.connect(() => Qt.callLater(root._sync));
            }
            radio.checked = i === root.currentIndex;
            radio.activeFocusOnTab = i === stop;
        }
    }

    onCurrentIndexChanged: root._sync()
    onEnabledChanged: root._sync()
    Component.onCompleted: Qt.callLater(root._sync)

    // Every route to a choice is this call: the radio refuses an unavailable
    // or already checked option, and answers with its own `selectionRequested`.
    function select(index: int): bool {
        if (!root._isAvailable(index) || index === root.currentIndex)
            return false;
        root.radios[index].select();
        return true;
    }

    // Moves focus and selection together to the next available option.
    function step(delta: int): bool {
        const count = root.radios.length;
        if (!root.enabled || count === 0 || delta === 0)
            return false;
        const at = root._focusedIndex();
        let index = at >= 0 ? at : root.currentIndex;
        if (index < 0)
            index = delta > 0 ? -1 : count;
        for (let tried = 0; tried < count; tried++) {
            const next = index + delta;
            if (root.wrapNavigation) index = (next + count) % count;
            else if (next < 0 || next >= count) return false;
            else index = next;
            if (root._isAvailable(index))
                return root._go(index);
        }
        return false;
    }

    function first(): bool { return root._go(root._firstAvailable()); }
    function last(): bool { return root._go(root._lastAvailable()); }

    function _go(index: int): bool {
        if (index < 0)
            return false;
        root.radios[index].forceActiveFocus(Qt.TabFocusReason);
        root.select(index);
        return true;
    }

    // The radios do not take arrows, so a key pressed on any of them lands here.
    Keys.onPressed: event => {
        if (!root.enabled || event.modifiers !== Qt.NoModifier)
            return;
        const forward = root.mirrored ? Qt.Key_Left : Qt.Key_Right;
        const back = root.mirrored ? Qt.Key_Right : Qt.Key_Left;
        if (event.key === forward || event.key === Qt.Key_Down)
            event.accepted = root.step(1);
        else if (event.key === back || event.key === Qt.Key_Up)
            event.accepted = root.step(-1);
        else if (event.key === Qt.Key_Home)
            event.accepted = root.first();
        else if (event.key === Qt.Key_End)
            event.accepted = root.last();
    }

    readonly property list<T.Action> actions: [
        T.Action { text: "Previous"; enabled: root.enabled; onTriggered: root.step(-1) },
        T.Action { text: "Next"; enabled: root.enabled; onTriggered: root.step(1) },
        T.Action { text: "First"; enabled: root.enabled; onTriggered: root.first() },
        T.Action { text: "Last"; enabled: root.enabled; onTriggered: root.last() }
    ]

    contentItem: ColumnLayout {
        id: column
        spacing: Style.space2

        // The group carries the name, so a screen reader does not meet it twice.
        ControlLabel {
            Accessible.ignored: true
            text: root.label
        }
        ColumnLayout {
            id: options
            spacing: root.optionSpacing
            Layout.fillWidth: true
            onChildrenChanged: Qt.callLater(root._sync)
        }
    }
}
