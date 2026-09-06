pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// ONE notification entry, rendered and made interactive. The card owns
// everything about how a notification LOOKS and RESPONDS; it owns no service,
// no scene, and no policy about when a notification is shown at all.
//
// `entry` is a plain data object shaped like:
//   { notificationId, appName, summary, body, urgency, actions: [{id, label}],
//     imagePath, createdAt, paused, isTransient, archivedAt, swatch }
// Every field is optional except where the card cannot degrade without it
// (`appName`, `summary`). `urgency` is "low" | "normal" | "critical". `body`
// is StyledText — the consumer is the one that sanitizes it before handing it
// here. `archivedAt` present means the entry is a closed record: the card
// shows its wall-clock time instead of a relative one and stops offering the
// action row. `swatch`, present, is a colour the icon box shows AS the icon
// instead of a fallback glyph — the card does not know or ask why.
//
// The card never mutates `entry` and never calls into anything outside
// itself: hover is reported through `hovered`, an action press through
// `actionTriggered`, a dismiss gesture through `dismissed`. What any of that
// should DO — pause an expiry timer, invoke a D-Bus action, register the
// card's rect with a fullscreen capsule — is the consumer's call, made from
// the outside.
Item {
    id: root

    required property var entry
    // Held open regardless of hover/drag — a fixed reference card, or the
    // notification centre's currently-toggled row.
    property bool alwaysExpanded: false
    property bool draggable: false
    // Vertical drag-to-expand is opt-in: a delegate inside a Flickable list
    // must not let a vertical drag double as the list's own scroll gesture.
    property bool verticalDragEnabled: false
    property bool showActions: true
    property bool showDivider: false
    // A list with its own cursor thickens this card's tick instead of
    // drawing a second mark on top of it.
    property bool selected: false
    // Which of this entry's (at most 3) actions carries keyboard focus, or
    // -1 for none. A list owns one cursor for many cards and passes it down.
    property int actionFocusIndex: -1
    // Toggled by a vertical drag past the threshold; additive to hover.
    property bool dragExpanded: false
    // Defaults from the entry shape; a consumer whose entry does not carry a
    // swatch of its own (or which decides one under a rule the card cannot
    // see — an app name, say) overrides it directly.
    property var swatch: root.entry.swatch

    readonly property bool verticalDrag: drag.active && Math.abs(drag.translation.y) > Math.abs(drag.translation.x)
    readonly property bool hovered: layer.hovered
    readonly property bool expanded: root.alwaysExpanded || root.hovered || root.dragExpanded
        || (root.entry.paused ?? false)
    readonly property bool archived: root.entry.archivedAt !== undefined
    readonly property bool hasSwatch: root.swatch !== undefined && root.swatch !== null

    signal dismissed
    signal actionTriggered(string actionId)

    readonly property string iconSource: root.entry.imagePath ?? ""
    readonly property string iconName: root.entry.urgency === "critical" ? "alert-triangle"
        : root.entry.urgency === "low" ? "moon"
        : "bell"
    readonly property color tickColor: root.entry.urgency === "critical" ? Style.danger
        : root.entry.urgency === "low" ? Style.textMuted
        : Style.accent

    // Named rather than inlined in the label's binding so it is one call
    // away from a test, the same reasoning `Style.childRadius` is a function.
    function timestampText(): string {
        if (root.archived)
            return Qt.formatDateTime(new Date(root.entry.archivedAt), "hh:mm");
        if (!root.expanded || root.entry.createdAt === undefined)
            return "";
        const seconds = Math.max(0, (Date.now() - root.entry.createdAt) / 1000);
        if (seconds < 60)
            return "just now";
        if (seconds < 3600)
            return `${Math.floor(seconds / 60)}m ago`;
        return `${Math.floor(seconds / 3600)}h ago`;
    }

    implicitWidth: Style.notificationWidth
    implicitHeight: root.expanded ? headline.height + details.implicitHeight + Style.space2
                                  : Style.notificationCollapsedHeight

    clip: true

    // A fixed reference instance (a preview, a list row re-entering from a
    // filter change) can skip the settle; a fresh arrival gets it.
    property bool animateEntrance: true
    property real entranceProgress: root.animateEntrance ? 0 : 1
    // A small settle rather than a real button press — the same idiom every
    // control's own `pressScale` uses, named as its own property rather than
    // a literal in the scale expression below (same law, `pressScale` etc.).
    property real entranceScale: 0.97
    opacity: root.entranceProgress
    scale: root.entranceScale + root.entranceProgress * (1 - root.entranceScale)
    Behavior on entranceProgress {
        NumberAnimation { duration: Motion.microPop; easing.type: Motion.emphasizedEasing }
    }
    Component.onCompleted: {
        if (root.animateEntrance)
            Qt.callLater(() => root.entranceProgress = 1);
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Motion.fast; easing.type: Motion.emphasizedEasing }
    }

    // The urgency tick doubles as the list cursor when this card sits in one:
    // always present, dimmer at rest, thickening (not brightening) on select.
    SelectionMark {
        id: tick
        anchors.left: parent.left
        anchors.leftMargin: Style.space2
        anchors.verticalCenter: headline.verticalCenter
        shown: true
        strong: root.selected
        restOpacity: 0.75
        markColor: root.tickColor
    }

    RowLayout {
        id: headline
        anchors.left: tick.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Style.space2
        anchors.rightMargin: Style.space3
        height: Style.notificationCollapsedHeight
        spacing: Style.space2

        // The app's own icon when it sent one, the swatch when the consumer
        // decided this entry carries one, else the urgency glyph — all three
        // occupy the same box so the headline never reflows on arrival.
        Item {
            implicitWidth: Style.iconSm
            implicitHeight: Style.iconSm

            Rectangle {
                anchors.fill: parent
                visible: root.hasSwatch
                radius: Style.radiusSm
                color: root.swatch ?? "transparent"
                border.width: 1
                border.color: Style.outline
            }

            Image {
                anchors.fill: parent
                visible: !root.hasSwatch && root.iconSource.length > 0
                source: root.iconSource
                asynchronous: true
                fillMode: Image.PreserveAspectFit
            }

            SvgIcon {
                anchors.fill: parent
                visible: !root.hasSwatch && root.iconSource.length === 0
                name: root.iconName
                size: Style.iconSm
            }
        }

        // A NAME, not a value — the technical face is reserved for numbers
        // and machine text.
        Prose { role: "metadata"; text: root.entry.appName }
        Prose { Layout.fillWidth: true; role: "title"; text: root.entry.summary }
    }

    ColumnLayout {
        id: details
        anchors.left: tick.right
        anchors.right: parent.right
        anchors.top: headline.bottom
        anchors.leftMargin: Style.space2
        anchors.rightMargin: Style.space3
        spacing: Style.space1
        visible: root.expanded

        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            wrapMode: Text.WordWrap
            maximumLineCount: 6
            elide: Text.ElideRight
            text: root.entry.body ?? ""
            // Already sanitized by the consumer to bare b/i/u/br.
            textFormat: Text.StyledText
            color: Style.textMuted
            font.family: Style.fontFamily
            font.pixelSize: Style.textSm
        }

        RowLayout {
            visible: root.showActions && (root.entry.actions?.length ?? 0) > 0
            spacing: Style.space3

            Repeater {
                model: (root.entry.actions ?? []).slice(0, 3)

                Text {
                    required property var modelData
                    required property int index
                    // Addressable by a consumer or a test without exposing a
                    // repeater handle from the card's own public interface.
                    objectName: "notificationAction" + index
                    text: modelData.label ?? String(modelData)
                    color: root.actionFocusIndex === index ? Style.text : Style.accent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.textSm
                    font.weight: root.actionFocusIndex === index ? Style.weightBold : Style.weightMedium
                    font.underline: root.actionFocusIndex === index

                    MouseArea {
                        anchors.fill: parent
                        // Lifts a 14px label to a 24px-tall hit target.
                        anchors.margins: -Style.notificationActionHitMargin
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.actionTriggered(parent.modelData.id)
                    }
                }
            }
        }

        Prose {
            role: "metadata"
            technical: true
            // Relative timestamp while live; archived rows show wall-clock.
            visible: text.length > 0
            text: root.timestampText()
        }
    }

    Divider {
        visible: root.showDivider
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        inset: Style.notificationDividerInset
        strength: 0.25
    }

    // Hover pauses expiry AND expands (one gesture, reported once); the
    // consumer decides what "paused" does. `target: null` because this
    // card's own response IS its height opening — scaling it too would
    // answer the same hover twice.
    StateLayer {
        id: layer
        anchors.fill: parent
        interactive: false
        target: null
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: root.dismissed()
    }

    // Swipe-dismiss: horizontal, both directions, spring-back under the
    // threshold fraction of the card's own width — works on any urgency.
    transform: Translate {
        x: drag.active && !root.verticalDrag ? drag.translation.x : 0

        Behavior on x {
            NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing }
        }
    }

    DragHandler {
        id: drag
        enabled: root.draggable
        target: null
        xAxis.enabled: true
        yAxis.enabled: root.verticalDragEnabled
        onActiveChanged: {
            if (active)
                return;
            if (Math.abs(translation.y) > Math.abs(translation.x)) {
                if (Math.abs(translation.y) > Style.notificationExpandDragPx)
                    root.dragExpanded = translation.y > 0;
            } else if (Math.abs(translation.x) > root.width * Style.notificationDismissFraction) {
                root.dismissed();
            }
        }
    }
}
