import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// THE text input. One line, every state, two slots.
//
// It replaced `SearchField`, which was this component plus a magnifier plus
// four booleans naming which keys the launcher wanted to steal. A search box
// is a text box with an icon in its leading slot; it is not a second kind of
// text box, and the moment a second surface needed a plain one the library
// would have grown a third.
//
// ── keys ─────────────────────────────────────────────────────────────────
// A text input sits in the middle of a keyboard argument it cannot settle:
// Up and Down might move a cursor or move a selection in the list below;
// Left might move a caret or leave a drilled-in view; Tab might indent or
// move on. Only the surface knows.
//
// So there is ONE hook. `keyPressed` fires before anything else happens, with
// the real event; a consumer that sets `event.accepted = true` has taken the
// key and the field does nothing further with it. Everything the field does
// NOT hear back about, it handles itself: Return accepts, Escape escapes, Up
// and Down are reported as `moveUp` / `moveDown` for the list that usually
// sits under a field like this.
//
// That is one mechanism instead of four flags, and it covers the fifth key
// the flags did not anticipate.
Rectangle {
    id: root

    property string placeholder: ""
    property alias text: input.text
    // sm | md | lg
    property string size: "md"
    // Characters are hidden, but the person must still see them LANDING —
    // a field that shows nothing at all cannot be told from one that is not
    // receiving the keystrokes.
    property bool masked: false
    // Non-empty paints the failure. The message itself belongs to `Field`.
    property bool failed: false
    property bool readOnly: false

    // ── slots ───────────────────────────────────────────────────────────
    property alias leading: leadingSlot.data
    property alias trailing: trailingSlot.data

    // ── the one key hook ────────────────────────────────────────────────
    // Fires first, with the live event. Accept it to take the key.
    signal keyPressed(var event)

    signal accepted
    signal escaped
    signal edited(string text)
    signal moveUp
    signal moveDown
    // A hover-enter is not allowed to claim a selection while someone is
    // typing; the consumer owns that rule and the field only reports that
    // the text changed under the keyboard.
    signal selectionClaimed

    readonly property bool _sm: size === "sm"
    readonly property bool _lg: size === "lg"
    readonly property int fieldTextSize: _sm ? Style.textSm : _lg ? Style.textLg : Style.textMd
    readonly property bool focused: input.activeFocus

    function focusField(): void { input.forceActiveFocus(); }
    function setText(value: string): void { input.text = value; }
    function selectAll(): void { input.selectAll(); }

    implicitHeight: _sm ? Style.controlHeightSm : _lg ? Style.controlHeightLg : Style.controlHeight
    implicitWidth: row.implicitWidth + Style.space3 * 2
    radius: Style.radiusMd
    color: Style.surface
    opacity: enabled ? 1 : Style.opacityDisabled

    // The one border in the library, and it earns it: a text box is the only
    // control whose EDGE is the affordance — it says "your typing goes inside
    // this". It stays invisible at rest (the shell paints no boxes), appears
    // on focus, and turns on failure.
    border.width: root.failed || root.focused ? 1 : 0
    border.color: root.failed ? Style.danger : Style.accent

    Behavior on border.color {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: Style.space3
        anchors.rightMargin: Style.space3
        spacing: Style.space3

        Item {
            id: leadingSlot
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: children.length > 0 ? childrenRect.width : 0
            implicitHeight: children.length > 0 ? childrenRect.height : 0
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Prose {
                anchors.fill: parent
                visible: input.text.length === 0
                role: "label"
                muted: true
                font.pixelSize: root.fieldTextSize
                verticalAlignment: Text.AlignVCenter
                text: root.placeholder
            }

            TextInput {
                id: input
                anchors.fill: parent
                enabled: root.enabled
                readOnly: root.readOnly
                color: Style.text
                selectionColor: Style.accent
                selectedTextColor: Style.background
                verticalAlignment: TextInput.AlignVCenter
                font.family: Style.fontFamily
                font.pixelSize: root.fieldTextSize
                // Show each character as it lands, then hide it. Hiding
                // everything from the first keystroke leaves no way to tell a
                // masked field from a dead one.
                echoMode: root.masked ? TextInput.PasswordEchoOnEdit : TextInput.Normal
                clip: true

                onTextEdited: {
                    root.selectionClaimed();
                    root.edited(text);
                }

                // ONE dispatcher, and the reason is measured rather than
                // stylistic: `Keys.onPressed` and the per-key handlers
                // (`Keys.onDownPressed` and friends) hang off the SAME
                // attached object, and accepting the event in the generic one
                // does not stop the specific one from running. The first
                // version of this component had both, and a consumer that
                // claimed Down got its own handler AND `moveDown` — a
                // launcher list that moved two rows per keystroke.
                // `tests/interaction/tst_textfield.qml` is that bug, kept.
                //
                // So the hook fires, and if it did not take the key this
                // decides what the key means. No ordering to depend on.
                Keys.onPressed: event => {
                    root.keyPressed(event);
                    if (event.accepted)
                        return;

                    switch (event.key) {
                    case Qt.Key_Up:
                        root.selectionClaimed();
                        root.moveUp();
                        event.accepted = true;
                        break;
                    case Qt.Key_Down:
                        root.selectionClaimed();
                        root.moveDown();
                        event.accepted = true;
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.selectionClaimed();
                        root.accepted();
                        event.accepted = true;
                        break;
                    case Qt.Key_Escape:
                        root.escaped();
                        event.accepted = true;
                        break;
                    default:
                        // Everything else is typing, and typing belongs to the
                        // input. Leaving it unaccepted is what lets the caret,
                        // selection and clipboard keys keep working.
                        break;
                    }
                }
            }
        }

        Item {
            id: trailingSlot
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: children.length > 0 ? childrenRect.width : 0
            implicitHeight: children.length > 0 ? childrenRect.height : 0
        }
    }

    // Clicking anywhere in the box puts the caret in it. Without this the
    // person has to hit the text itself, which on an empty field is a
    // zero-width target sitting behind a placeholder.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.IBeamCursor
        onPressed: event => {
            input.forceActiveFocus();
            event.accepted = false;
        }
    }
}
