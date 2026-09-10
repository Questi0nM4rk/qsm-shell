import QtQuick

import qs.QsmShell.Style

// THE body of a component: one rectangle whose colour is the surface ladder's
// answer to where it lies (`base`) and what it is doing (hovered, pressed,
// selected, enabled). Every component used to write its own state ternary
// and its own Behavior, and four of them disagreed on the selected tint.
//
//     background: Surface { base: Style.surface; hovered: root.hovered; selected: root.checked }
//
// `pressed` is for bodies that cannot grow (rows, text); a control that grows
// through StateLayer leaves it false. `contentColor` is what text and glyphs
// on this body wear: accent while selected, the text role otherwise, dimmed
// with the body.
Rectangle {
    id: root

    property color base: Style.surface
    property color accent: Style.accent
    property bool hovered: false
    property bool pressed: false
    property bool selected: false

    readonly property color contentColor: root.enabled
        ? (root.selected ? root.accent : Style.text)
        : Style.disabled(root.selected ? root.accent : Style.text)

    color: Style.tone(root.base, root.hovered, root.pressed, root.selected, root.enabled, root.accent)

    Behavior on color {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }
}
