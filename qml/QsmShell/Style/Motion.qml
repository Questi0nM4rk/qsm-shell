pragma Singleton

import QtQuick

import qs.QsmShell.Style

QtObject {
    readonly property int press: Style.reducedMotion ? 40 : Tokens.motionPress
    readonly property int micro: Style.reducedMotion ? 60 : Tokens.motionMicro
    readonly property int fast: Style.reducedMotion ? 80 : Tokens.motionFast
    readonly property int standardEasing: Easing.OutCubic
    readonly property int emphasizedEasing: Easing.OutQuart
}
