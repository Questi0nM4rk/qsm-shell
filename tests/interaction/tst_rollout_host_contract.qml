import QtQuick
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style

// Rollout finds its host by duck typing, the host contract in ShellBorder:
// registerBulge/unregisterBulge, registerRolloutRegion/
// unregisterRolloutRegion, registerFullscreenCapsule/unregisterFullscreenCapsule,
// plus one read of `fullscreen`. QML has no interfaces to hold that contract
// honest once the host is untyped `var` — this is the test that does.
TestCase {
    id: probe

    name: "RolloutHostContract"
    width: 300
    height: 200
    visible: true
    when: windowShown

    // Reduced motion shortens every reveal/retract to the same floor
    // (Motion.revealLarge/revealSmall), so the contract's timing-dependent
    // assertions settle fast without leaning on a specific tier's duration.
    QtObject {
        id: fastBackend
        property bool reducedMotion: true
    }

    Component.onCompleted: Style.backend = fastBackend

    // A fake host: records which of the seven calls happened and with what
    // id, nothing else. It answers the contract; it is not a real registry.
    QtObject {
        id: fakeHost
        property bool fullscreen: false
        property var calls: []

        function registerBulge(id, rect, radius, blend, deform, minEig, edgeBits, rimBits, detached, outness) {
            calls.push({ fn: "registerBulge", id: id });
        }
        function unregisterBulge(id) {
            calls.push({ fn: "unregisterBulge", id: id });
        }
        function registerRolloutRegion(id, rect) {
            calls.push({ fn: "registerRolloutRegion", id: id });
        }
        function unregisterRolloutRegion(id) {
            calls.push({ fn: "unregisterRolloutRegion", id: id });
        }
        function registerFullscreenCapsule(id, rect, radius) {
            calls.push({ fn: "registerFullscreenCapsule", id: id });
        }
        function unregisterFullscreenCapsule(id) {
            calls.push({ fn: "unregisterFullscreenCapsule", id: id });
        }
    }

    function callCount(name) {
        return fakeHost.calls.filter(c => c.fn === name).length;
    }

    Rollout {
        id: rollout
        host: fakeHost
        rolloutId: "probe-rollout"
        edges: ["top"]
        shouldBeActive: false
        bodyWidth: 200
        bodyHeight: 80

        Rectangle { width: 200; height: 80 }
    }

    // Every test starts from the same rest state: fully retracted, no calls
    // recorded yet.
    function init() {
        rollout.shouldBeActive = false;
        tryVerify(() => !rollout.visible, 1000, "rollout did not settle hidden before the test");
        fakeHost.calls = [];
    }

    function test_reveal_registers_bulge_on_show() {
        rollout.shouldBeActive = true;
        tryVerify(() => callCount("registerBulge") > 0, 1000,
            "reveal did not register a bulge on the host");
    }

    function test_rollout_region_registers_only_near_settled() {
        rollout.shouldBeActive = true;
        verify(callCount("registerRolloutRegion") === 0,
            "the hit region registered before the reveal was near-settled");

        tryVerify(() => rollout.offsetScale <= 0.1, 1000,
            "the reveal never neared settle (offsetScale <= 0.1)");
        tryVerify(() => callCount("registerRolloutRegion") > 0, 500,
            "the hit region never registered once near-settled");
    }

    function test_retract_unregisters_bulge_on_hide() {
        rollout.shouldBeActive = true;
        tryVerify(() => rollout.offsetScale <= 0.1, 1000, "reveal never settled");
        fakeHost.calls = [];

        rollout.shouldBeActive = false;
        tryVerify(() => callCount("unregisterBulge") > 0, 1000,
            "retract did not unregister the bulge once it fully settled hidden");
    }

    // A separate host and a separate Rollout, so destroying it cannot leak
    // into the assertions the other three tests make against `fakeHost`.
    QtObject {
        id: destroyHost
        property bool fullscreen: false
        property var calls: []

        function registerBulge(id, rect, radius, blend, deform, minEig, edgeBits, rimBits, detached, outness) {
            calls.push({ fn: "registerBulge", id: id });
        }
        function unregisterBulge(id) {
            calls.push({ fn: "unregisterBulge", id: id });
        }
        function registerRolloutRegion(id, rect) {
            calls.push({ fn: "registerRolloutRegion", id: id });
        }
        function unregisterRolloutRegion(id) {
            calls.push({ fn: "unregisterRolloutRegion", id: id });
        }
        function registerFullscreenCapsule(id, rect, radius) {
            calls.push({ fn: "registerFullscreenCapsule", id: id });
        }
        function unregisterFullscreenCapsule(id) {
            calls.push({ fn: "unregisterFullscreenCapsule", id: id });
        }
    }

    // `host` is supplied through createObject's initial properties, not
    // written into the component's own QML text, so the dynamic instance
    // needs no reference to an id outside its own document.
    Component {
        id: destroyRolloutComponent
        Rollout {
            rolloutId: "destroy-probe"
            edges: ["top"]
            shouldBeActive: true
            bodyWidth: 100
            bodyHeight: 60

            Rectangle { width: 100; height: 60 }
        }
    }

    function test_destruction_unregisters_everything() {
        const dynamic = destroyRolloutComponent.createObject(probe, { host: destroyHost });
        tryVerify(() => destroyHost.calls.some(c => c.fn === "registerBulge"), 1000,
            "the dynamic rollout never registered a bulge before being destroyed");

        destroyHost.calls = [];
        dynamic.destroy();
        tryVerify(() => destroyHost.calls.some(c => c.fn === "unregisterBulge")
            && destroyHost.calls.some(c => c.fn === "unregisterRolloutRegion")
            && destroyHost.calls.some(c => c.fn === "unregisterFullscreenCapsule"), 1000,
            "destruction did not unregister all three registrations");
    }
}
