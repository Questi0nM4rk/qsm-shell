import qs.QsmShell.Components

ProgressBar {
    property string variant: ""

    implicitWidth: 300
    value: .62
    indeterminate: variant === "unknown"
}
