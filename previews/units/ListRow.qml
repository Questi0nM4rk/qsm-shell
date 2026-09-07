import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// THE row, wearing its two former surface names as VARIANT axes instead of
// two types. "device-row" and "result-row" differed from the base list row
// in a handful of properties -- size, recede, content, a trailing reading --
// and nothing that needed a second type.
ListRow {
    id: root
    property string variant: ""

    // A list you READ (formerly "device-row"): full strength, no recede, and
    // per the law this type exists to demonstrate, NOT a target -- it
    // reports rather than acts. `large` is its own axis (formerly
    // "result-row"'s size step) -- redeclaring `size` here would shadow the
    // base component's own property.
    readonly property bool reading: variant.indexOf("reading") >= 0
    readonly property bool large: variant.indexOf("lg") >= 0

    size: root.reading ? "sm" : root.large ? "lg" : "md"
    recede: !root.reading
    interactive: !root.reading
    icon: root.reading ? "wifi" : "sparkle"
    primary: root.reading ? "qsm-lab" : "Pick a colour"
    supporting: root.reading ? "" : "Open colour picker"
    selected: variant.indexOf("selected") >= 0
    danger: variant.indexOf("danger") >= 0
    header: variant.indexOf("header") >= 0
    separator: variant.indexOf("separator") >= 0
    disabled: variant.indexOf("disabled") >= 0

    // ListRow's own `implicitWidth: body.implicitWidth` reports the ROW
    // BODY's natural span but never adds back the `leftMargin`/`rightMargin`
    // that same body loses to its own `anchors.fill: parent`, so a caller
    // that trusts the natural width (every other caller instead imposes one)
    // gets a body 2*Style.space3 too narrow and its text elides. Compensating
    // here rather than in the component itself, which this preview split may
    // not touch.
    width: implicitWidth + Style.space3 * 2

    // Real trailing content, loaded only for the reading look -- an inactive
    // Loader has no size, so the picking look reserves no space for either.
    Loader {
        active: root.reading
        sourceComponent: Prose {
            role: "reading"
            font.pixelSize: Style.textXs
            muted: true
            text: "Connected"
        }
    }
    Loader {
        active: root.reading
        sourceComponent: IconButton {
            icon: "trash-2"
            size: Style.iconSm
            padding: Style.space1
            color: Style.textMuted
        }
    }

    readonly property var controls: [
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ]},
        { label: "selected", options: [
            { label: "off", set: { selected: false } },
            { label: "on",  set: { selected: true } }
        ]},
        { label: "danger", options: [
            { label: "off", set: { danger: false } },
            { label: "on",  set: { danger: true } }
        ]},
        { label: "header", options: [
            { label: "off", set: { header: false } },
            { label: "on",  set: { header: true } }
        ]},
        { label: "separator", options: [
            { label: "off", set: { separator: false } },
            { label: "on",  set: { separator: true } }
        ]},
        { label: "disabled", options: [
            { label: "off", set: { disabled: false } },
            { label: "on",  set: { disabled: true } }
        ]},
        { label: "recede", options: [
            { label: "off", set: { recede: false } },
            { label: "on",  set: { recede: true } }
        ]}
    ]
}
