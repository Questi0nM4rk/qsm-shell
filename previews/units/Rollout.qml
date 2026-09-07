import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components
import qs.QsmShell.Style

// A rollout has a small TRIGGER area that opens it while closed (the nub
// bulging out of the frame) and a bigger HOVER area that keeps it open once
// grown into (the body plus the corridors a hand sweeps through to reach
// it). The top box is `triggerAreas`; the two lower boxes are `hoverAreas`,
// with a deliberate GAP between them. `shouldBeActive` binds to `wantsOpen`
// here exactly as a real surface would: point at the trigger box and the
// rollout opens; sweep on into either hover box and it stays open; sweep
// from one hover box straight into the other and it never drops; leave
// everything and it stays open for the close delay before finally
// retracting. This is what proves the mechanism live: a static capture
// always lands on one frame of one state.
Item {
    id: root
    property string variant: ""

    implicitWidth: 420
    implicitHeight: 260

    // The ancestor every ScenePointer must be declared on.
    ScenePointer { id: pointer }

    // A minimal stand-in for the seven-call host contract -- this preview is
    // about the keep-open rule, not the melt shader.
    QtObject {
        id: fakeHost
        property bool fullscreen: false
        property var pointer: pointer
        function registerBulge() {}
        function unregisterBulge() {}
        function registerRolloutRegion() {}
        function unregisterRolloutRegion() {}
        function registerFullscreenCapsule() {}
        function unregisterFullscreenCapsule() {}
    }

    // The nub: small, sits ABOVE the body (and below the readout column),
    // reachable while the rollout is fully closed.
    readonly property rect areaTrigger: Qt.rect(180, 84, 60, 24)
    readonly property rect areaLeft: Qt.rect(20, 110, 120, 80)
    readonly property rect areaRight: Qt.rect(280, 110, 120, 80)

    // Sits IN the gap between the two hover areas, not touching either --
    // proof that what keeps it open is the union of `hoverAreas`, never its
    // own silhouette. `shouldBeActive` binds to `wantsOpen`, the same
    // decision a real surface makes: the trigger opens it, the hover keeps
    // it, this component itself never decides.
    Rollout {
        id: rollout
        x: 165
        y: 115
        host: fakeHost
        rolloutId: "preview-rollout"
        edges: ["top"]
        tier: "small"
        shouldBeActive: rollout.wantsOpen
        triggerAreas: [root.areaTrigger]
        hoverAreas: [root.areaLeft, root.areaRight]

        Rectangle {
            width: 90
            height: 60
            color: "transparent"
            Prose {
                anchors.centerIn: parent
                role: "supporting"
                text: "rollout"
            }
        }
    }

    Rectangle {
        x: root.areaTrigger.x; y: root.areaTrigger.y
        width: root.areaTrigger.width; height: root.areaTrigger.height
        radius: Style.radiusMd
        color: "transparent"
        border.width: 2
        border.color: pointer.contains(root.areaTrigger) ? Style.accent : Style.outline
    }

    Rectangle {
        x: root.areaLeft.x; y: root.areaLeft.y
        width: root.areaLeft.width; height: root.areaLeft.height
        radius: Style.radiusMd
        color: "transparent"
        border.width: 2
        border.color: pointer.contains(root.areaLeft) ? Style.accent : Style.outline
    }

    Rectangle {
        x: root.areaRight.x; y: root.areaRight.y
        width: root.areaRight.width; height: root.areaRight.height
        radius: Style.radiusMd
        color: "transparent"
        border.width: 2
        border.color: pointer.contains(root.areaRight) ? Style.accent : Style.outline
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Style.space2
        spacing: Style.space1
        RowLayout {
            spacing: Style.space4
            Prose { role: "metadata"; text: "triggered" }
            Prose { role: "reading"; text: rollout.triggered ? "true" : "false" }
        }
        RowLayout {
            spacing: Style.space4
            Prose { role: "metadata"; text: "hovered" }
            Prose { role: "reading"; text: rollout.hovered ? "true" : "false" }
        }
        RowLayout {
            spacing: Style.space4
            Prose { role: "metadata"; text: "keepOpen" }
            Prose { role: "reading"; text: rollout.keepOpen ? "true" : "false" }
        }
        RowLayout {
            spacing: Style.space4
            Prose { role: "metadata"; text: "wantsOpen" }
            Prose { role: "reading"; text: rollout.wantsOpen ? "true" : "false" }
        }
    }
}
