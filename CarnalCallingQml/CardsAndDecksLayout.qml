import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14
import JoipEngine 1.3
import JOIP.core 1.5
import JOIP.db 1.1
import CarnalCallingQml 1.0

Rectangle {
    id: layout
    anchors.fill: parent
    color: "transparent"

    property int spacing: 5
    property bool isLandscape: { return width > height; }

    property Project currentlyLoadedProject: root.currentlyLoadedProject

    Rectangle {
        id: gridWrapper
        color: "transparent"

        property real offsetX: hexBgRenderer.x
        property real offsetY: hexBgRenderer.y
        readonly property alias numRows: hexBgRenderer.numRows
        readonly property alias numCols: hexBgRenderer.numCols

        x: StyleParams.dominantHand === DominantHand.Left ?
               notificationRect.x + notificationRect.width - offsetX - StyleParams.hexWidth * 0.25 :
               offsetX + StyleParams.hexWidth * 0.25
        y: numCols %2 == 1 ?
               (StyleParams.dominantHand === DominantHand.Left ?
                    notificationRect.offsetY + offsetY + StyleParams.hexHeight/2 :
                    notificationRect.offsetY + offsetY):
               (StyleParams.dominantHand === DominantHand.Left ?
                    notificationRect.offsetY + offsetY + StyleParams.hexHeight :
                    notificationRect.offsetY + offsetY + StyleParams.hexHeight)
        width: StyleParams.dominantHand === DominantHand.Left ?
                   parent.width - notificationRect.x - notificationRect.width :
                   notificationRect.x
        height: numCols %2 == 1 ?
                    (StyleParams.dominantHand === DominantHand.Left ?
                        parent.height - notificationRect.offsetY - StyleParams.hexHeight :
                        parent.height - notificationRect.offsetY - StyleParams.hexHeight) :
                    (StyleParams.dominantHand === DominantHand.Left ?
                         parent.height - notificationRect.offsetY - StyleParams.hexHeight*3/2 :
                         parent.height - notificationRect.offsetY - StyleParams.hexHeight*3/2)

        HexGridRenderer {
            id: hexBgRenderer
            anchors.centerIn: parent
            width: gridWidth - hexWidth / 2
            height: gridHeight
            widthHint: parent.width
            heightHint: parent.height

            color: "transparent"

            hexWidth: StyleParams.hexWidth
            hexHeight: StyleParams.hexHeight
            lineWeight: StyleParams.strokeColorHexInactiveWidth/2

            hexFillString: StyleParams.fillColorHexInactive
            lineFillString: StyleParams.strokeColorHexInactive

            animateMouseOver: true
            gradientRendering: false
        }

        /*
        Rectangle {
            id: debugRenderer
            x: hexBg.x
            y: hexBg.y
            width: parent.width - hexBg.x *2
            height: parent.height - hexBg.y *2
            color: "transparent"
            border.color: "blue"
        }
        */

        DeckCollection {
            id: decks
            x: 0
            y: 0
            width: parent.width
            height: parent.height

            numRows: gridWrapper.numRows
            numCols: gridWrapper.numCols
            hexBg: Qt.point(hexBgRenderer.x, hexBgRenderer.y)

            repository: repositoryLoader
        }
        CardCollection {
            id: cards
            x: 0
            y: 0
            width: parent.width
            height: parent.height

            numRows: gridWrapper.numRows
            numCols: gridWrapper.numCols
            hexBg: Qt.point(hexBgRenderer.x, hexBgRenderer.y)

            repository: repositoryLoader
        }
    }

    CCPlayerNotification {
        id: notificationRect

        y: StyleParams.hexHeight
        x: DominantHand.Left === StyleParams.dominantHand ?
               parent.spacing * 2 :
               parent.width - width - parent.spacing * 2

        width: StyleParams.hexWidth * 1.75
        height: sceneControl.y + sceneControl.height - y

        hexWidth: StyleParams.hexWidth
        hexHeight: StyleParams.hexHeight

        userName: "notification"

        onTransitionRequested: {
            switch(scene) {
            case "options":
                // todo: show options
                break;
            case "cards":
                eventReceiver.sendEventResponse("mapEvent", "Cards");
                break;
            case "decks":
                eventReceiver.sendEventResponse("mapEvent", "Decks");
                break;
            }
        }
    }

    CCPlayerTextBox {
        id: textBox;

        x: parent.spacing * 2
        y: parent.height - height
        width: parent.width - parent.spacing * 4
        height: parent.height / 3 - parent.spacing / 2
        iconWidth: StyleParams.iconWidth
        iconHeight: StyleParams.iconHeight
        hexWidth: StyleParams.hexWidth
        hexHeight: StyleParams.hexHeight
        minHeightHidden: sceneControl.height

        userName: "textBox"
        mainTextBox: true
        hideLogAfterInactivity: true
    }

    CCPlayerControls {
        id: sceneControl

        x: textBox.x
        y: textBox.y - height / 3
        width: textBox.width
        height: StyleParams.hexHeight * 1.5

        buttonWidth: StyleParams.hexWidth
        buttonHeight: StyleParams.hexHeight

        exitButton.visible: true
        pauseButton.visible: false
        hideButton.visible: false

        quit: function()
        {
            eventReceiver.sendEventResponse("cardEvent", "");
        }

        onSetUiVisible: {
            notificationRect.opacity = visible ? 1.0 : 0.0;
            textBox.opacity = visible ? 1.0 : 0.0;
        }
    }

    PlayerEventCommunicator {
        id: eventReceiver;
    }

    DataRepository {
        id: repositoryLoader
        currentlyLoadedProject: layout.currentlyLoadedProject
    }

    function handleLoadCards(sData)
    {
        let cardData = JSON.parse(sData);
        textBox.state = "HIDDEN";
        decks.visible = false;
        cards.showWith(null != cardData.ownedCards ? cardData.ownedCards : null);
    }
    function handleLoadDecks(sData)
    {
        let deckData = JSON.parse(sData);
        textBox.state = "HIDDEN";
        decks.showWith(null != deckData.ownedDecks ? deckData.ownedDecks : null);
        cards.initWith(null != deckData.ownedCards ? deckData.ownedCards : null);
        cards.visible = false;
    }

    Component.onCompleted: {
        StyleParams.currentProjectId = currentlyLoadedProject.id;
        eventReceiver.registerEventHandler("loadCards", handleLoadCards);
        eventReceiver.registerEventHandler("loadDecks", handleLoadDecks);
    }
}
