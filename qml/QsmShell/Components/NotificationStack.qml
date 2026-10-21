pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Style

// A presentation of the host's capped, newest-first notification window.
// Rows are reconciled by identity so changing a value never replaces the
// delegate which owns hover, expansion and gesture state.
Item {
    id: root

    property var stack: []
    property var isAlive: null
    property var swatchFor: null
    // The host binds this to the lifetime of its visible rollout.
    property bool retainWhenEmpty: false
    // Bind to the host's open intent, not its eventual visibility endpoint.
    property bool inputEnabled: true
    // Row material, forwarded to every NotificationCard without a styling
    // policy of its own: bodied cards on `surface`, their radius, and the
    // gap between rows. The gap is part of the column AND of the eviction
    // extent, so a departing row takes its gap with it and the survivors
    // land exactly where the shift stops.
    property bool bodied: false
    property real bodyRadius: Style.radiusBody
    property real rowSpacing: 0

    signal dismissRequested(var entry)
    signal hoverChanged(var entry, bool hovered)
    signal primaryActionRequested(var entry)
    signal geometryChanged()

    ListModel {
        id: rows
        dynamicRoles: true
    }

    function idKey(id: var): string {
        return typeof id + ":" + String(id);
    }

    function copyValue(value: var): var {
        if (value === null || value === undefined || typeof value !== "object")
            return value;
        if (value instanceof Date)
            return value.getTime();
        if (Array.isArray(value))
            return value.map(item => root.copyValue(item));
        const copy = ({});
        for (const key of Object.keys(value)) {
            const item = value[key];
            if (typeof item !== "function")
                copy[key] = root.copyValue(item);
        }
        return copy;
    }

    function snapshotOf(entry: var): var {
        if (!entry || (typeof entry.notificationId !== "string" && typeof entry.notificationId !== "number")
                || String(entry.notificationId).length === 0
                || typeof entry.appName !== "string" || typeof entry.summary !== "string")
            return null;
        const snapshot = {
            notificationId: entry.notificationId,
            appName: entry.appName,
            summary: entry.summary,
            paused: false
        };
        // These are the complete NotificationCard data fields; optional values
        // stay absent rather than becoming undefined-valued render properties.
        for (const key of ["body", "urgency", "imagePath", "actions", "createdAt",
                           "archivedAt", "isTransient", "swatch", "paused"]) {
            if (entry[key] !== undefined)
                snapshot[key] = key === "swatch" ? String(entry[key]) : root.copyValue(entry[key]);
        }
        return snapshot;
    }

    function indexFor(id: var): int {
        const key = root.idKey(id);
        for (let i = 0; i < rows.count; i++) {
            if (rows.get(i).key === key)
                return i;
        }
        return -1;
    }

    // A host reaches a card for native input and fullscreen-mask inspection
    // without reaching into the Repeater.
    function targetForNotification(id: var): var {
        const index = root.indexFor(id);
        return index >= 0 ? cardRepeater.itemAt(index) : null;
    }

    property var displayStack: []
    property var evicting: []
    function refreshViews(): void {
        const visible = [];
        const departed = [];
        for (let i = 0; i < rows.count; i++) {
            const row = rows.get(i);
            if (row.phase === "active" || row.phase === "retained")
                visible.push(row.payload);
            if (row.phase === "evicting")
                departed.push(row.payload);
        }
        root.displayStack = visible;
        root.evicting = departed;
    }
    property real evictShift: 0
    readonly property real evictHeight: {
        let height = 0;
        for (let i = 0; i < cardRepeater.count; i++) {
            const card = cardRepeater.itemAt(i);
            if (card && card.phase === "evicting")
                height += card.height + root.rowSpacing;
        }
        return height;
    }
    property bool finishingEviction: false
    // A departure stopped mid-slide because the window emptied and the host
    // is retaining the last body. The shift is held at its current offset
    // rather than animating, so the retained extent does not keep shrinking.
    property bool retainingEviction: false
    property bool layoutReady: false
    readonly property bool rowHeightsAnimating: {
        for (let i = 0; i < cardRepeater.count; i++) {
            const card = cardRepeater.itemAt(i);
            // A frozen row holds its painted height and its stopped entrance,
            // so its stalled progress is deliberate, not a live height pulse.
            if (card && !card.expansionFrozen
                    && (card.expansionAnimating || card.entranceProgress < 1))
                return true;
        }
        return false;
    }
    property var previousVisible: []

    function syncLayout(): void {
        if (root.layoutReady)
            column.forceLayout();
        root.geometryChanged();
    }

    function reconcile(): void {
        const previousEvicting = root.evicting.map(item => root.idKey(item.notificationId));
        const snapshots = [];
        for (const source of root.stack) {
            const snapshot = root.snapshotOf(source);
            if (snapshot)
                snapshots.push(snapshot);
        }

        if (snapshots.length === 0) {
            if (root.retainWhenEmpty && root.displayStack.length > 0) {
                for (let i = 0; i < rows.count; i++) {
                    const row = rows.get(i);
                    if (row.phase === "active") {
                        const card = cardRepeater.itemAt(i);
                        if (card)
                            card.freezePresentation();
                        rows.setProperty(i, "phase", "retained");
                        rows.setProperty(i, "inputEligible", false);
                    }
                }
                root.refreshViews();
                root.holdEviction();
            } else {
                root.clearPresentation();
            }
            root.previousVisible = [];
            root.geometryChanged();
            return;
        }

        // A host arrival during retract revives the exact delegates before any
        // obsolete cleanup can run. Same-ID rows only receive a new value.
        root.releaseEvictionHold();
        const activeKeys = new Set();
        for (const payload of snapshots) {
            const key = root.idKey(payload.notificationId);
            activeKeys.add(key);
            let index = root.indexFor(payload.notificationId);
            if (index < 0) {
                rows.append({ key, idValue: payload.notificationId, payload,
                    phase: "active", inputEligible: true, animate: true });
            } else {
                rows.setProperty(index, "payload", payload);
                rows.setProperty(index, "phase", "active");
                rows.setProperty(index, "inputEligible", true);
                rows.setProperty(index, "animate", false);
                const card = cardRepeater.itemAt(index);
                if (card) {
                    if (root.inputEnabled)
                        card.releasePresentation();
                    else
                        card.freezePresentation();
                }
            }
        }

        const windowKeys = new Set(snapshots.map(item => root.idKey(item.notificationId)));
        const previouslyVisible = root.previousVisible;
        const pushedOut = previouslyVisible.filter(item => {
            const key = root.idKey(item.notificationId);
            return !windowKeys.has(key) && (root.isAlive?.(item.notificationId) ?? false);
        });

        // Drop rows that are no longer in either the window or its legitimate
        // overflow departure. A source object is never held past this copy.
        for (let i = rows.count - 1; i >= 0; i--) {
            const row = rows.get(i);
            if (activeKeys.has(row.key))
                continue;
            if (row.phase === "evicting")
                continue;
            if (row.phase === "active" || row.phase === "retained") {
                const shouldEvict = pushedOut.some(item => root.idKey(item.notificationId) === row.key);
                if (shouldEvict) {
                    const card = cardRepeater.itemAt(i);
                    if (card)
                        card.freezePresentation();
                    rows.setProperty(i, "phase", "evicting");
                    rows.setProperty(i, "inputEligible", false);
                } else {
                    const card = cardRepeater.itemAt(i);
                    if (card)
                        card.releaseHover();
                    rows.remove(i);
                }
            }
        }

        // Match the host's window exactly: oldest first, with overflow rows
        // preceding it. ListModel moves preserve the row's delegate identity.
        const desired = [];
        for (let i = 0; i < rows.count; i++)
            if (rows.get(i).phase === "evicting") desired.push(rows.get(i).key);
        for (let i = snapshots.length - 1; i >= 0; i--)
            desired.push(root.idKey(snapshots[i].notificationId));
        for (let target = 0; target < desired.length; target++) {
            let source = -1;
            for (let i = target; i < rows.count; i++) {
                if (rows.get(i).key === desired[target]) {
                    source = i;
                    break;
                }
            }
            if (source >= 0 && source !== target)
                rows.move(source, target, 1);
        }

        root.refreshViews();
        root.previousVisible = snapshots;
        const nextEvicting = root.evicting.map(item => root.idKey(item.notificationId));
        const evictionChanged = previousEvicting.length !== nextEvicting.length
            || previousEvicting.some(key => !nextEvicting.includes(key));
        if (evictionChanged || pushedOut.length > 0)
            root.retargetEviction();
        root.geometryChanged();
    }

    function retargetEviction(): void {
        if (root.evicting.length === 0 && !evictAnim.running && root.evictShift === 0)
            return;
        const current = root.evictShift;
        evictAnim.stop();
        evictAnim.from = current;
        evictAnim.to = -root.evictHeight;
        evictAnim.start();
    }

    // Retention owns the last body until the host reports genuinely hidden, so a
    // departure caught mid-slide stops where it is instead of animating the
    // retained extent smaller. The evicting rows stay in the column at their
    // frozen heights, which is the paint the owner last saw.
    function holdEviction(): void {
        if (root.evicting.length === 0)
            return;
        evictAnim.stop();
        root.retainingEviction = true;
    }

    // An arrival during retract releases the hold and resumes any departure
    // still owed, so a retained viewport cannot outlive a live window and no
    // stale completion can remove a freshly arrived row.
    function releaseEvictionHold(): void {
        if (!root.retainingEviction)
            return;
        root.retainingEviction = false;
        root.retargetEviction();
    }

    function finishEviction(): void {
        root.finishingEviction = true;
        for (let i = rows.count - 1; i >= 0; i--)
            if (rows.get(i).phase === "evicting")
                rows.remove(i);
        // Their new y coordinates replace the completed column translation.
        root.syncLayout();
        root.refreshViews();
        root.evictShift = 0;
        root.finishingEviction = false;
        root.geometryChanged();
    }

    function clearPresentation(): void {
        for (let i = 0; i < cardRepeater.count; i++) {
            const card = cardRepeater.itemAt(i);
            if (card)
                card.releaseHover();
        }
        evictAnim.stop();
        rows.clear();
        root.displayStack = [];
        root.evicting = [];
        root.evictShift = 0;
        root.retainingEviction = false;
    }

    onStackChanged: root.reconcile()
    onRetainWhenEmptyChanged: if (!retainWhenEmpty && stack.length === 0) root.clearPresentation()
    onInputEnabledChanged: {
        for (let i = 0; i < cardRepeater.count; i++) {
            const card = cardRepeater.itemAt(i);
            if (!card || card.phase !== "active")
                continue;
            if (inputEnabled)
                card.releasePresentation();
            else
                card.freezePresentation();
        }
        root.geometryChanged();
    }
    onEvictShiftChanged: root.geometryChanged()
    onWidthChanged: root.geometryChanged()
    onHeightChanged: root.geometryChanged()
    Component.onCompleted: {
        root.layoutReady = true;
        root.syncLayout();
    }

    NumberAnimation {
        id: evictAnim
        target: root
        property: "evictShift"
        duration: Motion.revealSmall
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.revealCurve
        onFinished: root.finishEviction()
    }

    function cardGeometry(): var {
        const out = [];
        for (let index = 0; index < cardRepeater.count; index++) {
            const item = cardRepeater.itemAt(index);
            const row = rows.get(index);
            if (!item || !row)
                continue;
            const p1 = item.mapToItem(root, 0, 0);
            const p2 = item.mapToItem(root, item.width, item.height);
            const left = Math.max(0, Math.min(p1.x, p2.x));
            const top = Math.max(0, Math.min(p1.y, p2.y));
            const right = Math.min(root.width, Math.max(p1.x, p2.x));
            const bottom = Math.min(root.height, Math.max(p1.y, p2.y));
            const rect = Qt.rect(left, top, Math.max(0, right - left), Math.max(0, bottom - top));
            const eligible = root.inputEnabled && row.inputEligible
                && rect.width > 0 && rect.height > 0;
            out.push({ notificationId: row.idValue, rect,
                phase: row.phase, eligible });
        }
        return out;
    }

    implicitWidth: Style.notificationWidth
    implicitHeight: Math.max(0, column.implicitHeight + root.evictShift)

    // A bodied card's shadow reaches past its body, so the clip is wider than
    // the stack on the sides and the bottom. The top stays flush: a departing
    // row slides up and out through it, and a clip taller there would show the
    // departing card in the host's padding.
    readonly property real shadowReach: root.bodied && !Style.reducedEffects ? Style.cardShadowExtent : 0

    Item {
        id: viewport
        anchors.fill: parent
        anchors.leftMargin: -root.shadowReach
        anchors.rightMargin: -root.shadowReach
        anchors.bottomMargin: -root.shadowReach
        clip: true

        Column {
            id: column
            x: root.shadowReach
            spacing: root.rowSpacing
            transform: Translate { y: root.evictShift }

            move: Transition {
                enabled: root.evicting.length === 0 && !root.finishingEviction
                    && !root.rowHeightsAnimating
                NumberAnimation {
                    property: "y"
                    duration: Motion.revealSmall
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.revealCurve
                }
            }

            Repeater {
                id: cardRepeater
                model: rows
                onItemAdded: root.syncLayout()
                onItemRemoved: root.syncLayout()

                NotificationCard {
                    id: delegateCard
                    required property string key
                    required property int index
                    required property var idValue
                    required property var payload
                    required property string phase
                    required property bool inputEligible
                    required property bool animate
                    entry: payload
                    inputEnabled: root.inputEnabled && inputEligible && phase === "active"
                    showActions: false
                    primaryActionEnabled: root.inputEnabled && inputEligible && phase === "active"
                        && defaultAction() !== null
                    draggable: inputEnabled
                    verticalDragEnabled: inputEnabled
                    bodied: root.bodied
                    bodyRadius: root.bodyRadius
                    showDivider: !root.bodied && index < cardRepeater.count - 1
                    swatch: root.swatchFor ? root.swatchFor(payload) : payload.swatch
                    animateEntrance: animate
                    height: expansionFrozen ? frozenHeight : implicitHeight * entranceProgress
                    objectName: "notification-row-" + key

                    property bool hoverWasReported: false
                    function releaseHover(): void {
                        if (hoverWasReported) {
                            hoverWasReported = false;
                            root.hoverChanged(entry, false);
                        }
                    }
                    onHoveredChanged: {
                        if (hovered && inputEnabled) {
                            if (!hoverWasReported) {
                                hoverWasReported = true;
                                root.hoverChanged(entry, true);
                            }
                        } else {
                            releaseHover();
                        }
                    }
                    onDismissed: if (inputEnabled) root.dismissRequested(entry)
                    onPrimaryTriggered: requestedEntry => {
                        const current = root.stack.find(item => item.notificationId === requestedEntry.notificationId);
                        if (inputEnabled && current && actionsOf(current).some(
                                action => String(action.id) === "default" && !(action.disabled ?? false)))
                            root.primaryActionRequested(current);
                    }
                    onXChanged: root.geometryChanged()
                    onYChanged: root.geometryChanged()
                    onWidthChanged: root.geometryChanged()
                    onHeightChanged: root.syncLayout()
                    onInputEnabledChanged: {
                        releaseHover();
                        root.geometryChanged();
                    }
                    Component.onCompleted: root.geometryChanged()
                    Component.onDestruction: {
                        releaseHover();
                        root.geometryChanged();
                    }
                }
            }
        }
    }
}
