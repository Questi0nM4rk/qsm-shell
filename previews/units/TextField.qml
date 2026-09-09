pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// THE text input, exercised as its own proof harness. Both slots are real:
// a search glyph in the leading slot, and a trailing control that calls the
// same public functions the field's own actions and keys do -- `clear()` for
// text, `toggleReveal()` for a password. The unit is the component itself,
// not a wrapper -- the host decides layout, the unit proves the control.
TextField {
    id: root
    property string variant: ""
    property string purposeOverride: ""
    readonly property string purpose: purposeOverride.length > 0
        ? purposeOverride
        : variant.startsWith("text") ? "text"
        : variant.startsWith("password") ? "password"
        : variant.startsWith("number") ? "number"
        : variant.startsWith("search") ? "search"
        : "text"
    readonly property bool textExample: purpose === "text"
    readonly property bool passwordExample: purpose === "password"
    readonly property bool numberExample: purpose === "number"

    property bool showLeading: true

    size: "lg"
    inputType: passwordExample ? "password" : numberExample ? "number" : "text"
    // `failed` is a HOST verdict, never the validator's, so the unit plays the
    // host for it: a number purpose reads `acceptableInput` and paints the
    // failure itself. Without it Return on `42,42.` was a silent no-op in a
    // frame identical to a valid field's. The `failed` control strip below
    // assigns this property and so replaces this binding for that session,
    // which is what a control strip is for.
    failed: numberExample && text.length > 0 && !acceptableInput
    leadingCursorShape: purpose === "search" ? Qt.PointingHandCursor : Qt.IBeamCursor
    trailingCursorShape: readOnly && !passwordExample ? Qt.ArrowCursor : Qt.PointingHandCursor
    placeholder: textExample ? "Enter text"
        : passwordExample ? "Password"
        : numberExample ? "Number"
        : "Search components"
    text: variant.endsWith("filled")
        ? textExample ? "Plain text"
        : passwordExample ? "correct horse"
        : numberExample ? "42.5"
        : "qsm-lab"
        : ""

    // Each example composes the same field with a glyph that names its purpose.
    Component {
        id: searchAction
        // The footprint must be the GLYPH width, not the padded button width:
        // the leading slot's width drives where the text column starts, so an
        // IconButton's extra padding here pushed the field text 8px right
        // against the plain-SvgIcon variants.
        IconButton {
            objectName: "textFieldSearchAction"
            icon: "search"
            size: Style.iconMd
            padding: 0
            color: Style.textMuted
            onClicked: root.accept()
        }
    }

    Component {
        id: purposeGlyph
        SvgIcon {
            name: root.textExample ? "type"
                : root.passwordExample ? "key"
                : "hash"
            size: Style.iconMd
            color: Style.textMuted
        }
    }

    leading: Loader {
        active: root.showLeading
        sourceComponent: root.purpose === "search" ? searchAction : purposeGlyph
    }

    // Trailing: text/search/number clear through the public API; password
    // reveals without changing its input type or sensitive-input hints.
    trailing: Loader {
        active: root.text.length > 0
        sourceComponent: IconButton {
            objectName: "textFieldTrailingAction"
            enabled: root.passwordExample || !root.readOnly
            icon: root.passwordExample
                ? root.passwordVisible ? "eye-off" : "eye"
                : "x"
            size: Style.iconSm
            padding: Style.space1
            color: Style.textMuted
            onClicked: {
                if (root.passwordExample)
                    root.toggleReveal();
                else
                    root.clear();
            }
        }
    }

    // States a pointer or keyboard can reach on their own (hover, press,
    // focus) must never be faked as control options. Only property-only
    // states that no honest interaction can reach belong here.
    readonly property var controls: [
        { label: "purpose", options: [
            { label: "text", set: {
                purposeOverride: "text", passwordVisible: false, text: "Plain text"
            }},
            { label: "search", set: {
                purposeOverride: "search", passwordVisible: false, text: "qsm-lab"
            }},
            { label: "password", set: {
                purposeOverride: "password", passwordVisible: false, text: "correct horse"
            }},
            { label: "number", set: {
                purposeOverride: "number", passwordVisible: false, text: "42.5"
            }}
        ]},
        { label: "leading", options: [
            { label: "glyph", set: { showLeading: true } },
            { label: "none",  set: { showLeading: false } }
        ]},
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ]},
        { label: "failed", options: [
            { label: "off", set: { failed: false } },
            { label: "on",  set: { failed: true } }
        ]},
        { label: "readOnly", options: [
            { label: "off", set: { readOnly: false } },
            { label: "on",  set: { readOnly: true } }
        ]},
        { label: "state", options: [
            { label: "enabled",  set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ]}
    ]
}
