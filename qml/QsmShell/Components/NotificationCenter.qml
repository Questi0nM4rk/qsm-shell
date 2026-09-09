pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style
import "fuzzy.js" as Fuzzy

// The notification history: a search field, the full list GROUPED BY APP
// (live entries first within a group, most-recently-touched group first),
// an empty state, and DND/Clear as signals a consumer wires to whatever
// clearing or do-not-disturb means for it. Owns no service, no D-Bus, no
// notion of "live" vs "archived" beyond the two fields already documented
// on the card's entry shape (`notificationId`, `archivedAt`).
//
// `entries` is a flat array the consumer already merged (its own live list
// plus its own archive) — the centre does not know there are two sources.
ColumnLayout {
    id: root

    property var entries: []
    property bool dnd: false
    // The panel-height policy input: how tall the list may grow before it
    // scrolls. The floor (two rows' worth) is the centre's own opinion.
    property real maxListHeight: 420
    // A rule the library cannot see (an application name, say) deciding an
    // entry's card carries a colour instead of a glyph. Optional: an entry
    // that already carries its own `swatch` field needs no function here.
    property var swatchFor: null

    property string expandedKey: ""
    property int actionFocusIndex: -1
    // The cursor itself: exposed rather than only reachable by relative
    // `moveSelection` steps, so a consumer (or a test) can put it on a known
    // row directly — landing on the entry that just arrived, say.
    property alias currentIndex: historyList.currentIndex

    // What the scroll cue's fade fades TO, and it MUST come from the consumer.
    // This list draws no ground of its own: it sits on whatever surface hosts
    // it, and only the host knows what that is. Hardcoding `Style.surface`
    // here was wrong in the one place it shipped -- the panel's feed scrolls
    // directly on a shader silhouette, so the fade washed a card colour over
    // a much darker ground and read as a grey smear rather than as a fade.
    // ScrollCue's own comment says it: a gradient toward the wrong colour is
    // more visible than no gradient at all.
    property color fadeColor: Style.surface

    signal dismissRequested(var entry)
    signal actionTriggered(var entry, string actionId)
    // The card only REPORTS hover; whether that pauses anything is the
    // consumer's call (same law the card itself follows).
    signal hoverChanged(var entry, bool hovered)
    signal dndToggled
    signal clearRequested
    // The search field's own escape/selection-claim facts, forwarded — the
    // library does not know what closing a modal or claiming a keyboard
    // means. `keyPressed` is forwarded UNCONDITIONALLY and first, so a
    // consumer can claim a key (Delete, Tab) before the field decides what
    // it means; the field's own law ("keyPressed fires first, accept it to
    // take the key").
    signal escaped
    signal selectionClaimed
    signal keyPressed(var event)

    spacing: Style.space3

    function focusField(): void { searchField.forceActiveFocus(); }

    function entryKey(entry: var): string {
        return String(entry.notificationId ?? `archive-${entry.archivedAt ?? ""}-${entry.appName}-${entry.summary}`);
    }

    function selectedEntry(): var {
        return historyList.currentItem?.entry ?? null;
    }

    // The cursor follows the ENTRY, not the row number.
    //
    // `items` is recomputed from scratch whenever anything upstream moves: an
    // entry archiving, a live timer, a search keystroke. Assigning the new
    // array resets the view's numeric cursor, so acting on a row threw the
    // person somewhere else in the list -- which is the one thing a keyboard
    // list must never do, because the next keystroke then lands on a row they
    // never chose. Remembering the KEY and finding it again in the new array
    // makes the cursor mean "this notification" instead of "position 7".
    //
    // The launcher solved the same problem the same way and this list did not
    // have it yet.
    property string cursorKey: ""

    function restoreCursor(): void {
        if (root.cursorKey.length === 0)
            return;
        const at = root.items.findIndex(entry => root.entryKey(entry) === root.cursorKey);
        if (at >= 0) {
            historyList.currentIndex = at;
            return;
        }
        // The entry is gone (dismissed, cleared, filtered out). Hold the
        // position rather than jumping home: the neighbour is the nearest
        // thing to where they were.
        historyList.currentIndex = Math.max(0,
            Math.min(historyList.currentIndex, root.items.length - 1));
    }

    function clearActionFocus(): void {
        root.actionFocusIndex = -1;
    }

    function toggleSelected(): void {
        const entry = root.selectedEntry();
        if (!entry)
            return;
        const key = root.entryKey(entry);
        root.expandedKey = root.expandedKey === key ? "" : key;
        root.clearActionFocus();
    }

    function moveSelection(delta: int): void {
        root.expandedKey = "";
        root.clearActionFocus();
        if (delta < 0)
            historyList.decrementCurrentIndex();
        else
            historyList.incrementCurrentIndex();
    }

    // Dismiss the highlighted entry — reported, never performed: the
    // consumer decides what dismissing an entry does.
    function removeSelected(): void {
        const entry = root.selectedEntry();
        if (entry)
            root.dismissRequested(entry);
        root.expandedKey = "";
        root.clearActionFocus();
    }

    function moveAction(delta: int): void {
        const entry = root.selectedEntry();
        if (!entry || root.expandedKey !== root.entryKey(entry) || (entry.actions?.length ?? 0) === 0)
            return;
        const count = Math.min(3, entry.actions.length);
        root.actionFocusIndex = (root.actionFocusIndex + delta + count) % count;
    }

    function activateSelected(): void {
        const entry = root.selectedEntry();
        if (!entry)
            return;
        if (root.actionFocusIndex >= 0) {
            root.actionTriggered(entry, entry.actions[root.actionFocusIndex].id);
            root.clearActionFocus();
        } else {
            root.toggleSelected();
        }
    }

    // A plain alias, not a readonly mirror: a consumer restoring a search
    // (or a test) sets it directly instead of reaching into a private field.
    property alias query: searchField.text
    readonly property var items: {
        const all = root.entries;
        const scored = root.query.length === 0
            ? all
            : all.filter(entry => Fuzzy.score(root.query, `${entry.summary} ${entry.body}`) >= 0);
        // App groups ordered by most-recent notification: newest-first
        // within groups; the list's own section adjacency needs it sorted.
        const latestByApp = {};
        for (const entry of scored) {
            const at = entry.archivedAt ?? Number.MAX_VALUE; // live beats archived
            const app = String(entry.appName);
            latestByApp[app] = Math.max(latestByApp[app] ?? 0, at);
        }
        return scored.sort((left, right) => {
            const appLeft = String(left.appName);
            const appRight = String(right.appName);
            if (appLeft !== appRight)
                return latestByApp[appRight] - latestByApp[appLeft];

            const leftLive = left.notificationId !== undefined;
            const rightLive = right.notificationId !== undefined;
            if (leftLive !== rightLive)
                return leftLive ? -1 : 1;

            return (right.archivedAt ?? 0) - (left.archivedAt ?? 0);
        });
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.space2

        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholder: "Search notifications"
            focus: true
            leading: SvgIcon { name: "search"; size: Style.iconMd; color: Style.textMuted }
            // The host's hook first; an unclaimed Up or Down moves the
            // list under the field, which is this surface's meaning for it.
            onKeyPressed: event => {
                root.keyPressed(event);
                if (event.accepted)
                    return;
                if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                    root.selectionClaimed();
                    root.moveSelection(event.key === Qt.Key_Up ? -1 : 1);
                    event.accepted = true;
                }
            }
            onAccepted: root.activateSelected()
            onEscaped: root.escaped()
            onSelectionClaimed: root.selectionClaimed()
        }

        Capsule {
            icon: "bell"
            label: "DND"
            active: root.dnd
            onClicked: root.dndToggled()
        }

        Capsule {
            icon: "layers"
            label: "Clear"
            onClicked: root.clearRequested()
        }
    }

    // The cue is a SIBLING of the list, never a child: a Flickable's
    // declared children go into its contentItem, so they scroll with the
    // content and feed childrenRect instead of the viewport around it.
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(Style.space6 * 2,
            Math.min(root.maxListHeight, historyList.contentHeight))

        ListView {
            id: historyList
            anchors.fill: parent
            clip: true
            spacing: Style.space1
            model: root.items
            boundsBehavior: Flickable.StopAtBounds

            // Remember which entry the cursor is on, and put it back after the
            // model is replaced. `onCountChanged` rather than the root's
            // `onItemsChanged` on purpose: the restore has to run AFTER the
            // view has taken the new model, and handler order against a
            // binding re-evaluation is not something to rely on.
            onCurrentIndexChanged: {
                const entry = root.items[currentIndex];
                root.cursorKey = entry ? root.entryKey(entry) : "";
            }
            onCountChanged: root.restoreCursor()

            section.property: "appName"
            section.delegate: Prose {
                required property string section
                topPadding: Style.space2
                role: "metadata"
                text: section
            }

            delegate: NotificationCard {
                id: delegateCard
                required property var modelData
                required property int index
                width: ListView.view.width
                entry: modelData
                selected: ListView.isCurrentItem
                dragExpanded: root.expandedKey === root.entryKey(modelData)
                actionFocusIndex: ListView.isCurrentItem ? root.actionFocusIndex : -1
                animateEntrance: false
                draggable: modelData.notificationId !== undefined
                swatch: root.swatchFor ? root.swatchFor(modelData) : modelData.swatch
                onDismissed: root.dismissRequested(modelData)
                onActionTriggered: id => root.actionTriggered(modelData, id)
                onHoveredChanged: root.hoverChanged(modelData, delegateCard.hovered)

                // Pointer and keyboard drive ONE cursor here: hovering a row
                // selects it (unless the keyboard just moved and the pointer
                // did not — `Interaction.pointerSelects`, the one place that
                // fact lives), so Enter and Delete always act on the row the
                // person can see marked.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    onEntered: {
                        if (Interaction.pointerSelects)
                            historyList.currentIndex = delegateCard.index;
                    }
                    onClicked: historyList.currentIndex = delegateCard.index
                }
            }
        }

        EmptyState {
            anchors.centerIn: parent
            visible: root.items.length === 0
            title: root.query.length > 0 ? "No matches" : "Nothing here"
        }

        ScrollCue {
            view: historyList
            fadeColor: root.fadeColor
        }
    }
}
