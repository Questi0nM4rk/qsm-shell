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
// it was for.
//
// `hint` shows BEFORE the control is used, not after it fails. A format the
// person could have followed, revealed only by breaking it, is a rule the
// interface kept to itself.
//
// `error` is a message, not a state flag, so the component cannot be in an
// error state that says nothing. It reports `failed` for the control inside
// to colour itself by.
ColumnLayout {
    id: root

    property string label: ""
    property string hint: ""
    // Non-empty means failed. What broke, and where — the how-to-fix belongs
    // in the message text itself.
    property string error: ""
    // Marks the field as needed, in a channel that is not colour.
    property bool required: false
    // A caller composing a scaled control (a TextField/Slider/Switch's own
    // `sizeScale`) binds this to it so the label, message, glyph and gaps stay
    // in step with the control they frame.
    property real sizeScale: 1

    // A blank message says nothing, so it is neither a failure nor a hint.
    readonly property bool failed: error.trim().length > 0
    readonly property bool hinted: hint.trim().length > 0
    readonly property string accessibleName: label
    readonly property string accessibleDescription: [failed ? error : hint, required && label !== "" ? "Required" : ""].filter(value => value.length > 0).join(" ")

    // The control this frames.
    default property alias content: contentHost.data

    spacing: Style.rhythm(Style.space1 * root.sizeScale)

    // The mark lives on the label row, which an empty label hides; a required
    // field with no name would be announced but never shown.
    Component.onCompleted: {
        if (required && label === "")
            console.error("Field: `required` needs a `label`; the required mark has nowhere to show")
    }

    // The same label element a slider wears; one style for naming a control.
    ControlLabel {
        text: root.label
        required: root.required
        sizeScale: root.sizeScale
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
        spacing: Style.rhythm(Style.spaceTight * root.sizeScale)

        // The slot stays while a hint shows, so the message does not shift
        // right when the error arrives.
        SvgIcon {
            opacity: root.failed ? 1 : 0
            name: "circle-alert"
            size: Style.iconNear(Style.iconXs * root.sizeScale)
            color: Style.danger
        }
        Prose {
            Layout.fillWidth: true
            role: "metadata"
            color: root.failed ? Style.danger : Style.textMuted
            text: root.failed ? root.error : root.hint
            font.pixelSize: Style.textNear(Style.textXs * root.sizeScale)
        }
    }
}
