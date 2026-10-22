import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// The frame around ANY control that needs naming: a label above it, a hint
// before it is used, an error after it fails.
//
// WHY this is separate from the input rather than part of it: a switch, a
// slider and a segmented choice need a name and a failure message exactly as
// much as a text box does. Building those three lines into the text box means
// building them three more times, differently, the first time something other
// than a text box needs them.
//
// The label is a LABEL and lives outside the control. A placeholder inside an
// empty box vanishes the moment typing starts, so a box using its placeholder
// as its name leaves the person with a filled field and no way to recall what
// it was for. Clicking it puts the caret in the control, the way a label does.
//
// `hint` shows BEFORE the control is used, not after it fails. A format the
// person could have followed, revealed only by breaking it, is a rule the
// interface kept to itself.
//
// `error` is a message, not a state flag, so the component cannot be in an
// error state that says nothing. It reports `failed` for the control inside
// to colour itself by.
//
// The frame follows what it frames: the label, message and gaps take the
// control's own `sizeScale`, and the control is given the label as its
// accessible name and the active message as its description, unless a host
// already named it.
ColumnLayout {
    id: root

    property string label: ""
    property string hint: ""
    // Non-empty means failed. What broke, and where — the how-to-fix belongs
    // in the message text itself.
    property string error: ""
    // Marks the field as needed, in a channel that is not colour.
    property bool required: false
    // The scale of everything the frame draws. It follows the control it
    // frames (a TextField, a Slider, a Switch report their own `sizeScale`);
    // a host states it only to override.
    property real sizeScale: root._controlScale

    // A blank message says nothing, so it is neither a failure nor a hint.
    readonly property bool failed: error.trim().length > 0
    readonly property bool hinted: hint.trim().length > 0
    readonly property string accessibleName: label
    readonly property string accessibleDescription: [failed ? error : hint, nameLabel.requiredNote].filter(value => value.length > 0).join(" ")

    // The control this frames.
    default property alias content: contentHost.data

    // The control, a `var` because its type is the host's. A Loader hands over
    // what it loaded, which is nothing until it has loaded it.
    readonly property var _control: {
        const first = contentHost.children.length > 0 ? contentHost.children[0] : null;
        return first && first.item !== undefined ? first.item : first;
    }
    readonly property real _controlScale: root._control?.sizeScale ?? 1

    // One gap between label, control and message, past the focus ring's reach
    // (two strokes, 4.8 px at 1.25) so a ring never touches the text beside it.
    spacing: Style.rhythm(Style.space2 * root.sizeScale)

    // The mark lives on the label row, which an empty label hides; a required
    // field with no name would be announced but never shown.
    Component.onCompleted: {
        if (required && label === "")
            console.error("Field: `required` needs a `label`; the required mark has nowhere to show")
        root._nameControl()
    }
    on_ControlChanged: root._nameControl()

    // A screen reader meets the control, not the frame, so the name and the
    // description go to the control. Bound, so an error that arrives is spoken.
    function _nameControl(): void {
        const control = root._control;
        if (!control)
            return;
        if (control.Accessible.name === "")
            control.Accessible.name = Qt.binding(() => root.accessibleName);
        if (control.Accessible.description === "")
            control.Accessible.description = Qt.binding(() => root.accessibleDescription);
    }

    // Puts the caret where the label points, as a click on a label does. A
    // pointer press: the keyboard ring stays off.
    function _focusControl(): void {
        const control = root._control;
        if (!control || !control.enabled)
            return;
        if (control.focusFromPointer)
            control.focusFromPointer();
        else
            control.forceActiveFocus(Qt.MouseFocusReason);
    }

    // The same label element a slider wears; one style for naming a control.
    ControlLabel {
        id: nameLabel
        objectName: "controlLabel"
        // The control carries this name and the required note, so a screen
        // reader does not meet them twice.
        Accessible.ignored: true
        text: root.label
        required: root.required
        sizeScale: root.sizeScale

        TapHandler {
            onTapped: root._focusControl()
        }
    }

    Item {
        id: contentHost
        Layout.fillWidth: true
        implicitHeight: childrenRect.height
    }

    // Hint and error occupy the same line, because they answer the same
    // question at different times and stacking them makes the control jump
    // when it fails. The error wins while it stands.
    RowLayout {
        Layout.fillWidth: true
        visible: root.failed || root.hinted
        spacing: Style.rhythm(Style.space1 * root.sizeScale)

        // The glyph is the failure's channel besides colour, and only a
        // failure has one: a hint starts on the same left edge as the label
        // and the control.
        SvgIcon {
            visible: root.failed
            // On the first line, in the middle of the glyphs, however many
            // lines follow: the text sits at the top of its line box.
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: Math.max(0, Math.round((metrics.height - height) / 2))
            name: "circle-alert"
            size: Style.iconNear(Style.iconXs * root.sizeScale)
            color: Style.danger
        }
        FontMetrics {
            id: metrics
            font: message.font
        }
        // The message wraps: it is the part of a failure that says what to do,
        // and an ellipsis cuts exactly that part.
        Prose {
            id: message
            objectName: "fieldMessage"
            Layout.fillWidth: true
            role: "body"
            color: root.failed ? Style.danger : Style.textMuted
            text: root.failed ? root.error : root.hint
            font.pixelSize: Style.textNear(Style.textXs * root.sizeScale)
            elide: Text.ElideNone
            // A line is the glyph and one gap taller, on the 4 px rhythm.
            lineHeightMode: Text.FixedHeight
            lineHeight: Style.rhythm(font.pixelSize + Style.space1)
        }
    }
}
