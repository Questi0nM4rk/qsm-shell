pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// A key, drawn as a key.
//
// WHY it looks like a cap rather than being set in the technical face: a
// keybind reference is scanned, not read, and "SUPER + /" as running text has
// to be parsed before it can be recognised. Caps and a separator turn it into
// a shape the eye matches against the keyboard in front of it.
//
// `combo` takes the whole thing — "SUPER + SHIFT + Q" — and splits it, so a
// consumer holding a compositor's own bind string does not have to tokenise
// before it can render.
//
// The host owns the width. Left alone Kbd is as wide as its caps; a host that
// gives it a width narrower than that (`width: column.width`) shrinks the caps
// and elides their text, so a long combo never draws past its column.
RowLayout {
    id: root

    required property string combo
    // Modifier keys are the same width wherever they appear; a ragged column
    // of caps is harder to scan than the text it replaced.
    property real minCapWidth: Style.space5

    spacing: Style.spaceTight

    Repeater {
        model: root.combo.split("+").map(part => part.trim()).filter(part => part.length > 0)

        delegate: RowLayout {
            id: part

            required property string modelData
            required property int index

            spacing: Style.spaceTight

            Prose {
                visible: part.index > 0
                // The join keeps its width; only caps give way.
                Layout.minimumWidth: implicitWidth
                role: "metadata"
                text: "+"
            }
            Rectangle {
                Layout.preferredWidth: Math.max(root.minCapWidth, cap.implicitWidth + Style.space2)
                // The floor leaves room for an ellipsis and the cap's insets.
                Layout.minimumWidth: Math.min(Layout.preferredWidth, Style.space5)
                Layout.preferredHeight: Style.badgeHeight + Style.space1
                radius: Style.radiusXs
                color: Style.keycap

                Prose {
                    id: cap
                    anchors.centerIn: parent
                    width: Math.max(0, Math.min(implicitWidth, parent.width - Style.space2))
                    elide: Text.ElideRight
                    role: "reading"
                    font.pixelSize: Style.textXs
                    text: part.modelData
                }
            }
        }
    }
}
