import QtQuick

import qs.QsmShell.Style

// Who this is: a picture if there is one, their initials if there is not.
//
// Initials rather than a silhouette glyph, because a row of identical
// silhouettes distinguishes nobody — and the fallback is the state that
// actually ships most of the time.
//
// `status` rides the corner rather than tinting the whole mark: tinting a
// photograph to say "online" damages the photograph and says it faintly.
Item {
    id: root

    property url source: ""
    // The name the initials come from. Two words give two letters, one gives
    // one — three letters is a monogram, not a glance.
    property string name: ""
    property real size: Style.controlHeight
    property color background: Style.surfaceHover
    // Empty = no dot. Otherwise a Badge tone.
    property string status: ""

    readonly property string initials: {
        const words = name.trim().split(/\s+/).filter(word => word.length > 0);
        if (words.length === 0)
            return "";
        if (words.length === 1)
            return words[0].charAt(0).toUpperCase();
        return String(words[0].charAt(0) + words[words.length - 1].charAt(0)).toUpperCase();
    }

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        id: ground
        anchors.fill: parent
        radius: width / 2
        color: root.background

        Prose {
            anchors.centerIn: parent
            visible: portrait.status !== Image.Ready
            role: "title"
            font.pixelSize: Math.round(root.size / 2.6)
            muted: true
            text: root.initials
        }
    }

    // Clipped to the same circle the ground draws, so a square photograph
    // does not sit in a round hole.
    Image {
        id: portrait
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        visible: portrait.status === Image.Ready
        layer.enabled: true
        Image {
            anchors.fill: parent
            source: portrait.source
            sourceSize: portrait.sourceSize
            fillMode: Image.PreserveAspectCrop
        }
    }

    Badge {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.status.length > 0
        tone: root.status
        dot: true
        filled: true
    }
}
