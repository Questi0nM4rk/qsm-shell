import QtQuick

// Live counterpart to CapturePreview.qml: same Preview host, no grab/quit,
// meant to be run with the wayland platform instead of offscreen. Args land
// after "--" in Qt.application.arguments (component, variant, width, height).
Item {
    id: root

    function argAfter(index, fallback) {
        const args = Qt.application.arguments
        const separator = args.indexOf("--")
        if (separator < 0)
            return fallback
        const value = args[separator + 1 + index]
        return value === undefined ? fallback : value
    }

    property string targetComponent: argAfter(0, "capsule")
    property string targetVariant: argAfter(1, "resting")
    property int targetWidth: parseInt(argAfter(2, "1600"))
    property int targetHeight: parseInt(argAfter(3, "900"))

    width: targetWidth
    height: targetHeight

    Rectangle {
        anchors.fill: parent
        color: "#1c0e27"
    }

    Preview {
        anchors.fill: parent
        component: root.targetComponent
        variant: root.targetVariant
        viewportWidth: root.targetWidth
        viewportHeight: root.targetHeight
    }
}
