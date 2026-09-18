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

    CCPlayerNotification {
        id: notificationRect

        y: StyleParams.hexWidth
        x: DominantHand.Left === StyleParams.dominantHand ? parent.spacing * 2 + 48 : parent.width - width - parent.spacing * 2

        width: StyleParams.hexWidth * 1.75
        height: sceneControl.y - y + 48

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

        userName: "textBox"
        mainTextBox: true
        hideLogAfterInactivity: true

        Behavior on y {
            NumberAnimation { duration: 500; easing.type: Easing.OutBack}
        }

        states: [
            State {
                name: "VISIBLE"
                PropertyChanges { target: textBox; y: parent.height - height; }
            },
            State {
                name: "HIDDEN"
                PropertyChanges { target: textBox; y: parent.height - sceneControl.height + layout.spacing + 2; }
            }
        ]
    }

    CCPlayerControls {
        id: sceneControl

        x: textBox.x
        y: textBox.y - height / 2
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

    function handleLoadCards(sData)
    {
        let cardData = JSON.parse(sData);
        textBox.state = "HIDDEN";
    }
    function handleLoadDecks(sData)
    {
        let deckData = JSON.parse(sData);
        textBox.state = "HIDDEN";
    }

    Component.onCompleted: {
        StyleParams.currentProjectId = currentlyLoadedProject.id;
        eventReceiver.registerEventHandler("loadCards", handleLoadCards);
        eventReceiver.registerEventHandler("loadDecks", handleLoadDecks);
    }
}
