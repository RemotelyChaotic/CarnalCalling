function setupDatabase() {

    let mapLocations = include("MapData.json");
    let cardData = include("CardData.json");
    localStorage.store("mapLocations", mapLocations);
    localStorage.store("cardData", cardData);
}

export { setupDatabase }
