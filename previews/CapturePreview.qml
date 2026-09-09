import QtQuick

Item {
    id: captureRoot

    property string targetComponent: "capsule"
    property string targetUnit: ""
    property string targetVariant: "resting"
    property int targetWidth: 1600
    property int targetHeight: 900
    property string targetTheme: "deep-night"
    property var targetBackend: null
    property string outputPath: "/tmp/qsm-capture.png"

    width: targetWidth
    height: targetHeight

    Rectangle {
        anchors.fill: parent
        color: "#1c0e27"
    }

    Preview {
        id: previewHost
        anchors.fill: parent
        component: captureRoot.targetComponent
        unit: captureRoot.targetUnit
        variant: captureRoot.targetVariant
        viewportWidth: captureRoot.targetWidth
        viewportHeight: captureRoot.targetHeight
        theme: captureRoot.targetTheme
        backend: captureRoot.targetBackend
        captureDump: true
    }

    // Let bindings and fonts settle before capture.
    Timer {
        id: grabTimer
        interval: 300
        running: true
        repeat: false
        onTriggered: {
            // The tree has to describe the SAME frame the PNG shows. Preview's
            // own dump fires one frame after load, which is before a Behavior
            // started by a host write has run: the variant reaches a unit
            // through `onLoaded`, AFTER the unit completed, so both slider
            // scenarios reported a painted position still animating out of the
            // pre-variant value and read as broken geometry. capture-qml.mjs
            // keeps the LAST dump, so this one wins.
            previewHost.dumpTree();
            captureRoot.grabToImage(function(result) {
                if (result.saveToFile(captureRoot.outputPath)) {
                    console.log("CAPTURE_OK:" + captureRoot.outputPath)
                } else {
                    console.error("CAPTURE_FAIL: could not save to " + captureRoot.outputPath)
                }
                Qt.quit()
            })
        }
    }
}
