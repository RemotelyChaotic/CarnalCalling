import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Shapes 1.14
import QtGraphicalEffects 1.14
import JoipEngine 1.3
import JOIP.core 1.5
import JOIP.db 1.1
import JOIP.script 1.1

Rectangle {
    id: notificationRect
    color: "transparent"

    property alias userName: notification.userName

    property Project currentlyLoadedProject: root.currentlyLoadedProject

    property real hexWidth: StyleParams.hexWidth
    property real hexHeight: StyleParams.hexHeight
    property string glowHexColor: StyleParams.glowHexColor
    property int glowHexRadius: StyleParams.glowHexRadius
    property int glowHexSpread: StyleParams.glowHexSpread

    signal transitionRequested(string scene)

    readonly property real offsetY: hexColumn.y

    function showNotification(sId, sTitle, sButtonText, iTimeS, sOnButton, sOnTimeout)
    {
        notification.showNotification(sId, sTitle, sButtonText, iTimeS, sOnButton, sOnTimeout);
    }

    function removeNotificaiton(sId)
    {
        notification.removeNotificaiton(sId);
    }

    /*
    Rectangle {
        id: bDEBUG
        color: "blue"
        anchors.bottom: parent.bottom
        x: hexColumn.x
        width: hexColumn.width
        height: hexColumn.height
    }*/

    ColumnLayout {
        id: hexColumn
        y: parent.height - height -
           (StyleParams.dominantHand === DominantHand.Left ? parent.hexHeight/2 : 0)
        x: parent.width - width
        height: Math.floor(parent.height / parent.hexHeight) * parent.hexHeight
        width: parent.hexWidth * 1.75 // two hexes

        layoutDirection: Qt.LeftToRight
        spacing: -Math.round(notificationRect.hexHeight / 2)-1 // -1 to overlap borders

        layer.enabled: Settings.playerAntialiasing
        layer.samples: 4 // (anti-aliasing)

        Repeater {
            model: hexColumn.height / notificationRect.hexHeight*2-1
            delegate: HexShape {
                Layout.preferredWidth: notificationRect.hexWidth
                Layout.preferredHeight: notificationRect.hexHeight
                Layout.alignment: index % 2 ? Qt.AlignLeft : Qt.AlignRight

                opacity: 0.4

                fillColor: StyleParams.fillColorHexInactive
                strokeColor: StyleParams.strokeColorHexInactive
                strokeWidth: StyleParams.strokeColorHexInactiveWidth
            }
        }
    }

    // glow
    Component {
        id: glowComponent

        Item {
            width: notificationRect.hexWidth - 2
            height: notificationRect.hexHeight - 2

            HexShape {
                id: glowShape
                anchors.fill: parent
                fillColor: notificationRect.glowHexColor
            }

            Glow {
                anchors.fill: glowShape
                source: glowShape
                radius: notificationRect.glowHexRadius
                samples: 15
                color: notificationRect.glowHexColor
                spread: notificationRect.glowHexSpread
            }
        }
    }

    Repeater {
        model: [
            optionsButton,
            devicesButton,
            cardsButton,
            decksButton
        ]
        delegate: Loader {
            id: optionsGlow
            x: modelData.x+1
            y: modelData.y+1
            sourceComponent: glowComponent

            opacity: modelData.hovered ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    HexButtonWithToolTip {
        id: optionsButton
        x: parent.hexWidth * 0.75
        y: hexColumn.y
        textBoxOffset: hexWidth - 6
        orientation: StyleParams.dominantHand === DominantHand.Right ?
                         HexButtonWithToolTip.Left : HexButtonWithToolTip.Right
        glowHexColor: notificationRect.glowHexColor

        text: qsTr("Options")
        toolTipText: qsTr("Options")
        imageSource: hovered ? StyleParams.optionsHoverButton : StyleParams.optionsButton

        onTriggeredButton: {
            notificationRect.transitionRequested("options");
        }
    }
    HexButtonWithToolTip {
        id: devicesButton
        x: 0
        y: hexColumn.y + parent.hexHeight / 2
        textBoxOffset: orientation === DominantHand.Left ? hexWidth*1.5 + 6 : -6
        orientation: StyleParams.dominantHand === DominantHand.Right ?
                         HexButtonWithToolTip.Left : HexButtonWithToolTip.Right
        glowHexColor: notificationRect.glowHexColor

        text: qsTr("Devices")
        toolTipText: qsTr("Devices")
        imageSource: hovered ? StyleParams.devicesHoverButton : StyleParams.devicesButton

        onTriggeredButton: {
            var globalCoordinares = devicesButton.mapToItem(root, 0, devicesButton.height);
            TeaseDeviceController.openSelectionScreen(globalCoordinares.x, globalCoordinares.y);
        }
    }
    HexButtonWithToolTip {
        id: cardsButton
        x: parent.hexWidth * 0.75
        y: hexColumn.y + parent.hexHeight
        textBoxOffset: hexWidth - 6
        orientation: StyleParams.dominantHand === DominantHand.Right ?
                         HexButtonWithToolTip.Left : HexButtonWithToolTip.Right
        glowHexColor: notificationRect.glowHexColor

        text: qsTr("Card Collection")
        toolTipText: qsTr("Card Collection")
        imageSource: hovered ? StyleParams.cardsHoverButton : StyleParams.cardsButton

        onTriggeredButton: {
            notificationRect.transitionRequested("cards");
        }
    }
    HexButtonWithToolTip {
        id: decksButton
        x: 0
        y: hexColumn.y + parent.hexHeight *3/2
        textBoxOffset: orientation === DominantHand.Left ? hexWidth*1.5 + 6 : -6
        orientation: StyleParams.dominantHand === DominantHand.Right ?
                         HexButtonWithToolTip.Left : HexButtonWithToolTip.Right
        glowHexColor: notificationRect.glowHexColor

        text: qsTr("Decks")
        toolTipText: qsTr("Decks")
        imageSource: hovered ? StyleParams.decksHoverButton : StyleParams.decksButton

        onTriggeredButton: {
            notificationRect.transitionRequested("decks");
        }
    }

    PlayerNotification {
        id: notification
        x: 0
        y: decksButton.y + decksButton.height
        height: parent.height - (decksButton.y + decksButton.height)
        width: parent.width
        userName: "notification"
    }
}
