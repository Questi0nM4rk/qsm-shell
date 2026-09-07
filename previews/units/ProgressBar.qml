import qs.QsmShell.Components

ProgressBar {
    property string variant: ""

    implicitWidth: 300
    value: .62
    indeterminate: variant === "unknown"

    readonly property var controls: [
        { label: "state", options: [
            { label: "rest",    set: { indeterminate: false, value: 0.62 } },
            { label: "unknown", set: { indeterminate: true } },
            { label: "full",    set: { indeterminate: false, value: 1 } }
        ]}
    ]
}
