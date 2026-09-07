import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components
import qs.QsmShell.Style

// `ScenePointer` paints nothing on its own, so a static capture of it is
// always the same resting frame -- what proves it is `npm run preview`, where
// the owner can move the mouse and watch the placement rule happen instead of
// reading about it.
//
// `good` is declared on this Item, the ancestor of the frame below. `blind`
// is declared as a sibling BELOW the frame's `MouseArea` -- the exact shape
// that shipped broken. Move the pointer over the frame: the first reading
// tracks it, the second never leaves "inside: false", no matter where the
// pointer goes inside the frame.
Item {
    id: root
    property string variant: ""

    implicitWidth: 320
    implicitHeight: 220

    ScenePointer { id: good }

    ColumnLayout {
        anchors.fill: parent
        spacing: Style.space2

        Rectangle {
            id: frame
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            radius: Style.radiusLg
            color: Style.surfaceRaised
            border.width: 1
            border.color: good.inside ? Style.accent : Style.outline

            // Sibling BELOW the surface -- shadowed for as long as this stays
            // declared here rather than on `root`.
            Item {
                id: blindReaderHost
                anchors.fill: parent
                ScenePointer { id: blind }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        RowLayout {
            spacing: Style.space4
            Prose { role: "metadata"; text: "ancestor" }
            Prose {
                role: "reading"
                text: good.inside ? `${Math.round(good.position.x)}, ${Math.round(good.position.y)}` : "inside: false"
            }
        }
        RowLayout {
            spacing: Style.space4
            Prose { role: "metadata"; text: "sibling below" }
            Prose {
                role: "reading"
                text: blind.inside ? `${Math.round(blind.position.x)}, ${Math.round(blind.position.y)}` : "inside: false"
            }
        }
    }
}
