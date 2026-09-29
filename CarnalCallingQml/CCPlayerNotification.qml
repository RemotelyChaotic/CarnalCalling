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
    signal transitionRequested(string scene)

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
        anchors.bottom: parent.bottom
        x: parent.width - width
        height: Math.floor(parent.height / parent.hexHeight) * parent.hexHeight
        width: parent.hexWidth * 1.75 // two hexes

        layoutDirection: Qt.LeftToRight
        spacing: -Math.round(notificationRect.hexHeight / 2)

        layer.enabled: Settings.playerAntialiasing
        layer.samples: 4 // (anti-aliasing)

        Repeater {
            model: hexColumn.height / notificationRect.hexHeight*2-1
            delegate: Shape {
                    Layout.preferredWidth: notificationRect.hexWidth
                    Layout.preferredHeight: notificationRect.hexHeight
                    Layout.alignment: index % 2 ? Qt.AlignLeft : Qt.AlignRight

                    opacity: 0.4

                    ShapePath {
                        fillColor: StyleParams.fillColorHexInactive
                        strokeColor: StyleParams.strokeColorHexInactive
                        strokeWidth: StyleParams.strokeColorHexInactiveWidth
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        startX: width * 0.25
                        startY: -0.5

                        PathLine { x: width * 0.75; y: -0.5 }
                        PathLine { x: width;        y: height * 0.5 }
                        PathLine { x: width * 0.75; y: height +0.5 }
                        PathLine { x: width * 0.25; y: height +0.5 }
                        PathLine { x: 0;            y: height * 0.5 }
                        PathLine { x: width * 0.25; y: -0.5 }
                }
            }
        }
    }


    CCNotificationDelegate {
        id: optionsButton
        x: parent.hexWidth * 0.75
        y: hexColumn.y
        textBoxOffset: hexWidth - 6

        text: qsTr("Options")
        toolTipText: qsTr("Options")
        imageSource: hovered ? StyleParams.optionsHoverButton : StyleParams.optionsButton

        onTriggeredButton: {
            notificationRect.transitionRequested("options");
        }
    }
    CCNotificationDelegate {
        id: devicesButton
        x: 0
        y: hexColumn.y + parent.hexHeight / 2
        textBoxOffset: -6

        text: qsTr("Devices")
        toolTipText: qsTr("Devices")
        imageSource: hovered ? StyleParams.devicesHoverButton : StyleParams.devicesButton

        onTriggeredButton: {
            var globalCoordinares = devicesButton.mapToItem(root, 0, devicesButton.height);
            TeaseDeviceController.openSelectionScreen(globalCoordinares.x, globalCoordinares.y);
        }
    }
    CCNotificationDelegate {
        id: cardsButton
        x: parent.hexWidth * 0.75
        y: hexColumn.y + parent.hexHeight
        textBoxOffset: hexWidth - 6

        text: qsTr("Card Collection")
        toolTipText: qsTr("Card Collection")
        imageSource: hovered ? StyleParams.cardsHoverButton : StyleParams.cardsButton

        onTriggeredButton: {
            notificationRect.transitionRequested("cards");
        }
    }
    CCNotificationDelegate {
        id: decksButton
        x: 0
        y: hexColumn.y + parent.hexHeight *3/2
        textBoxOffset: -6

        text: qsTr("Decks")
        toolTipText: qsTr("Decks")
        imageSource: hovered ? StyleParams.decksHoverButton : StyleParams.decksButton

        onTriggeredButton: {
            notificationRect.transitionRequested("decks");
        }
    }

    PlayerNotification {
        id: notification
        height: parent.height
        width: parent.width
        anchors.centerIn: parent
        userName: "notification"
    }
}
