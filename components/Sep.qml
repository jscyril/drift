import QtQuick
import "../services"

// Dotted vertical separator.
Column {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    spacing: 2
    leftPadding: 4
    rightPadding: 4
    Repeater {
        model: 5
        Rectangle { width: 1; height: 2; color: Theme.alpha(Theme.accent, 0.45) }
    }
}
