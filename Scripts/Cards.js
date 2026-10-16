import "Types.js"

let dataToSend = 
    { 
        "ownedCards": [
        ], 
        "ownedDecks": [
            {"name":"Test", "cards": []}
        ]
    };

for (let card of localStorage.load("cardData").Cards) {
    let addedCard = {
                "id": card.id,
                "setId": card.setId,
                "count": Math.floor(Math.random() * 10 + 1)
            };
    dataToSend["ownedCards"].push(addedCard);
}

function cardEventHandler(evtName, evtData) {
    // Debug
    textBox.showText(evtData, -1, true);
}

background.setBackgroundTexture(null);
eventSender.registerEventHandler("cardEvent", cardEventHandler);
eventSender.sendEvent("loadCards", dataToSend);