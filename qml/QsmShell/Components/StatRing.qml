import QtQuick
import qs.QsmShell.Style

Item {
    id: root
    property real value: 0
    property color color: Style.accent
    property string label: ""
    property string reading: ""
    property real size: 72
    implicitWidth: size
    implicitHeight: size
    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const center = width / 2;
            const radius = center - 5;
            c.lineWidth = 5;
            c.strokeStyle = Style.outline;
            c.beginPath(); c.arc(center, center, radius, 0, Math.PI * 2); c.stroke();
            c.strokeStyle = root.color;
            c.beginPath(); c.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0, Math.min(1, root.value))); c.stroke();
        }
        Connections { target: root; function onValueChanged() { canvas.requestPaint(); } function onColorChanged() { canvas.requestPaint(); } }
    }
    Text { anchors.centerIn: parent; text: root.reading; color: Style.text; font.pixelSize: Style.textSm; font.weight: Style.weightBold }
    Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.bottom; anchors.topMargin: Style.space1; text: root.label; color: Style.textMuted; font.pixelSize: Style.textXs }
}
