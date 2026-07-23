import "Types.js"

let mapLocations = localStorage.load("mapLocations");
let wMap = mapLocations["WorldMap"];
let dataToSend = { "resource": "WorldMap", "data": wMap, "current": 0 };

function mapEventHandler(evtName, evtData) {

}

background.setBackgroundTexture("CloudsTileable");
eventSender.registerEventHandler("mapEvent", mapEventHandler);
eventSender.sendEvent("openMap", dataToSend);