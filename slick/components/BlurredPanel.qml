// A panel showing the background behind it blurred and tinted, as Slick
// Greeter draws its top bar, login box and shutdown dialog.
import QtQuick
import QtQuick.Effects

Item {
    id: panel

    // The sharp background, filling the window
    property Item source
    property real radius: 0
    property color tint: Qt.rgba(0.1, 0.1, 0.1, 0.55)
    property color borderColor: "transparent"
    property real borderWidth: 0

    // Background grabbed around the panel too, so the blur has no dark edge
    readonly property real pad: 32

    Item {
        id: blurred
        anchors.fill: parent
        visible: false
        layer.enabled: true
        clip: true

        ShaderEffectSource {
            x: -panel.pad
            y: -panel.pad
            width: panel.width + 2 * panel.pad
            height: panel.height + 2 * panel.pad
            sourceItem: panel.source
            sourceRect: {
                // Re-evaluated when the panel moves or resizes
                var unused = panel.x + panel.y + panel.width + panel.height;
                var p = panel.source ? panel.mapToItem(panel.source, 0, 0)
                                     : Qt.point(0, 0);
                return Qt.rect(p.x - panel.pad, p.y - panel.pad, width, height);
            }
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 16
            }
        }
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: panel.radius
        antialiasing: true
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        source: blurred
        maskEnabled: panel.radius > 0
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Rectangle {
        anchors.fill: parent
        radius: panel.radius
        antialiasing: true
        color: panel.tint
        border.color: panel.borderColor
        border.width: panel.borderWidth
    }
}
