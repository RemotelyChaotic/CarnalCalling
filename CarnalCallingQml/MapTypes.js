.pragma library

function ConnectionStop(objConstr) {
    this.x = objConstr.x;
    this.y = objConstr.y;
}

function Connection(objConstr) {
    this.id = objConstr.id;
    this.from = objConstr.from;
    this.to = objConstr.to;
    this.stops = [];
    for (var i = 0; objConstr.stops.length > i; ++i) {
        this.stops.push(new ConnectionStop(objConstr.stops[i]));
    }
}

function Place(objConstrOrId, _x, _y, _name, _scene, _icon) {
    if (typeof objConstrOrId === "object") {
        this.id = objConstrOrId.id;
        this.x = objConstrOrId.x;
        this.y = objConstrOrId.y;
        this.name = objConstrOrId.name;
        this.scene = objConstrOrId.scene;
        this.icon = objConstrOrId.icon;
    } else {
        this.id = objConstrOrId;
        this.x = _x;
        this.y = _y;
        this.name = _name;
        this.scene = _scene;
        this.icon = _icon;
    }
}

function Map(objOrName, _placesArr, _connArr) {
    if (typeof objOrName === "object") {
        this.name = objOrName.name;
        this.places = [];
        this.connections = [];
        for (let i = 0; objOrName.places.length > i; ++i) {
            this.places.push(new Place(objOrName.places[i]));
        }
        for (let i = 0; objOrName.connections.length > i; ++i) {
            this.connections.push(new Connection(objOrName.connections[i]));
        }
    } else {
        this.name = objOrName;
        this.places = _placesArr;
        this.connections = _connArr;
    }
}

Map.prototype.addPlace = function(place) {
    this.places.push(place);
}
Map.prototype.removePlace = function(index) {
    return this.places.splice(index, 1);
}

Map.prototype.addConnection = function(conn) {
    this.connections.push(conn);
}
Map.prototype.removeConnection = function(index) {
    return this.connections.splice(index, 1);
}