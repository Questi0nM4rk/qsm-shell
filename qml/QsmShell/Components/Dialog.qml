import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import qs.QsmShell.Style

// A surface that takes over until it is answered.
//
// Use it rarely and for one reason: the person cannot sensibly continue until
// this is settled. Everything short of that belongs inline — a `Callout` for a
// condition, a `Popover` for a choice beside its trigger, an `ArmedAction` for
// a destructive click. A dialog for a routine confirmation trains the reflex
// dismissal that removes the protection it was added for.
//
// ── the contract it owns ─────────────────────────────────────────────────
// A modal makes three promises, and half of them is worse than none because a
// half-modal LOOKS finished:
//
//   1. Focus moves INTO it when it opens.
//   2. Tab and Shift+Tab stay inside it — this is the only component in the
//      library allowed to trap the keyboard, and only while it is open.
//   3. Focus RETURNS to whatever invoked it when it closes, so the person is
//      put back where they were rather than at the top of the surface.
//
// Escape asks to close. It ASKS: a dialog guarding unsaved work must be able
// to refuse, and only the surface knows whether this one is guarding any.
FocusScope {
    id: root

    property bool open: false
    property string title: ""
    property string body: ""
    // A dialog whose consequence is severe says so with a mark as well as with
    // words, because the words are what gets skimmed.
    property string tone: "neutral"
    property real dialogWidth: Style.notificationWidth

    // The buttons. They live at the bottom-right, trailing edge last, because
    // that is where the eye finishes a dialog it has just read.
    default property alias actions: actionHost.data

    signal dismissRequested
    // Closed for real: the moment focus goes back.
    signal closed

    readonly property color _tone: tone === "danger" ? Style.danger
        : tone === "warning" ? Style.warning
        : Style.accent

    // Where focus goes back to. A consumer that knows (it owns the opening
    // control) states it; otherwise the dialog reads whatever held focus at
    // the moment it opened. Captured on open rather than on close, because by
    // then the dialog already holds it.
    property Item returnFocusTo: null
    property Item _returnTo: null

    anchors.fill: parent
    visible: card.opacity > 0
    // A closed dialog must not be in the tab order. `visible: false` handles
    // that, and the opacity guard above keeps it laid out through its own
    // fade-out.
    enabled: root.open

    onOpenChanged: {
        if (root.open) {
            root._returnTo = root.returnFocusTo ?? (Window.window?.activeFocusItem ?? null);
            card.forceActiveFocus();
        } else {
            if (root._returnTo)
                root._returnTo.forceActiveFocus();
            root._returnTo = null;
            root.closed();
        }
    }

    Scrim {
        shown: root.open
        onDismissed: root.dismissRequested()
    }

    Card {
        id: card

        anchors.centerIn: parent
        width: root.dialogWidth
        implicitHeight: content.implicitHeight + Style.space5 * 2
        radius: Style.radiusXl
        surfaceColor: Style.surfaceRaised
        focus: true
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96

        // It arrives by settling into place rather than by sliding from an
        // edge: a modal has no origin on the surface, so a direction would be
        // arbitrary and would read as coming from somewhere.
        Behavior on opacity {
            NumberAnimation {
                duration: Motion.medium
                easing.type: root.open ? Motion.standardEasing : Motion.exitEasing
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Motion.medium
                easing.type: root.open ? Motion.emphasizedEasing : Motion.exitEasing
            }
        }

        Keys.onEscapePressed: root.dismissRequested()

        // The trap, half of it. Tabbing BACKWARD off the first real control
        // lands here, and this sends focus to whatever sits just before the
        // tail — the last control in the dialog. Its twin below closes the
        // other direction. Both exist only while the dialog is open, so
        // nothing else in the shell is ever trapped.
        Item {
            id: head
            activeFocusOnTab: root.open
            onActiveFocusChanged: if (activeFocus) tail.nextItemInFocusChain(false).forceActiveFocus()
        }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Style.space5
            anchors.rightMargin: Style.space5
            spacing: Style.space3

            RowLayout {
                Layout.fillWidth: true
                visible: root.title.length > 0
                spacing: Style.space3

                SvgIcon {
                    visible: root.tone !== "neutral"
                    name: root.tone === "danger" ? "circle-alert" : "alert-triangle"
                    size: Style.iconMd
                    color: root._tone
                }
                Prose {
                    Layout.fillWidth: true
                    role: "heading"
                    text: root.title
                }
            }
            Prose {
                Layout.fillWidth: true
                visible: root.body.length > 0
                role: "body"
                muted: true
                text: root.body
            }
            RowLayout {
                id: actionHost
                Layout.fillWidth: true
                Layout.topMargin: Style.space2
                // Actions sit at the trailing edge. The leading space is the
                // filler, so a single button lands on the right rather than
                // stretching across the dialog.
                layoutDirection: Qt.RightToLeft
                spacing: Style.space2
            }
        }

        // The other half. Tabbing FORWARD off the last real control lands
        // here, and this sends focus to whatever sits just after the head —
        // the first control in the dialog.
        Item {
            id: tail
            activeFocusOnTab: root.open
            onActiveFocusChanged: if (activeFocus) head.nextItemInFocusChain(true).forceActiveFocus()
        }
    }
}
