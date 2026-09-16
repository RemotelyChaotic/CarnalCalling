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

    property int hexWidth: StyleParams.hexWidth
    property int hexHeight: StyleParams.hexHeight
    signal transitionRequested(string scene)

    function showNotification(sId, sTitle, sButtonText, iTimeS, sOnButton, sOnTimeout)
    {
        notification.showNotification(sId, sTitle, sButtonText, iTimeS, sOnButton, sOnTimeout);
    }

    function removeNotificaiton(sId)
    {
        notification.removeNotificaiton(sId);
    }

    ColumnLayout {
        id: hexColumn
        anchors.bottom: parent.bottom
        x: parent.width - width
        height: Math.round(parent.height / (parent.hexHeight * 1.75)) * parent.hexHeight * 1.75
        width: parent.hexWidth * 1.75

        layoutDirection: Qt.LeftToRight
        spacing: -notificationRect.hexHeight / 2

        Repeater {
            model: notificationRect.height / notificationRect.hexHeight*2
            delegate: Shape {
                    Layout.preferredWidth: notificationRect.hexWidth
                    Layout.preferredHeight: notificationRect.hexHeight
                    Layout.alignment: index % 2 ? Qt.AlignLeft : Qt.AlignRight

                    opacity: 0.4

                    layer.enabled: Settings.playerAntialiasing
                    layer.samples: 4 // (anti-aliasing)

                    ShapePath {
                        fillColor: StyleParams.fillColorHexInactive
                        strokeColor: StyleParams.strokeColorHexInactive
                        strokeWidth: StyleParams.strokeColorHexInactiveWidth
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        startX: width * 0.25
                        startY: 0

                        PathLine { x: width * 0.75; y: 0 }
                        PathLine { x: width;        y: height * 0.5 }
                        PathLine { x: width * 0.75; y: height }
                        PathLine { x: width * 0.25; y: height }
                        PathLine { x: 0;            y: height * 0.5 }
                        PathLine { x: width * 0.25; y: 0 }
                }
            }
        }
    }

    PlayerNotification {
        id: notification
        height: parent.height
        width: parent.width
        anchors.centerIn: parent
        userName: "notification"
    }

    HexButton {
        id: optionsButton
        x: parent.hexWidth *3/4
        y: hexColumn.y
        width: parent.hexWidth
        height: parent.hexHeight

        display: AbstractButton.IconOnly

        toolTipText: qsTr("Options")
        imageSource: hovered ? StyleParams.optionsHoverButton : StyleParams.optionsButton

        onTriggeredButton: {
            notificationRect.transitionRequested("options");
        }
    }
    HexButton {
        id: cardsButton
        x: 0
        y: hexColumn.y + parent.hexHeight / 2
        width: parent.hexWidth
        height: parent.hexHeight

        display: AbstractButton.IconOnly

        toolTipText: qsTr("Card Collection")
        imageSource: hovered ? StyleParams.cardsHoverButton : StyleParams.cardsButton

        onTriggeredButton: {
            notificationRect.transitionRequested("cards");
        }
    }
    HexButton {
        id: decksButton
        x: parent.hexWidth *3/4
        y: hexColumn.y + parent.hexHeight
        width: parent.hexWidth
        height: parent.hexHeight

        display: AbstractButton.IconOnly

        toolTipText: qsTr("Decks")
        imageSource: hovered ? StyleParams.decksHoverButton : StyleParams.decksButton

        onTriggeredButton: {
            notificationRect.transitionRequested("decks");
        }
    }
    TextItemFormated {
        id: textOptions
        x: optionsButton.hovered ? 0 - width - 6 : optionsButton.x
        y: optionsButton.y
        height: optionsButton.height
        maximumWidth: 200

        opacity: optionsButton.hovered ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad}
        }
        Behavior on x {
            NumberAnimation { duration: 500; easing.type: Easing.OutBack}
        }

        text: qsTr("Options")
        textColor: StyleParams.textColorMenu
        pointSize: StyleParams.menuTextPonintSize
    }
    TextItemFormated {
        id: textCards
        x: cardsButton.hovered ? 0 - width - 6 : cardsButton.x
        y: cardsButton.y
        height: cardsButton.height
        maximumWidth: 200

        opacity: cardsButton.hovered ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad}
        }
        Behavior on x {
            NumberAnimation { duration: 500; easing.type: Easing.OutBack}
        }

        text: qsTr("Card Collection")
        textColor: StyleParams.textColorMenu
        pointSize: StyleParams.menuTextPonintSize
    }
    TextItemFormated {
        id: textDecks
        x: decksButton.hovered ? 0 - width - 6 : decksButton.x
        y: decksButton.y
        height: decksButton.height
        maximumWidth: 200

        opacity: decksButton.hovered ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad}
        }
        Behavior on x {
            NumberAnimation { duration: 500; easing.type: Easing.OutBack}
        }

        text: qsTr("Decks")
        textColor: StyleParams.textColorMenu
        pointSize: StyleParams.menuTextPonintSize
    }
}