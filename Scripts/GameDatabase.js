function setupDatabase() {

    let mapLocations = include("MapData.json");
    let cardData = include("CardData.json");
    let packData = include("PackData.json");
    //console.log("setupDatabase: mapLocations: ", JSON.stringify(mapLocations));
    //console.log("setupDatabase: cardData: ", JSON.stringify(cardData));
    //console.log("setupDatabase: packData: ", JSON.stringify(packData));
    localStorage.store("mapLocations", mapLocations);
    localStorage.store("cardData", cardData);
    localStorage.store("packData", packData);
}

export { setupDatabase }
