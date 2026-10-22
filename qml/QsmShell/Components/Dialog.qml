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
    property real dialogWidth: Style.controlWidth

    // The buttons, declared in reading order: the first takes focus on open
    // and the last sits at the trailing edge, bottom-right, because that is
    // where the eye finishes a dialog it has just read.
    default property alias actions: actionHost.data

    signal dismissRequested
    // Closed for real: the moment focus goes back.
    signal closed

    readonly property var _tones: ({
        neutral: { color: Style.accent, icon: "" },
        danger: { color: Style.danger, icon: "circle-alert" },
        warning: { color: Style.warning, icon: "alert-triangle" }
    })
    readonly property bool _toneKnown: _tones[tone] !== undefined
    readonly property color _tone: (_tones[tone] ?? _tones.neutral).color
    readonly property string _mark: (_tones[tone] ?? _tones.neutral).icon

    // QML cannot throw out of a binding, so an unknown tone is reported on the
    // error stream and drawn as neutral, with no mark.
    on_ToneKnownChanged: _checkTone()
    Component.onCompleted: _checkTone()
    function _checkTone(): void {
        if (!_toneKnown)
            console.error(`Dialog: unknown tone "${tone}" -- expected neutral, danger or warning`);
    }

    // Where focus goes back to. A consumer that knows (it owns the opening
    // control) states it; otherwise the dialog reads whatever held focus at
    // the moment it opened. Captured on open rather than on close, because by
    // then the dialog already holds it.
    property Item returnFocusTo: null
    property Item _returnTo: null

    anchors.fill: parent
    Accessible.role: Accessible.Dialog
    Accessible.name: root.title
    Accessible.description: root.body
    // `root.open` FIRST, and it is not redundant: the card fades in from zero,
    // so at the instant `open` flips, `card.opacity` is still 0. Reading only
    // the opacity left the dialog invisible for its first frame — and an
    // invisible item cannot take focus, so the focus-entry below silently did
    // nothing and the keyboard stayed behind the modal. The opacity term is
    // what keeps it laid out through the fade OUT.
    visible: root.open || card.opacity > 0
    // Not `enabled: root.open`: that greys every control at the first frame of
    // the fade out. Answering is gated instead by the shield below (pointer)
    // and by `_release` (keys), and the controls keep their colours until the
    // card is gone. Once invisible they leave the tab order on their own.

    // Move the keyboard to the first ACTION, not to the card: the card is a
    // plain surface, so focusing it leaves the keyboard pointing at nothing,
    // and a scrolling body ahead of the actions would otherwise take the
    // focus the safe action was declared to have. `actionHost` is not a stop
    // itself, so the next one after it is by construction its first control.
    function _enterFocus(): void {
        if (!root.open)
            return;
        const first = actionHost.nextItemInFocusChain(true);
        // With no action the chain runs straight into `tail`, which is a
        // sentinel, not a control: the card takes focus instead.
        if (first && first !== tail && root._holds(first))
            first.forceActiveFocus();
        else
            card.forceActiveFocus();
    }

    // Is `item` inside this dialog? The focus chain runs through the whole
    // window, so "the next focusable thing" can perfectly well be a control
    // behind the modal — which is the failure this guards.
    function _holds(item: Item): bool {
        let walk = item;
        while (walk) {
            if (walk === card)
                return true;
            walk = walk.parent;
        }
        return false;
    }

    onOpenChanged: {
        if (root.open) {
            root._returnTo = root.returnFocusTo ?? (Window.window?.activeFocusItem ?? null);
            // Deferred by one turn, and it has to be: `visible` and `enabled`
            // are BINDINGS on `open`, and this handler can run before they
            // re-evaluate. An invisible item silently refuses focus, so
            // calling straight through left the keyboard outside the modal
            // with nothing to say it had failed.
            Qt.callLater(root._enterFocus);
        } else {
            // The invoker is the consumer's to keep alive (`returnFocusTo` names
            // one that survives the action); an item that refuses focus is not
            // second-guessed here.
            if (root._returnTo)
                root._returnTo.forceActiveFocus();
            // Whatever still holds focus inside the fading card must stop
            // answering keys; the card itself only reports Escape while open.
            if (root.activeFocus)
                card.forceActiveFocus();
            root._returnTo = null;
            root.closed();
        }
    }

    Scrim {
        shown: root.open
        onDismissed: root.dismissRequested()
    }

    // Closed for real only when the fade ends, but no longer answering the
    // moment `open` drops: it catches the pointer over the fading card, whose
    // controls still hold their colours.
    MouseArea {
        z: 1
        anchors.fill: parent
        enabled: !root.open
        acceptedButtons: Qt.AllButtons
        onWheel: wheel => wheel.accepted = true
    }

    Card {
        id: card

        // Never wider than the window leaves room for: a dialog that outgrows a
        // small output would clip its own actions.
        width: Math.min(root.dialogWidth, root.width - Style.space6 * 2)
        // Capped to the window, so a long body scrolls under a fixed title and
        // fixed actions instead of pushing them out of reach. Rounded UP to the
        // device grid: the text's line height is fractional, and a card edge
        // between two device pixels is a soft edge.
        implicitHeight: Style.snapUp(Math.min(content.implicitHeight + Style.space5 * 2,
            root.height - Style.space6 * 2), root)
        x: Style.snap((root.width - width) / 2, root)
        y: Style.snap((root.height - height) / 2, root)
        radius: Style.radiusXl
        surfaceColor: Style.overlay
        focus: true
        opacity: root.open ? 1 : 0
        // Under reduced motion the card only fades: the settle is movement.
        scale: root.open || Style.reducedMotion ? 1 : Motion.microPopScale

        // It arrives by settling into place rather than by sliding from an
        // edge: a modal has no origin on the surface, so a direction would be
        // arbitrary and would read as coming from somewhere.
        Behavior on opacity {
            NumberAnimation {
                duration: root.open ? Motion.medium : Motion.exit(Motion.medium)
                easing.type: root.open ? Motion.standardEasing : Motion.exitEasing
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.open ? Motion.medium : Motion.exit(Motion.medium)
                easing.type: root.open ? Motion.emphasizedEasing : Motion.exitEasing
            }
        }

        Keys.onEscapePressed: if (root.open) root.dismissRequested()

        // The card takes every press that is not on a control it holds, so a
        // click on its title, body or padding never reaches the scrim, which
        // would read it as "clicked away". Declared before the content so the
        // actions and the body stay on top of it.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onWheel: wheel => wheel.accepted = true
        }

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
            anchors.fill: parent
            anchors.margins: Style.space5
            spacing: Style.space3

            // The mark is the tone's, so it shows without a title too.
            RowLayout {
                Layout.fillWidth: true
                visible: root.title.length > 0 || root._mark.length > 0
                spacing: Style.space3

                SvgIcon {
                    visible: root._mark.length > 0
                    name: root._mark
                    size: Style.iconMd
                    color: root._tone
                }
                Prose {
                    Layout.fillWidth: true
                    visible: root.title.length > 0
                    role: "heading"
                    text: root.title
                }
            }
            // Takes the room the card has left; the title and the actions keep
            // theirs, so a long body scrolls and they stay in reach.
            ScrollArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: bodyText.implicitHeight
                visible: root.body.length > 0
                fadeColor: Style.overlay

                Prose {
                    id: bodyText
                    width: parent.width
                    role: "body"
                    // The body is what the person came to read.
                    font.pixelSize: Style.textMd
                    muted: true
                    text: root.body
                }
            }
            RowLayout {
                id: actionHost
                Layout.fillWidth: true
                // The answer sits a full inset below what it answers, the
                // space the card keeps around everything: title and body read
                // as one group, the actions as the next.
                Layout.topMargin: Style.space5 - Style.space3
                spacing: Style.space2

                // The leading space is the filler, so a single button lands on
                // the trailing edge rather than stretching across the dialog.
                Item { Layout.fillWidth: true }
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
