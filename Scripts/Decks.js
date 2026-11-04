import "Types.js"

let dataToSend = 
    { 
        "ownedCards": [
        ], 
        "ownedDecks": [
            {
                "id": 0,
                "name":"Testaaaaaaaa",
                "deck": [],
                "sideDeck": [],
                "displayCard": {"setId": "chr_0", "id": 0},
                "gendering": -1,
                "numSocial": 0,
                "numAction": 0,
                "tags": []
            }
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
eventSender.sendEvent("loadDecks", dataToSend);