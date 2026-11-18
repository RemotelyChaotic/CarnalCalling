function setupDatabase() {

    let cardData = include("CardData.json");
    let keywordData = include("KeywordData.json");
    let mapLocations = include("MapData.json");
    let packData = include("PackData.json");

    localStorage.store("cardData", cardData);
    localStorage.store("keywordData", keywordData);
    localStorage.store("mapLocations", mapLocations);
    localStorage.store("packData", packData);
}

export { setupDatabase }
