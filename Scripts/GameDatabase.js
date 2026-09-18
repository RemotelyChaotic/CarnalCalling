function setupDatabase() {

    let mapLocations = include("MapData.json");
    let cardData = include("CardData.json");
    let packData = include("PackData.json");
    localStorage.store("mapLocations", mapLocations);
    localStorage.store("cardData", cardData);
    localStorage.store("packData", packData);
}

export { setupDatabase }
