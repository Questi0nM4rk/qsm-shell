import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property var previewEnvironment: null
    property real preferredWidth: 0
    property real preferredHeight: 0
    property string edge: "bottom"
    property string alignment: "center"
    property real inset: Style.space4
    default property alias overlayData: overlay.data
    readonly property alias overlayBody: overlay

    readonly property bool environmentSupported: previewEnvironment !== null
    readonly property bool fullscreen: environmentSupported && previewEnvironment.fullscreen === true
    readonly property rect screenRect: environmentSupported
        ? previewEnvironment.screenRect : Qt.rect(x, y, width, height)
    readonly property var placement: place(screenRect, preferredWidth, preferredHeight,
                                            edge, alignment, inset)
    readonly property rect bodyRect: placement.rect
    readonly property bool constrained: placement.constrained
    readonly property bool emptyPlacement: placement.empty

    function place(bounds, bodyWidth, bodyHeight, placementEdge, placementAlignment, spacing) {
        const safeInset = Math.max(0, Number(spacing) || 0)
        const left = bounds.x + safeInset
        const top = bounds.y + safeInset
        const availableWidth = Math.max(0, bounds.width - safeInset * 2)
        const availableHeight = Math.max(0, bounds.height - safeInset * 2)
        const width = Math.min(Math.max(0, Number(bodyWidth) || 0), availableWidth)
        const height = Math.min(Math.max(0, Number(bodyHeight) || 0), availableHeight)
        const vertical = placementEdge === "left" || placementEdge === "right"
        const span = vertical ? availableHeight : availableWidth
        const length = vertical ? height : width
        const offset = placementAlignment === "start" ? 0
            : placementAlignment === "end" ? span - length : (span - length) / 2
        const x = placementEdge === "left" ? left
            : placementEdge === "right" ? left + availableWidth - width
            : left + offset
        const y = placementEdge === "top" ? top
            : placementEdge === "bottom" ? top + availableHeight - height
            : top + offset
        const empty = availableWidth <= 0 || availableHeight <= 0 || width <= 0 || height <= 0

        return {
            rect: Qt.rect(x, y, width, height),
            constrained: empty || width !== Number(bodyWidth) || height !== Number(bodyHeight),
            empty: empty
        }
    }

    Rectangle {
        id: application
        x: root.screenRect.x - root.x + (root.fullscreen ? 0 : Style.frameThickness)
        y: root.screenRect.y - root.y + (root.fullscreen ? 0 : Style.frameThickness)
        width: Math.max(0, root.screenRect.width - (root.fullscreen ? 0 : Style.frameThickness * 2))
        height: Math.max(0, root.screenRect.height - (root.fullscreen ? 0 : Style.frameThickness * 2))
        color: Style.surface
    }

    ShellBorder {
        x: root.screenRect.x - root.x
        y: root.screenRect.y - root.y
        width: root.screenRect.width
        height: root.screenRect.height
        visible: !root.fullscreen
    }

    Text {
        x: root.screenRect.x - root.x + Style.space4
        y: root.screenRect.y - root.y + Style.space4
        text: root.fullscreen ? "Simulated application fullscreen" : "Simulated desktop"
        color: Style.textMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.textSm
    }

    Item {
        id: overlay
        x: root.bodyRect.x - root.x
        y: root.bodyRect.y - root.y
        width: root.bodyRect.width
        height: root.bodyRect.height
        visible: !root.emptyPlacement
        enabled: visible
    }
}
