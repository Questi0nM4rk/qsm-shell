pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import qs.QsmShell.Style

// One of N, with every option visible. T.TabBar owns the native tab model,
// focus and accessibility contract; this type supplies the library's fixed
// proportions, states, and host-owned selection report.
T.TabBar {
    id: root

    required property var options
    property string size: "md"
    // Opt-in Tab/Shift+Tab selection for a host that owns one tab GROUP
    // (owner panel contract). The default stays the conventional single tab
    // stop; arrows, Home/End and the actions are unchanged either way.
    property bool tabNavigation: false
    // Ends are visible landmarks: a group that must stop there sets false.
    property bool wrapNavigation: true
    property real barHeight: Style.size("Segmented", root.size)
    readonly property real _s: root.barHeight / Style.size("Segmented", "md")
    readonly property real sizeScale: root._s
    readonly property int _textSize: Style.textNear(Style.textSm * root._s)
    readonly property int _iconSize: Style.iconNear(Style.iconSm * root._s)
    readonly property int _inset: Style.rhythm(Style.space2 * root._s)
    readonly property int _gap: Style.rhythm(Style.space1 * root._s)
    readonly property int _radius: Style.radiusSm
    readonly property bool focused: root.activeFocus || root.currentItem?.activeFocus === true

    signal selected(int index)

    activeFocusOnTab: root.enabled
    hoverEnabled: root.enabled
    implicitWidth: Style.controlWidth
    implicitHeight: root.barHeight
    Accessible.role: Accessible.PageTabList

    function _at(index: int): var {
        const option = root.options[index];
        return option === undefined ? null : option;
    }

    function _labelOf(option: var): string {
        return typeof option === "string" ? option : String(option?.label ?? "");
    }

    function _enabled(index: int): bool {
        const option = root._at(index);
        return option !== null && (typeof option === "string" || option.disabled !== true);
    }

    function _firstEnabled(): int {
        for (let i = 0; i < root.options.length; i++) {
            if (root._enabled(i))
                return i;
        }
        return -1;
    }

    function _lastEnabled(): int {
        for (let i = root.options.length - 1; i >= 0; i--) {
            if (root._enabled(i))
                return i;
        }
        return -1;
    }

    // TabBar's C++ setter preserves a host binding. Reporting is deliberately
    // here, rather than on currentIndexChanged: host synchronization is state,
    // not intent.
    function select(index: int): bool {
        if (!root.enabled || !root._enabled(index) || root.currentIndex === index)
            return false;
        root.setCurrentIndex(index);
        root.selected(index);
        return true;
    }

    function step(delta: int): bool {
        const count = root.options.length;
        if (!root.enabled || count === 0 || delta === 0)
            return false;
        let index = root.currentIndex;
        for (let tried = 0; tried < count; tried++) {
            const next = index + delta;
            if (root.wrapNavigation) index = (next + count) % count;
            else if (next < 0 || next >= count) return false;
            else index = next;
            if (root._enabled(index))
                return root.select(index);
        }
        return false;
    }

    function first(): bool { return root.select(root._firstEnabled()); }
    function last(): bool { return root.select(root._lastEnabled()); }

    // One handler for the bar and its buttons, so a key means the same thing
// wherever focus landed inside the group.
    function handleKey(event): void {
        if (!root.enabled)
            return;
        if (root.tabNavigation && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)
                && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
            root.step(event.key === Qt.Key_Backtab || event.modifiers === Qt.ShiftModifier ? -1 : 1);
            root.forceActiveFocus();
            event.accepted = true;
            return;
        }
        if (event.modifiers !== Qt.NoModifier)
            return;
        const forward = root.mirrored ? Qt.Key_Left : Qt.Key_Right;
        if (event.key === forward || event.key === (forward === Qt.Key_Right ? Qt.Key_Left : Qt.Key_Right)) {
            root.step(event.key === forward ? 1 : -1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Home) {
            root.first();
            event.accepted = true;
        } else if (event.key === Qt.Key_End) {
            root.last();
            event.accepted = true;
        }
    }

    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => root.handleKey(event)

    readonly property list<T.Action> actions: [
        T.Action { text: "Previous"; enabled: root.enabled; onTriggered: root.step(-1) },
        T.Action { text: "Next"; enabled: root.enabled; onTriggered: root.step(1) },
        T.Action { text: "First"; enabled: root.enabled; onTriggered: root.first() },
        T.Action { text: "Last"; enabled: root.enabled; onTriggered: root.last() }
    ]

    background: Surface {
        objectName: "segmentedSurface"
        enabled: root.enabled
        radius: root._radius
        hovered: root.hovered
    }

    contentItem: ListView {
        id: tabs
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: 0
        interactive: false
        clip: false
        model: root.contentModel
        currentIndex: root.currentIndex
    }

    Repeater {
        model: root.options
        delegate: Segment {}
    }

    component Segment: T.TabButton {
        id: tab
        required property var modelData
        required property int index

        readonly property bool available: root._enabled(tab.index)
        readonly property bool selectedSegment: root.currentIndex === tab.index
        readonly property var option: root._at(tab.index)
        objectName: "segmentedTab" + tab.index
        implicitWidth: root.width / Math.max(1, root.options.length)
        implicitHeight: root.barHeight
        width: implicitWidth
        height: root.barHeight
        enabled: root.enabled && tab.available
        checkable: false
        hoverEnabled: enabled
        activeFocusOnTab: false
        Accessible.role: Accessible.PageTab
        Accessible.name: root._labelOf(tab.modelData)
        Accessible.selected: tab.selectedSegment
        onClicked: root.select(tab.index)
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: event => root.handleKey(event)

        background: Rectangle {
            anchors.fill: parent
            radius: root._radius
            color: Style.tone("transparent", tab.hovered, tab.pressed,
                tab.selectedSegment, tab.enabled, Style.accent)
        }

        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root._inset
            anchors.rightMargin: root._inset
            spacing: root._gap

            SvgIcon {
                visible: name.length > 0
                name: typeof tab.modelData === "string" ? "" : String(tab.modelData?.icon ?? "")
                size: root._iconSize
                color: tab.enabled
                    ? (tab.selectedSegment ? Style.accent : Style.textMuted)
                    : Style.disabled(tab.selectedSegment ? Style.accent : Style.textMuted)
                Layout.alignment: Qt.AlignVCenter
            }
            Prose {
                role: "label"
                text: root._labelOf(tab.modelData)
                color: tab.enabled
                    ? (tab.selectedSegment ? Style.accent : Style.textMuted)
                    : Style.disabled(tab.selectedSegment ? Style.accent : Style.textMuted)
                font.pixelSize: root._textSize
                font.weight: tab.selectedSegment ? Style.weightBold : Style.weightMedium
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }
            Badge {
                visible: text.length > 0
                tone: tab.selectedSegment ? "accent" : "neutral"
                text: typeof tab.modelData === "string" ? "" : String(tab.modelData?.badge ?? "")
                Layout.alignment: Qt.AlignVCenter
            }
        }

        StateLayer {
            anchors.fill: parent
            host: tab
            target: null
            hoverScale: 1
            pressScale: 0.98
            focusRadius: root._radius
            focused: tab.selectedSegment && root.focused
        }
    }
}
