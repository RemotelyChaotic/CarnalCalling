import "Types.js"

let dataToSend = 
    { 
        "ownedCards": [
        ], 
        "ownedDecks": [
            {"name":"Test", "cards": []}
        ]
    };

function cardEventHandler(evtName, evtData) {
    // Debug
    textBox.showText(evtData, -1, true);
}

background.setBackgroundTexture(null);
eventSender.registerEventHandler("cardEvent", cardEventHandler);
eventSender.sendEvent("loadCards", dataToSend);