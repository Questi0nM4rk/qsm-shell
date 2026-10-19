pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
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
    // The header row's one control radius: the search field shares it.
    readonly property int _radius: Style.radiusMd
    // The items levitate on the rounded track: an inset all round and a gap
    // between neighbours, each item a pill concentric with the track's
    // corners (owner 2026-10-19), so no highlight can stop short of a corner.
    readonly property int _pad: Style.rhythm(Style.space1 * root._s)
    readonly property int _itemRadius: Math.max(0, root._radius - root._pad)
    readonly property real _segmentWidth: (root.width - root._pad * 2
        - root._gap * Math.max(0, root.options.length - 1)) / Math.max(1, root.options.length)
    readonly property bool focused: root.activeFocus || root.currentItem?.activeFocus === true

    signal selected(int index)

    activeFocusOnTab: root.enabled
    hoverEnabled: root.enabled
    implicitWidth: Style.controlWidth
    implicitHeight: root.barHeight
    Accessible.role: Accessible.PageTabList

    // Every reader of an option goes through here, so a host that rebuilds
    // `options` (a label that carries a count) updates the segments in place.
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

    // TabBar's C++ setter preserves a host binding, but the container also
    // rewrites currentIndex itself whenever an item is removed or added. A
    // Repeater over `options` destroys every segment when the array is
    // replaced, the container resets the index, and the host's binding (whose
    // inputs did not change) is never re-evaluated: the thumb stayed on a
    // stale index. The Repeater below is therefore keyed on the COUNT, so a
    // rebuilt array of the same length touches no segment.
    // Reporting is deliberately
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

        // One picked-segment pill that glides between segments, so the
        // choice reads as a thing that moved rather than a box that blinked.
        Rectangle {
            objectName: "segmentedThumb"
            visible: root.currentIndex >= 0
            x: root._pad + root.currentIndex * (root._segmentWidth + root._gap)
            y: root._pad
            width: root._segmentWidth
            height: root.barHeight - root._pad * 2
            radius: root._itemRadius
            // The picked segment is identity: the accent over the track,
            // opaque, lifted off it by the card's slight shadow.
            color: root.enabled ? Style.selected(Style.surface, Style.accent)
                : Style.disabled(Style.selected(Style.surface, Style.accent))
            layer.enabled: !Style.reducedEffects
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Style.shadow
                shadowOpacity: Style.cardShadowOpacity
                shadowBlur: Style.cardShadowBlur
                shadowVerticalOffset: Style.cardShadowOffset
                blurMax: Style.cardShadowExtent
            }

            Behavior on x {
                enabled: !Style.reducedMotion
                NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing }
            }
        }
    }

    contentItem: ListView {
        id: tabs
        anchors.fill: parent
        anchors.margins: root._pad
        orientation: ListView.Horizontal
        spacing: root._gap
        interactive: false
        clip: false
        model: root.contentModel
        currentIndex: root.currentIndex
    }

    Repeater {
        model: root.options.length
        delegate: Segment {}
    }

    component Segment: T.TabButton {
        id: tab
        required property int index

        readonly property bool available: root._enabled(tab.index)
        readonly property bool selectedSegment: root.currentIndex === tab.index
        readonly property var option: root._at(tab.index)
        readonly property string labelText: root._labelOf(tab.option)
        readonly property bool iconOnly: tab.labelText.length === 0
            && String(tab.option?.icon ?? "").length > 0
        objectName: "segmentedTab" + tab.index
        implicitWidth: root._segmentWidth
        implicitHeight: root.barHeight - root._pad * 2
        width: implicitWidth
        height: implicitHeight
        enabled: root.enabled && tab.available
        checkable: false
        hoverEnabled: enabled
        activeFocusOnTab: false
        Accessible.role: Accessible.PageTab
        // An icon-only option has no label; `name` then speaks for it.
        Accessible.name: tab.labelText || String(tab.option?.name ?? "")
        Accessible.selected: tab.selectedSegment
        onClicked: root.select(tab.index)
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: event => root.handleKey(event)

        // An item's own pill: empty at rest, a lift under the pointer and a
        // deeper step under a press. The picked item shows the sliding
        // thumb behind it instead, so it paints nothing of its own.
        background: Rectangle {
            radius: root._itemRadius
            color: tab.selectedSegment ? "transparent"
                : Style.tone("transparent", tab.hovered, tab.pressed, false, tab.enabled, Style.accent)

            Behavior on color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }
        }

        // The glyph and label group sits centred and takes only its own
        // width; it shrinks (and the label elides) only when the segment is
        // narrower. Two stretching spacers beside a stretching label split
        // the room three ways and elided labels that had space.
        contentItem: Item {
            RowLayout {
                anchors.centerIn: parent
                width: Math.min(implicitWidth, parent.width - root._inset * 2)
                spacing: root._gap

                SvgIcon {
                    visible: name.length > 0
                    name: typeof tab.option === "string" ? "" : String(tab.option?.icon ?? "")
                    size: root._iconSize
                    color: tab.enabled
                        ? (tab.selectedSegment ? Style.accent : tab.hovered ? Style.text : Style.textMuted)
                        : Style.disabled(tab.selectedSegment ? Style.accent : Style.textMuted)
                    Layout.alignment: Qt.AlignVCenter
                }
                Prose {
                    visible: !tab.iconOnly
                    role: "label"
                    text: tab.labelText
                    color: tab.enabled
                        ? (tab.selectedSegment ? Style.accent : tab.hovered ? Style.text : Style.textMuted)
                        : Style.disabled(tab.selectedSegment ? Style.accent : Style.textMuted)
                    font.pixelSize: root._textSize
                    font.weight: tab.selectedSegment ? Style.weightBold : Style.weightMedium
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.fillWidth: true
                    // Text measures in fractions and a layout hands out whole
                    // pixels: ceil, or a label that fits elides by a hair.
                    Layout.preferredWidth: Math.ceil(implicitWidth)
                    Layout.maximumWidth: Math.ceil(implicitWidth)
                    Layout.alignment: Qt.AlignVCenter
                }
                Badge {
                    visible: text.length > 0
                    tone: tab.selectedSegment ? "accent" : "neutral"
                    text: typeof tab.option === "string" ? "" : String(tab.option?.badge ?? "")
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        StateLayer {
            anchors.fill: parent
            host: tab
            // Hover lifts the item a little; a press only changes its colour
            // and never its size. The picked item does not grow: its thumb
            // lives on the track and would be left behind.
            target: tab
            hoverScale: tab.selectedSegment ? 1 : Motion.capsuleHoverScale
            pressScale: 1
            focusRadius: root._itemRadius
            // The ring marks keyboard focus only: a click selects and slides
            // the thumb, it does not ring (owner 2026-10-19).
            focused: tab.selectedSegment && (root.visualFocus || tab.visualFocus)
        }
    }
}
