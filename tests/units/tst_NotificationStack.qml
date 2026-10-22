import QtQuick
import QtTest
import qs.QsmShell.Components

TestCase {
    id: testCase
    name: "NotificationStack"
    width: 500
    height: 500
    visible: true
    when: windowShown

    property var source: []
    property var alive: []
    property var fixtureEvents: []

    NotificationStack {
        id: stack
        anchors.centerIn: parent
        stack: testCase.source
        isAlive: id => testCase.alive.includes(id)
    }
    SignalSpy { id: dismissed; target: stack; signalName: "dismissRequested" }

    function row(id) {
        return findChild(stack, "notification-row-string:" + id)
    }

    function entry(id, summary, actions) {
        return { notificationId: id, appName: "Transfer", summary, body: "Result",
            actions: actions ?? [{ id: "open", label: "Open" }] };
    }

    function init() {
        stack.retainWhenEmpty = false;
        source = [];
        alive = [];
    }

    function test_identity_owned_values_and_host_order() {
        const oldAction = { id: "open", label: "Open", metadata: { destination: "disk" } };
        const newest = entry("b", "Newer", [oldAction]);
        const oldest = entry("a", "Older", []);
        alive = ["a", "b"];
        source = [newest, oldest];
        tryVerify(() => stack.cardGeometry().length === 2);

        compare(stack.displayStack.map(item => item.notificationId).join(","), "a,b");
        const card = row("b");
        verify(card !== null);
        card._dragExpanded = true;
        oldAction.metadata.destination = "mutated source";
        compare(stack.displayStack.find(item => item.notificationId === "b")
            .actions[0].metadata.destination, "disk");

        source = [oldest, newest];
        compare(stack.displayStack.map(item => item.notificationId).join(","), "b,a");
        compare(row("b"), card, "moving a keyed row replaced its delegate");

        source = [entry("b", "Latest result", [{ id: "open", label: "View result" }]), oldest];
        tryVerify(() => stack.displayStack.find(item => item.notificationId === "b")?.summary === "Latest result");
        compare(row("b"), card, "same-ID content replacement recreated its delegate");
        compare(card.expanded, true, "same-ID replacement discarded local expansion");
    }

    function test_overflow_withdraws_input_and_retains_last_body() {
        const a = entry("a", "Oldest");
        const b = entry("b", "Middle");
        const c = entry("c", "Newest");
        alive = ["a", "b", "c"];
        source = [b, a];
        tryVerify(() => stack.cardGeometry().length === 2);
        row("b")._dragExpanded = true;
        tryVerify(() => row("b").entranceProgress === 1 && !row("b").expansionAnimating);

        source = [c, b];
        const evicted = stack.cardGeometry().find(item => item.notificationId === "a");
        verify(evicted !== undefined);
        compare(evicted.phase, "evicting");
        compare(evicted.eligible, false);
        row("a").dismiss();
        compare(dismissed.count, 0, "an overflow row still accepted a dismiss action");
        const expandedHeight = row("b").height;
        stack.inputEnabled = false;
        compare(row("b").expanded, true, "host retract collapsed the active presentation");
        compare(row("b").height, expandedHeight, "host retract changed the card body geometry");
        compare(stack.cardGeometry().find(item => item.notificationId === "b").eligible, false);
        stack.inputEnabled = true;
        compare(stack.cardGeometry().find(item => item.notificationId === "b").eligible, true);
        const before = stack.implicitHeight;

        stack.retainWhenEmpty = true;
        source = [];
        compare(stack.displayStack.length, 2);
        compare(stack.implicitHeight, before);
        compare(row("b").height, expandedHeight);
        compare(stack.cardGeometry().some(item => item.eligible), false);

        source = [entry("b", "Returned during retract")];
        tryVerify(() => stack.cardGeometry().some(item => item.notificationId === "b" && item.eligible));
        compare(row("b").expanded, true);

        source = [];
        stack.retainWhenEmpty = false;
        tryVerify(() => stack.cardGeometry().length === 0);
        tryCompare(stack, "implicitHeight", 0);
    }

    function test_repeated_overflow_retargets_without_restarting_the_column() {
        alive = ["a", "b", "c", "d"];
        source = [entry("b", "B"), entry("a", "A")];
        tryVerify(() => stack.cardGeometry().length === 2);
        source = [entry("c", "C"), entry("b", "B")];
        compare(stack.evicting.length, 1);
        wait(40);
        const shift = stack.evictShift;
        source = [entry("d", "D"), entry("c", "C")];
        compare(stack.evicting.length, 2);
        compare(stack.evictShift, shift, "a repeated overflow reset the active column shift");
        compare(stack.cardGeometry().filter(item => item.phase === "evicting")
            .every(item => !item.eligible), true);
    }

    function test_returning_eviction_reclaims_its_row_from_old_cleanup() {
        alive = ["a", "b", "c"];
        source = [entry("b", "B"), entry("a", "A")];
        tryVerify(() => stack.cardGeometry().length === 2);
        const original = row("a");
        source = [entry("c", "C"), entry("b", "B")];
        compare(stack.cardGeometry().find(item => item.notificationId === "a").phase, "evicting");

        source = [entry("a", "Returned"), entry("c", "C")];
        tryVerify(() => stack.cardGeometry().some(item => item.notificationId === "a"
            && item.phase === "active" && item.eligible));
        compare(row("a"), original);
        tryVerify(() => stack.evicting.length === 0, 1000);
        compare(row("a"), original, "stale eviction cleanup destroyed the reclaimed row");
    }

    function test_workbench_fixture_uses_the_real_rollout_and_answers_intents() {
        const component = Qt.createComponent(Qt.resolvedUrl("../../workbench/units/NotificationStack.qml"));
        compare(component.status, Component.Ready, component.errorString());
        const fixture = component.createObject(testCase, { width: 400, height: 300 });
        verify(fixture !== null, component.errorString());
        fixture.eventRecorder = (kind, event) => fixtureEvents.push(event);
        verify(fixture.integration.observables.count() === 2);
        fixture.arrive();
        tryVerify(() => fixture.integration.observables.evicting() === 1);
        compare(fixture.integration.observables.ids(), "b,c");
        tryVerify(() => fixtureEvents.includes("geometry-changed"));
        const card = findChild(fixture, "notification-row-string:b");
        verify(card !== null);
        card.dismiss();
        tryVerify(() => fixtureEvents.includes("dismiss-requested"));
        compare(fixture.integration.observables.count(), 2);
        compare(fixture.integration.observables.ids(), "a,c");
        fixture.arriveDuringRetreat();
        tryVerify(() => fixture.integration.observables["retreat-arrivals"]() === 1
            && fixture.all.length === 1, 2000);
        fixture.destroy();
    }
}
