pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Style

// The popup stack's own choreography (04-notifications): a capped WINDOW
// onto the live stream, newest entries appended at the bottom. When a newer
// arrival pushes an older one past the cap, the older one slides UP and out
// of the window instead of just vanishing — a real departure (dismissed or
// expired) just reflows the column via its own move transition, which is why
// telling the two apart matters.
//
// Owns no bus, no service, no screen. `stack` is the already-capped,
// already-ordered (newest first) window the consumer computed (DND
// filtering, the cap itself — service policy, both). `isAlive` answers, AT
// THE MOMENT ASKED, whether an id is still alive ANYWHERE, unbounded — the
// one fact this stack cannot see for itself but needs, to tell "pushed out
// of the window, still alive elsewhere" (eviction) from "gone" (ordinary
// reflow). A function, not a snapshot array handed in alongside `stack`:
// both would be sibling bindings off the same source change, and which
// settles first is not something a binding graph promises — a query asks
// the live source directly, at the instant this stack actually needs it.
//
// Snapshots, never live references, past the moment an entry arrives: the
// consumer's entries can be destroyed out from under this stack at any time
// (NotificationEntry's own law), and a card bound to a destroyed object
// crashes the shell.
Item {
    id: root

    property var stack: []
    property var isAlive: null
    // A rule the library cannot see (an application name, say) deciding an
    // entry's icon box carries a colour instead of a glyph — same escape
    // hatch NotificationCenter takes.
    property var swatchFor: null

    signal dismissRequested(var entry)
    // The card only REPORTS hover; whether that pauses anything is the
    // consumer's call (same law the card itself follows).
    signal hoverChanged(var entry, bool hovered)
    // A rendered row's bounds may have changed — a hover expanding it, its
    // own entrance settle, the eviction slide, or the ordinary reflow move.
    // The consumer decides what a rect means (a fullscreen capsule, say);
    // this stack only reports that one might be stale.
    signal geometryChanged()

    function snapshotOf(entry: var): var {
        return {
            notificationId: entry.notificationId,
            appName: entry.appName,
            summary: entry.summary,
            body: entry.body,
            urgency: entry.urgency,
            imagePath: entry.imagePath,
            actions: entry.actions,
            createdAt: entry.createdAt,
            paused: false
        };
    }

    // Every rendered row's bounds, in THIS item's own coordinate space. A
    // consumer that needs to register one against a screen (a fullscreen
    // capsule, say) maps it from there — this stack does not know a screen
    // exists.
    function cardGeometry(): var {
        const out = [];
        for (let index = 0; index < cardRepeater.count; index++) {
            const item = cardRepeater.itemAt(index);
            const entry = cardRepeater.model[index];
            if (!item || !entry)
                continue;
            const p = item.mapToItem(root, 0, 0);
            out.push({ notificationId: entry.notificationId, rect: Qt.rect(p.x, p.y, item.width, item.height) });
        }
        return out;
    }

    // Content rides the retract fully drawn: when the last popup expires the
    // model empties INSTANTLY, which left a blank bar sliding into the band —
    // keep showing the final stack until the rollout has fully retracted.
    property var displayStack: []
    // Overflow-evicted entries, still sliding out (snapshots, oldest first).
    property var evicting: []
    property real evictShift: 0
    // The eviction slide moves the WHOLE column via a transform rather than
    // any one row's own x/y, so a row's `onYChanged` alone never sees it.
    onEvictShiftChanged: root.geometryChanged()
    // Snapshots render collapsed, so an evicted row's height is deterministic.
    readonly property real evictHeight: evicting.length * Style.notificationCollapsedHeight
    // What was visible last change, for eviction detection (plain ids+data).
    property var previousVisible: []

    onStackChanged: {
        const snapshots = root.stack.map(entry => root.snapshotOf(entry));
        if (root.stack.length > 0)
            root.displayStack = snapshots;

        // Overflow eviction: an entry that left the WINDOW while `isAlive`
        // still says yes was pushed out by a newer arrival — that one slides
        // into the band. An entry `isAlive` no longer answers for (expired,
        // dismissed) just reflows via the column's own move transition.
        const windowIds = new Set(root.stack.map(entry => entry.notificationId));
        const pushedOut = root.previousVisible.filter(item =>
            !windowIds.has(item.notificationId) && (root.isAlive?.(item.notificationId) ?? false));
        root.previousVisible = snapshots;
        if (pushedOut.length === 0)
            return;

        // A second overflow mid-slide: finish the running slide instantly
        // (prune + reset by hand — complete()'s finished-signal timing is not
        // worth depending on), then start the new one from clean state.
        if (evictAnim.running) {
            evictAnim.stop();
            root.evicting = [];
            root.evictShift = 0;
        }
        root.evicting = pushedOut;
        evictAnim.to = -root.evictHeight;
        evictAnim.start();
    }

    // 04 DEFAULT numbers: 250ms, main curve, no overshoot, no fade.
    NumberAnimation {
        id: evictAnim
        target: root
        property: "evictShift"
        duration: Motion.revealSmall
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.revealCurve
        onFinished: {
            // Prune and reset in one pass — the rows above the clip edge
            // disappear together with the shift that hid them: no visible
            // change.
            root.evicting = [];
            root.evictShift = 0;
        }
    }

    // The window: clipped to the CURRENT stack's height, so an evicted row
    // above it is absorbed by the top edge and a newcomer below it enters
    // through the bottom edge as the column shifts up.
    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight - root.evictHeight
    clip: true

    Column {
        id: column
        spacing: 0
        transform: Translate { y: root.evictShift }

        // Expiry/dismissal mid-stack: the survivors glide up instead of
        // snapping (same 250ms vocabulary as the eviction slide).
        move: Transition {
            NumberAnimation {
                property: "y"
                duration: Motion.revealSmall
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.revealCurve
            }
        }

        Repeater {
            id: cardRepeater
            // Oldest at the top (the window is newest-first; the stream
            // appends downward — 04: entries enter from the bottom edge),
            // with evicting snapshots above the window.
            model: {
                const visible = root.stack.length > 0 ? root.stack : root.displayStack;
                return [...root.evicting, ...[...visible].reverse()];
            }

            NotificationCard {
                id: delegateCard
                required property var modelData
                required property int index
                entry: modelData
                // 04 RATIFIED: popups are feedback and dismissal only —
                // named actions are invoked exclusively from the
                // notification-centre panel.
                showActions: false
                draggable: true
                verticalDragEnabled: true
                // A Repeater inside a positioner remains a child of that
                // positioner itself alongside its delegates, so the last
                // delegate is at `count - 1`, not at `children.length - 1`.
                showDivider: index < cardRepeater.count - 1
                swatch: root.swatchFor ? root.swatchFor(modelData) : modelData.swatch
                onDismissed: root.dismissRequested(modelData)
                onHoveredChanged: root.hoverChanged(modelData, delegateCard.hovered)
                // A row's own bounds change continuously while it settles in,
                // expands on hover, or slides through eviction/reflow — each
                // one is a candidate rect update for whatever the consumer is
                // tracking against a rendered row (a fullscreen capsule, say).
                onXChanged: root.geometryChanged()
                onYChanged: root.geometryChanged()
                onWidthChanged: root.geometryChanged()
                onHeightChanged: root.geometryChanged()
                Component.onCompleted: root.geometryChanged()
                Component.onDestruction: root.geometryChanged()
            }
        }
    }
}
