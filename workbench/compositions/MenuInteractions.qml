pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

// A native composition, not a new shell component or a production service host.
FocusScope {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property string size: "md"
    property string query: ""
    property string expandedId: ""
    property real volume: 0.5
    property bool muted: false
    property bool wifiEnabled: true
    property bool bluetoothEnabled: true
    property string password: ""
    property bool rememberNetwork: false
    property string wifiPhase: "idle"
    property string wifiError: ""
    property string connectedNetwork: ""
    property string blePhase: "idle"
    property bool mouseConnected: true
    property bool mousePaired: true
    property string scanPhase: "idle"
    property bool failReply: false
    property bool disabled: false
    property bool bindingOverride: false
    property int activations: 0
    property int movements: 0
    property int commits: 0
    // Local fixture latency, not an animation duration or a real network timeout.
    property int simulatedLatency: 650

    readonly property string selectedId: menu.rowAt(menu.currentIndex)?.objectName ?? ""
    readonly property bool editorOpen: expandedId === "output-volume"

    implicitWidth: Style.controlWidth + Style.controlWidth / 2
    implicitHeight: Style.controlWidth * 2

    component Entry: ListRow {
        required property string identity
        objectName: identity
        size: root.size
        visible: root.matches(primary)
        recede: false
        focused: selected && (menu.activeFocus || activeFocus)
        expanded: root.expandedId === identity
        onHoveredEntered: root.select(identity, false)
    }

    component Chevron: SvgIcon {
        required property bool opened
        name: "chevron-down"
        size: Style.iconSm
        rotation: opened ? 180 : 0
        Behavior on rotation {
            enabled: !Style.reducedMotion
            NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space3
        spacing: Style.space2

        Prose { role: "section"; text: "Shell items · Menu composition" }
        Prose { role: "metadata"; text: "Local examples only · no hardware changes or saved passwords" }

        TextField {
            id: search
            Layout.fillWidth: true
            size: root.size
            placeholder: "Filter menu items"
            Accessible.name: "Filter menu items"
            text: root.query
            onEdited: text => root.query = text
            onKeyPressed: event => {
                if (event.key !== Qt.Key_Up && event.key !== Qt.Key_Down) return
                menu.currentIndex = -1
                root.navigate(event.key === Qt.Key_Down ? 1 : -1)
                event.accepted = true
            }
        }

        Surface {
            Layout.fillWidth: true
            Layout.fillHeight: true
            base: Style.surfaceRaised
            radius: Style.radiusLg

            ScrollArea {
                id: scroll
                anchors.fill: parent
                anchors.margins: Style.space2
                fadeColor: Style.surfaceRaised
                fadeDepth: Style.space4

                Menu {
                    id: menu
                    width: scroll.viewport.width
                    spacing: 0
                    clip: false
                    onActivated: index => root.activateItem(menu.rowAt(index).objectName)
                    onCurrentIndexChanged: {
                        const row = menu.rowAt(currentIndex)
                        if (!row) return
                        if (root.expandedId && root.expandedId !== row.objectName)
                            root.expandedId = ""
                        row.forceActiveFocus()
                        root.revealSelection()
                    }
                    onImplicitHeightChanged: layoutSync.restart()

                    ListRow { header: true; primary: "Audio"; recede: false }
                    Entry {
                        id: volumeRow
                        identity: "output-volume"
                        primary: "Output volume"
                        icon: "volume"
                        disabled: root.disabled
                        Prose { role: "reading"; text: Math.round(root.volume * 100) + "%" }
                        Chevron { opened: volumeRow.expanded }
                        expandedContent: Slider {
                            id: slider
                            Layout.fillWidth: true
                            size: root.size
                            value: root.volume
                            enabled: root.editorOpen && !root.disabled
                            Accessible.name: "Output volume"
                            decreaseKey: root.bindingOverride ? Qt.Key_H : Interaction.sliderDecreaseKey
                            increaseKey: root.bindingOverride ? Qt.Key_L : Interaction.sliderIncreaseKey
                            onKeyPressed: event => root.editorKey(event, true)
                            onMoved: {
                                root.volume = value
                                root.movements++
                                root.record("intent", "moved", { identity: "output-volume", value: value })
                            }
                            onCommitted: {
                                root.commits++
                                root.record("intent", "committed", { identity: "output-volume", value: root.volume })
                            }
                        }
                    }
                    Entry {
                        id: muteRow
                        identity: "mute-output"
                        primary: "Mute output"
                        icon: root.muted ? "volume-muted" : "volume"
                        disabled: root.disabled
                        Switch {
                            id: muteSwitch
                            size: root.size
                            checked: root.muted
                            enabled: muteRow.selectable
                            Accessible.name: "Mute output"
                            onToggleRequested: checked => { root.select("mute-output"); root.setMute(checked) }
                            Keys.onPressed: event => root.editorKey(event, false)
                        }
                    }
                    Entry {
                        identity: "audio-reading"
                        primary: "Built-in speakers"
                        supporting: "Current output · report only"
                        icon: "monitor"
                        interactive: false
                        Prose { role: "reading"; text: "48 kHz" }
                    }

                    ListRow { header: true; primary: "Wi-Fi"; recede: false }
                    Entry {
                        id: wifiRadio
                        identity: "wifi-radio"
                        primary: "Wi-Fi radio"
                        icon: "wifi"
                        Switch {
                            id: wifiSwitch
                            size: root.size
                            checked: root.wifiEnabled
                            Accessible.name: "Wi-Fi radio"
                            onToggleRequested: checked => { root.select("wifi-radio"); root.setWifi(checked) }
                            Keys.onPressed: event => root.editorKey(event, false)
                        }
                    }
                    Entry {
                        id: wifiRow
                        identity: "wifi-secure"
                        primary: "Studio Wi-Fi"
                        supporting: root.wifiPhase === "connecting" ? "Connecting…"
                            : root.connectedNetwork === "Studio Wi-Fi" ? "Connected · secured network"
                            : root.wifiError || "Secured network · password required"
                        icon: "wifi"
                        disabled: !root.wifiEnabled
                        Badge {
                            text: root.connectedNetwork === "Studio Wi-Fi" ? "Connected" : "WPA2"
                            tone: root.connectedNetwork === "Studio Wi-Fi" ? "success" : "neutral"
                        }
                        Chevron { opened: wifiRow.expanded }
                        expandedContent: [
                            Field {
                                Layout.fillWidth: true
                                label: "Network password"
                                error: root.wifiError
                                required: true
                                sizeScale: passwordField.sizeScale
                                TextField {
                                    id: passwordField
                                    width: parent.width
                                    size: root.size
                                    inputType: "password"
                                    placeholder: "At least 8 characters · local demo"
                                    text: root.password
                                    failed: root.wifiError.length > 0
                                    enabled: root.wifiEnabled && root.wifiPhase !== "connecting"
                                    Accessible.name: "Studio Wi-Fi password"
                                    onEdited: text => { root.password = text; root.wifiError = "" }
                                    onKeyPressed: event => root.editorKey(event, false)
                                    onAccepted: root.submitWifi()
                                    onEscaped: root.closeEditor()
                                    trailing: ControlLabel {
                                        icon: passwordField.passwordVisible ? "eye-off" : "eye"
                                        clickable: true
                                        accessibleName: passwordField.passwordVisible ? "Hide password" : "Reveal password"
                                        onClicked: passwordField.toggleReveal()
                                        Keys.onPressed: event => root.editorKey(event, false)
                                    }
                                }
                            },
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.space3
                                Checkbox {
                                    id: remember
                                    size: root.size
                                    checked: root.rememberNetwork
                                    accessibleName: "Remember network in this example"
                                    enabled: root.wifiPhase !== "connecting"
                                    onToggleRequested: checked => root.rememberNetwork = checked
                                    Keys.onPressed: event => root.editorKey(event, false)
                                    ControlLabel { text: "Remember network"; sizeScale: remember.sizeScale }
                                }
                                Item { Layout.fillWidth: true }
                                ControlLabel {
                                    text: root.wifiPhase === "connecting" ? "Connecting…" : "Connect"
                                    clickable: true
                                    enabled: root.wifiPhase !== "connecting"
                                    onClicked: passwordField.accept()
                                    Keys.onPressed: event => root.editorKey(event, false)
                                }
                                ControlLabel {
                                    text: "Cancel"
                                    clickable: true
                                    onClicked: root.closeEditor()
                                    Keys.onPressed: event => root.editorKey(event, false)
                                }
                            }
                        ]
                    }
                    Entry {
                        identity: "wifi-open"
                        primary: "Guest Wi-Fi"
                        supporting: root.connectedNetwork === "Guest Wi-Fi" ? "Connected" : "Open network · no password"
                        icon: "wifi"
                        disabled: !root.wifiEnabled
                        Badge { text: root.connectedNetwork === "Guest Wi-Fi" ? "Connected" : "Open" }
                    }
                    Entry {
                        identity: "wifi-unavailable"
                        primary: "Saved office network"
                        supporting: "Out of range · unavailable"
                        icon: "wifi"
                        disabled: true
                    }

                    ListRow { header: true; primary: "Bluetooth / BLE"; recede: false }
                    Entry {
                        id: bluetoothRadio
                        identity: "bluetooth-radio"
                        primary: "Bluetooth radio"
                        icon: "bluetooth"
                        Switch {
                            id: bluetoothSwitch
                            size: root.size
                            checked: root.bluetoothEnabled
                            Accessible.name: "Bluetooth radio"
                            onToggleRequested: checked => { root.select("bluetooth-radio"); root.setBluetooth(checked) }
                            Keys.onPressed: event => root.editorKey(event, false)
                        }
                    }
                    Entry {
                        id: bleRow
                        identity: "ble-device"
                        primary: "Desk sensor"
                        supporting: root.blePhase === "connecting" ? "Pairing…"
                            : root.blePhase === "connected" ? "Paired · connected"
                            : root.blePhase === "failed" ? "Pairing failed · try again" : "Nearby Bluetooth LE device"
                        icon: "bluetooth"
                        disabled: !root.bluetoothEnabled
                        Badge { text: "BLE" }
                        Chevron { opened: bleRow.expanded }
                        expandedContent: RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.space2
                            Prose {
                                Layout.fillWidth: true
                                role: "metadata"
                                text: root.blePhase === "connected" ? "Ready in this example" : "Pair and connect to this device"
                            }
                            ControlLabel {
                                text: root.blePhase === "connecting" ? "Pairing…"
                                    : root.blePhase === "connected" ? "Disconnect" : "Pair"
                                clickable: true
                                enabled: root.blePhase !== "connecting"
                                onClicked: root.connectBle()
                                Keys.onPressed: event => root.editorKey(event, false)
                            }
                        }
                    }
                    Entry {
                        id: mouseRow
                        identity: "bluetooth-mouse"
                        primary: "Travel mouse"
                        supporting: !root.mousePaired ? "Forgotten · reset example to restore"
                            : root.mouseConnected ? "Connected · activate to disconnect" : "Paired · activate to connect"
                        icon: "bluetooth"
                        disabled: !root.bluetoothEnabled || !root.mousePaired
                        ControlLabel {
                            text: "Forget"
                            clickable: true
                            enabled: mouseRow.selectable
                            onClicked: {
                                root.select("bluetooth-mouse")
                                root.mouseConnected = false
                                root.mousePaired = false
                                root.record("result", "device-forgotten", { identity: "bluetooth-mouse" })
                            }
                            Keys.onPressed: event => root.editorKey(event, false)
                        }
                    }
                    ListRow { separator: true }
                    Entry {
                        identity: "rescan"
                        primary: "Rescan nearby devices"
                        supporting: root.scanPhase === "pending" ? "Scanning…"
                            : root.scanPhase === "done" ? "Scan finished · example devices unchanged" : "Wi-Fi and Bluetooth discovery"
                        icon: "search"
                        disabled: !root.wifiEnabled && !root.bluetoothEnabled
                    }
                }
                Prose {
                    width: scroll.viewport.width
                    y: menu.height + Style.space2
                    visible: !root.hasSelectableItem()
                    role: "metadata"
                    text: "No matching items"
                }
            }
        }

        Prose {
            Layout.fillWidth: true
            role: "metadata"
            text: "↑ ↓ items · Enter opens / activates · ← → or N/O adjusts · Esc returns"
        }
    }

    Timer {
        id: layoutSync
        interval: 0
        onTriggered: root.revealSelection()
    }
    Timer {
        id: editorFocus
        interval: 0
        onTriggered: {
            if (root.expandedId === "output-volume" && slider.enabled) slider.forceActiveFocus()
            else if (root.expandedId === "wifi-secure" && passwordField.enabled) passwordField.forceActiveFocus()
            root.revealSelection()
        }
    }
    Timer {
        id: querySync
        interval: 0
        onTriggered: {
            const row = menu.rowAt(menu.currentIndex)
            if (row && (!row.visible || !row.selectable)) {
                root.expandedId = ""
                menu.currentIndex = -1
            }
        }
    }
    Timer {
        id: wifiReply
        interval: root.simulatedLatency
        onTriggered: {
            root.wifiPhase = root.failReply ? "failed" : "connected"
            root.wifiError = root.failReply ? "Example connection failed. Retry or cancel." : ""
            if (!root.failReply) {
                root.connectedNetwork = "Studio Wi-Fi"
                if (root.expandedId === "wifi-secure") root.closeEditor()
                root.password = ""
            }
            root.record("result", "wifi-result", { identity: "wifi-secure", phase: root.wifiPhase })
        }
    }
    Timer {
        id: bleReply
        interval: root.simulatedLatency
        onTriggered: {
            root.blePhase = root.failReply ? "failed" : "connected"
            root.record("result", "ble-result", { identity: "ble-device", phase: root.blePhase })
        }
    }
    Timer {
        id: scanReply
        interval: root.simulatedLatency
        onTriggered: { root.scanPhase = "done"; root.record("result", "scan-result", { phase: "done" }) }
    }

    function matches(text: string): bool { return text.toLowerCase().includes(root.query.trim().toLowerCase()) }
    function record(kind, name, payload): void { root.eventRecorder?.(kind, name, payload) }
    function select(identity: string, focusItem = true): bool {
        for (let i = 0; i < menu.rowCount; i++) {
            const row = menu.rowAt(i)
            if (row.objectName !== identity || !row.visible || !row.selectable) continue
            menu.currentIndex = i
            if (focusItem) row.forceActiveFocus()
            root.revealSelection()
            return true
        }
        return false
    }
    function hasSelectableItem(): bool {
        for (let i = 0; i < menu.rowCount; i++) {
            const row = menu.rowAt(i)
            if (row.visible && row.selectable) return true
        }
        return false
    }
    function revealSelection(): void {
        const row = menu.rowAt(menu.currentIndex)
        if (!row || !row.visible) return
        const view = scroll.viewport
        const bottom = row.y + row.height
        const desired = row.y < view.contentY ? row.y
            : bottom > view.contentY + view.height ? bottom - view.height : view.contentY
        view.contentY = Math.max(0, Math.min(desired, Math.max(0, view.contentHeight - view.height)))
    }
    function navigate(delta: int): void {
        root.expandedId = ""
        menu.step(delta)
        const row = menu.rowAt(menu.currentIndex)
        if (row?.selectable && row.visible) row.forceActiveFocus()
        root.revealSelection()
    }
    function openEditor(identity: string): bool {
        if (!root.select(identity)) return false
        root.expandedId = identity
        editorFocus.restart()
        return true
    }
    function closeEditor(): bool {
        if (!root.expandedId) return false
        if (root.expandedId === "wifi-secure" && root.wifiPhase === "connecting") {
            wifiReply.stop()
            root.wifiPhase = "idle"
        }
        editorFocus.stop()
        root.expandedId = ""
        menu.rowAt(menu.currentIndex)?.forceActiveFocus()
        return true
    }
    function editorKey(event, valueEditor: bool): void {
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            root.navigate(event.key === Qt.Key_Up ? -1 : 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Escape
            || (valueEditor && (event.key === Qt.Key_Enter || event.key === Qt.Key_Return))) {
            if (!event.isAutoRepeat) root.closeEditor()
            event.accepted = true
        } else if (valueEditor && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
            root.navigate(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1)
            event.accepted = true
        }
    }
    function activateItem(identity: string): void {
        root.activations++
        root.record("intent", "activated", { identity: identity })
        if (identity === "output-volume" || identity === "wifi-secure" || identity === "ble-device") {
            if (root.expandedId === identity) root.closeEditor()
            else root.openEditor(identity)
        } else if (identity === "mute-output") muteSwitch.flip()
        else if (identity === "wifi-radio") wifiSwitch.flip()
        else if (identity === "bluetooth-radio") bluetoothSwitch.flip()
        else if (identity === "wifi-open") {
            wifiReply.stop()
            root.wifiPhase = "connected"
            root.connectedNetwork = "Guest Wi-Fi"
            root.record("result", "wifi-result", { identity: identity, phase: "connected" })
        } else if (identity === "bluetooth-mouse") {
            root.mouseConnected = !root.mouseConnected
            root.record("result", "device-toggled", { identity: identity, connected: root.mouseConnected })
        } else if (identity === "rescan" && !scanReply.running) {
            root.scanPhase = "pending"
            scanReply.start()
        }
    }
    function setMute(checked: bool): void {
        root.muted = checked
        root.record("result", "mute-toggled", { identity: "mute-output", muted: checked })
    }
    function setWifi(checked: bool): void {
        root.wifiEnabled = checked
        if (!checked) {
            wifiReply.stop()
            root.wifiPhase = "idle"
            root.connectedNetwork = ""
            if (root.expandedId.startsWith("wifi-")) root.closeEditor()
        }
        root.record("result", "wifi-radio-toggled", { enabled: checked })
    }
    function setBluetooth(checked: bool): void {
        root.bluetoothEnabled = checked
        if (!checked) {
            bleReply.stop()
            root.blePhase = "idle"
            root.mouseConnected = false
            if (root.expandedId === "ble-device") root.closeEditor()
        }
        root.record("result", "bluetooth-radio-toggled", { enabled: checked })
    }
    function submitWifi(): bool {
        if (!root.wifiEnabled || root.wifiPhase === "connecting" || root.expandedId !== "wifi-secure") return false
        if (root.password.length < 8) {
            root.wifiError = "Use at least 8 characters in this example."
            return false
        }
        root.wifiError = ""
        root.wifiPhase = "connecting"
        wifiReply.start()
        root.record("intent", "wifi-connect", { identity: "wifi-secure" })
        return true
    }
    function connectBle(): bool {
        if (!root.bluetoothEnabled || root.blePhase === "connecting" || root.expandedId !== "ble-device") return false
        if (root.blePhase === "connected") root.blePhase = "idle"
        else { root.blePhase = "connecting"; bleReply.start() }
        root.record("intent", "ble-connect", { identity: "ble-device", phase: root.blePhase })
        return true
    }
    function reset(): void {
        wifiReply.stop(); bleReply.stop(); scanReply.stop()
        editorFocus.stop(); layoutSync.stop(); querySync.stop()
        root.expandedId = ""
        root.query = ""
        root.password = ""
        root.wifiError = ""
        root.wifiPhase = "idle"
        root.blePhase = "idle"
        root.scanPhase = "idle"
        root.connectedNetwork = ""
        root.volume = 0.5
        root.muted = false
        root.wifiEnabled = true
        root.bluetoothEnabled = true
        root.mouseConnected = true
        root.mousePaired = true
        root.rememberNetwork = false
        root.disabled = false
        root.failReply = false
        root.bindingOverride = false
        root.activations = 0; root.movements = 0; root.commits = 0
        root.select("output-volume")
    }

    readonly property var controls: [
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } }, { label: "md", set: { size: "md" } }, { label: "lg", set: { size: "lg" } }
        ] },
        { label: "value", options: [
            { label: "minimum", set: { volume: 0 } }, { label: "middle", set: { volume: 0.5 } }, { label: "maximum", set: { volume: 1 } }
        ] },
        { label: "reply", options: [
            { label: "success", set: { failReply: false } }, { label: "failure / retry", set: { failReply: true } }
        ] },
        { label: "keys", options: [
            { label: "shared N/O", set: { bindingOverride: false } }, { label: "custom H/L", set: { bindingOverride: true } }
        ] },
        { label: "availability", options: [
            { label: "audio enabled", set: { disabled: false } }, { label: "audio disabled", set: { disabled: true } }
        ] },
        { label: "example", options: [{ label: "reset", call: "reset" }] }
    ]
    readonly property var actionHandlers: ({
        "step-next": () => { root.navigate(1); return true },
        "step-previous": () => { root.navigate(-1); return true },
        "activate": () => menu.activateCurrent(),
        "close-editor": () => root.closeEditor(),
        "increase": () => slider.stepBy(Style.sliderKeyboardUnits),
        "decrease": () => slider.stepBy(-Style.sliderKeyboardUnits),
        "toggle-mute": () => { if (!muteRow.selectable) return false; root.setMute(!root.muted); return true },
        "connect-wifi": () => root.submitWifi(),
        "connect-ble": () => root.connectBle()
    })
    readonly property var integration: ({
        events: ["activated", "moved", "committed", "mute-toggled", "wifi-radio-toggled", "bluetooth-radio-toggled", "wifi-connect", "wifi-result", "ble-connect", "ble-result", "device-toggled", "device-forgotten", "scan-result"],
        idle: () => !wifiReply.running && !bleReply.running && !scanReply.running,
        actions: Object.keys(root.actionHandlers),
        runAction: name => Object.prototype.hasOwnProperty.call(root.actionHandlers, name) ? root.actionHandlers[name]() : false,
        targets: {
            row: () => menu.rowAt(menu.currentIndex), browse: () => menu,
            editor: () => slider, mute: () => muteRow, "mute-switch": () => muteSwitch,
            search: () => search, "search-input": () => root.findNamed(search, "textFieldInput"),
            "editor-viewport": () => root.findNamed(volumeRow, "expandedViewport"),
            "wifi-switch": () => wifiSwitch, "wifi-row": () => wifiRow,
            "password-input": () => root.findNamed(passwordField, "textFieldInput"),
            "bluetooth-switch": () => bluetoothSwitch, "ble-row": () => bleRow
        },
        observables: {
            "selected-id": () => root.selectedId, expanded: () => root.expandedId,
            volume: () => root.volume, muted: () => root.muted,
            "wifi-enabled": () => root.wifiEnabled, "wifi-phase": () => root.wifiPhase,
            "ble-phase": () => root.blePhase, "bluetooth-enabled": () => root.bluetoothEnabled,
            "editor-focus": () => slider.activeFocus || root.findNamed(slider, "sliderHandle")?.activeFocus === true,
            "row-focus": () => menu.rowAt(menu.currentIndex)?.activeFocus === true,
            "search-focus": () => search.focused, query: () => root.query,
            activations: () => root.activations, commits: () => root.commits, "moved-count": () => root.movements
        }
    })
    function findNamed(item: Item, name: string): Item {
        if (item.objectName === name) return item
        for (const child of item.children) {
            const found = root.findNamed(child, name)
            if (found) return found
        }
        return null
    }
    onQueryChanged: querySync.restart()
    onDisabledChanged: if (root.disabled && root.editorOpen) root.closeEditor()
    Component.onCompleted: root.reset()
}
