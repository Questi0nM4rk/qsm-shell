import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components
import qs.QsmShell.Style

// T6: a rollout is held open while the pointer sits inside its hit area, plus
// a grace period after it leaves. The two boxes below are `holdAreas`, with a
// deliberate GAP between them -- sweep the pointer from one box straight into
// the other and `held` never drops; leave both and it stays true for the
// grace period before finally going false. This is what proves the mechanism
// live: a static capture always lands on one frame of one state.
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

    readonly property rect areaLeft: Qt.rect(20, 90, 120, 80)
    readonly property rect areaRight: Qt.rect(280, 90, 120, 80)

    // Sits IN the gap between the two hold areas, not touching either --
    // proof that what keeps it open is the union of `holdAreas`, never its
    // own silhouette.
    Rollout {
        id: rollout
        x: 165
        y: 95
        host: fakeHost
        rolloutId: "preview-rollout"
        edges: ["top"]
        tier: "small"
        shouldBeActive: true
        holdAreas: [root.areaLeft, root.areaRight]

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
            Prose { role: "metadata"; text: "held" }
            Prose { role: "reading"; text: rollout.held ? "true" : "false" }
        }
    }
}
