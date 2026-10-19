import QtQuick
import "../services"

// Tabular number label, vertically centered in its row.
Label {
    font.features: { "tnum": 1 }
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
}
