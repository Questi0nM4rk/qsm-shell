pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml.Models

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
    // Which list shows: "unread" (entries whose `read` is false) or "all".
    // Unread is its own view, not only a dot, so what is new never hides
    // between what was seen. A host opening the menu picks the view.
    property string view: "unread"
    readonly property int unreadCount: root.entries.filter(entry => entry.read === false).length
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
    // A plain click on an unread row: the host decides what "seen" means.
    signal activated(var entry)
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

    // How far a bodied card's shadow reaches past its body.
    readonly property real shadowReach: Style.reducedEffects ? 0 : Style.cardShadowExtent

    function focusField(): void { searchField.forceActiveFocus(); }

    function entryKey(entry: var): string {
        if (entry.notificationId !== undefined) return `live-${entry.notificationId}`;
        return entry.archiveId ?? JSON.stringify([entry.archivedAt, entry.appName,
            entry.summary, entry.body, entry.urgency]);
    }

    function selectedEntry(): var {
        return root.restoringCursor ? null : historyList.currentItem?.entry ?? null;
    }

    // Selection follows identity, not the numeric position of a sorted snapshot.
    property string cursorKey: ""
    property var renderedItems: []
    property bool restoringCursor: false
    property int previousIndex: 0
    ListModel { id: historyModel; dynamicRoles: true }
    onItemsChanged: { root.restoringCursor = true; modelSync.restart(); }
    Component.onCompleted: modelSync.restart()

    Timer {
        id: modelSync
        interval: 0
        onTriggered: {
            root.previousIndex = historyList.currentIndex;
            root.restoringCursor = true;
            root.renderedItems = root.items;
            // Keep delegates alive across snapshot updates, especially hover →
            // pause. Replacing the whole array would recreate the hovered card
            // and turn that state update into a false pointer departure.
            for (let index = 0; index < root.items.length; index++) {
                const entry = root.items[index];
                const identity = root.entryKey(entry);
                let previous = -1;
                for (let at = index; at < historyModel.count; at++) {
                    if (historyModel.get(at).identity === identity) { previous = at; break; }
                }
                if (previous < 0) historyModel.insert(index,
                    { identity: identity, appName: entry.appName, record: entry });
                else {
                    if (previous !== index) historyModel.move(previous, index, 1);
                    historyModel.setProperty(index, "appName", entry.appName);
                    historyModel.setProperty(index, "record", entry);
                }
            }
            if (historyModel.count > root.items.length)
                historyModel.remove(root.items.length, historyModel.count - root.items.length);
            cursorSync.restart();
        }
    }
    Timer {
        id: cursorSync
        interval: 0
        onTriggered: {
            root.restoreCursor();
            root.restoringCursor = false;
            const entry = root.renderedItems[historyList.currentIndex];
            root.cursorKey = entry ? root.entryKey(entry) : "";
        }
    }

    function restoreCursor(): void {
        const at = root.items.findIndex(entry => root.entryKey(entry) === root.cursorKey);
        if (at >= 0) {
            historyList.currentIndex = at;
            return;
        }
        // The entry is gone (dismissed, cleared, filtered out). Hold the
        // position rather than jumping home: the neighbour is the nearest
        // thing to where they were.
        historyList.currentIndex = root.items.length === 0 ? -1 : Math.max(0,
            Math.min(root.previousIndex, root.items.length - 1));
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
        if (root.restoringCursor) return;
        historyList.currentItem?.dismiss();
        root.expandedKey = "";
        root.clearActionFocus();
    }

    function moveAction(delta: int): void {
        const card = historyList.currentItem;
        if (!card || root.expandedKey !== root.entryKey(card.entry))
            return;
        const available = card.actions.filter(action => action.index !== undefined && action.enabled);
        if (available.length === 0) {
            root.clearActionFocus();
            return;
        }
        const at = available.findIndex(action => action.index === root.actionFocusIndex);
        const next = at < 0 ? (delta < 0 ? available.length - 1 : 0)
            : (at + delta + available.length) % available.length;
        root.actionFocusIndex = available[next].index;
    }

    function activateSelected(): void {
        if (root.restoringCursor) return;
        const card = historyList.currentItem;
        if (!card)
            return;
        if (root.actionFocusIndex >= 0) {
            const action = card.actions.find(action => action.index === root.actionFocusIndex);
            if (action)
                card.activateAction(String(action.entryAction.id));
            root.clearActionFocus();
        } else {
            root.toggleSelected();
        }
    }

    // A plain alias, not a readonly mirror: a consumer restoring a search
    // (or a test) sets it directly instead of reaching into a private field.
    property alias query: searchField.text
    readonly property Item searchTarget: searchField
    readonly property var items: {
        const all = root.view === "unread"
            ? root.entries.filter(entry => entry.read === false)
            : root.entries.slice();
        const scored = root.query.length === 0
            ? all
            : all.filter(entry => Fuzzy.score(root.query, `${entry.appName} ${entry.summary} ${entry.body}`) >= 0);
        // App groups ordered by most-recent notification: newest-first
        // within groups; the list's own section adjacency needs it sorted.
        const groups = new Map();
        for (const entry of scored) {
            const app = String(entry.appName);
            const group = groups.get(app) ?? { live: false, latest: 0, order: groups.size };
            group.live = group.live || entry.notificationId !== undefined;
            group.latest = Math.max(group.latest, entry.archivedAt ?? entry.createdAt ?? 0);
            groups.set(app, group);
        }
        return scored.sort((left, right) => {
            const appLeft = String(left.appName);
            const appRight = String(right.appName);
            if (appLeft !== appRight) {
                const leftGroup = groups.get(appLeft);
                const rightGroup = groups.get(appRight);
                return Number(rightGroup.live) - Number(leftGroup.live)
                    || rightGroup.latest - leftGroup.latest || leftGroup.order - rightGroup.order;
            }

            const leftLive = left.notificationId !== undefined;
            const rightLive = right.notificationId !== undefined;
            if (leftLive !== rightLive)
                return leftLive ? -1 : 1;

            return (right.archivedAt ?? right.createdAt ?? 0)
                - (left.archivedAt ?? left.createdAt ?? 0);
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

        // Icon-only, so the field keeps the width its placeholder needs; the
        // names are the accessible labels. A square of the field's own height.
        IconButton {
            icon: "moon"
            accessibleName: "Do not disturb"
            color: root.dnd ? Style.accent : Style.text
            padding: (Style.controlHeight - Style.iconMd) / 2
            Accessible.checkable: true
            Accessible.checked: root.dnd
            onClicked: root.dndToggled()
        }

        IconButton {
            icon: "trash-2"
            accessibleName: "Clear history"
            padding: (Style.controlHeight - Style.iconMd) / 2
            onClicked: root.clearRequested()
        }
    }

    Segmented {
        id: viewBar
        Layout.fillWidth: true
        options: [
            { label: "Unread", badge: root.unreadCount > 0 ? String(root.unreadCount) : "" },
            { label: "All" }
        ]
        currentIndex: root.view === "unread" ? 0 : 1
        Accessible.name: "Notification views"
        onSelected: index => {
            root.view = index === 0 ? "unread" : "all";
            root.expandedKey = "";
            root.clearActionFocus();
        }
    }

    // The cue is a SIBLING of the list, never a child: a Flickable's
    // declared children go into its contentItem, so they scroll with the
    // content and feed childrenRect instead of the viewport around it.
    // Fills what the host gives: a list that shrank to its content let the
    // column re-centre the header, so emptying the list jumped the whole
    // menu to the middle of the screen.
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: Math.max(Style.space6 * 2,
            Math.min(root.maxListHeight, historyList.contentHeight))

        ListView {
            id: historyList
            anchors.fill: parent
            // The viewport reaches past the cards on both sides by the
            // shadow's extent and the cards sit inside it, so the shadow is
            // clipped by the list's edge only where the list itself ends.
            anchors.leftMargin: -root.shadowReach
            anchors.rightMargin: -root.shadowReach
            // A ListView places every delegate at x 0, so the cards are moved
            // in by the content margins, never by their own x.
            leftMargin: root.shadowReach
            rightMargin: root.shadowReach
            clip: true
            spacing: Style.space2
            model: historyModel
            boundsBehavior: Flickable.StopAtBounds

            // Model replacement temporarily resets the numeric cursor; only
            // user navigation updates the stable identity during that handoff.
            onCurrentIndexChanged: {
                if (root.restoringCursor) return;
                const entry = root.renderedItems[currentIndex];
                root.cursorKey = entry ? root.entryKey(entry) : "";
            }

            section.property: "appName"
            section.delegate: Prose {
                required property string section
                // The card's own text column: past its cursor, gap and glyph.
                leftPadding: Style.space2 + Style.markThickness + Style.spaceTight
                    + Style.space2 + Style.iconSm + Style.space2
                topPadding: Style.space2
                role: "section"
                text: section
            }

            delegate: NotificationCard {
                id: delegateCard
                required property var record
                readonly property var modelData: record
                required property int index
                width: ListView.view.width - root.shadowReach * 2
                entry: modelData
                selected: ListView.isCurrentItem
                dragExpanded: root.expandedKey === root.entryKey(modelData)
                actionFocusIndex: ListView.isCurrentItem ? root.actionFocusIndex : -1
                animateEntrance: false
                bodied: true
                expandOnHover: false
                onExpandRequested: {
                    const key = root.entryKey(modelData);
                    root.expandedKey = root.expandedKey === key ? "" : key;
                    root.clearActionFocus();
                }
                draggable: modelData.notificationId !== undefined
                swatch: root.swatchFor ? root.swatchFor(modelData) : modelData.swatch
                unread: modelData.read === false
                activatable: modelData.read === false
                onActivated: root.activated(modelData)
                onDismissed: root.dismissRequested(modelData)
                onActionTriggered: id => root.actionTriggered(modelData, id)
                onHoveredChanged: {
                    root.hoverChanged(modelData, delegateCard.hovered);
                    if (delegateCard.hovered && Interaction.pointerSelects)
                        historyList.currentIndex = delegateCard.index;
                }
            }
        }

        EmptyState {
            anchors.centerIn: parent
            visible: root.items.length === 0
            icon: "bell"
            title: root.query.length > 0 ? "No matches"
                : root.view === "unread" ? "All caught up" : "Nothing here"
            detail: root.query.length > 0 ? "Try another search"
                : root.view === "unread" ? "New notifications appear here" : "History is empty"
        }

        ScrollCue {
            view: historyList
            fadeColor: root.fadeColor
        }
    }
}
