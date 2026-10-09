import "Types.js"

let dataToSend = 
    { 
        "ownedCards": [
            {
                "id": 0,
                "setId": "chr_0",
                "count": 1
            }/*,
            {
                "id": 1,
                "setId": "chr_0",
                "count": 2
            }*/
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