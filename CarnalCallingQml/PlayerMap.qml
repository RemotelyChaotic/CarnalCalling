import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Shapes 1.14
import QtGraphicalEffects 1.14
import JoipEngine 1.8
import JOIP.core 1.5
import JOIP.db 1.1
import JOIP.ui 1.1
import CarnalCallingQml 1.0
import "AStarBidirectional.js" as AStar

Rectangle {
    id: map
    color: "transparent"

    property int placeWidth: 50
    property int placeHeight: 50
    property int travelDuration: 3000

    property string colorCurrentPlace: "#ff00ff"
    property string colorTravel: "#ff00ff"
    property string primaryColorSelection: "#ff00ff"
    property string secondaryColorSelection: "#660066"
    property string tertiaryColorSelection: "#880088"

    property string unknownMap: "UnknownSvg"
    property string unknownIcon: "UnknownSvg"
    property string fogTexture: "Clouds"
    property int fogTextureWidth: 524
    property int fogTextureHeight: 265

    property bool lockZoom : false

    enum EMapObjType { Place = 0, Path = 1, Player = 2, PathInterpolator = 3 }

    Item {
        id: mapPrivates

        property Project currentlyLoadedProject: root.currentlyLoadedProject
        // MapTypes.Map expected
        property var mapData: null

        property int currentPlace: -1
        property var plannedTravel: null
        property bool zoomingAllowed: true

        property int explorationDataColumns: 33
        property int explorationDataRows: 22
        property var explorationData: {
            var arr = [];
            for (var r = 0; explorationDataRows > r; ++r) {
                for (var c = 0; explorationDataColumns > c; ++c) {
                    arr[c + explorationDataColumns * r] = false;
                }
            }
            return arr;
        }
        signal explorationDataUpdated()
    }

    function showWith(sResource, vMapData, current)
    {
        mapPrivates.plannedTravel = null;
        mapPrivates.currentPlace = current;
        mapPrivates.mapData = vMapData;

        if (null != sResource && "" !== sResource) {
            image.source = "image://DataBaseImageProivider/" + mapPrivates.currentlyLoadedProject.id + "/" + sResource;
        } else {
            image.source = "image://DataBaseImageProivider/" + mapPrivates.currentlyLoadedProject.id + "/" + unknownMap;
        }
    }

    function headToSelected()
    {
        if (null != mapPrivates.plannedTravel && mapPrivates.plannedTravel.connections.length > 0 &&
            mapPrivates.plannedTravel.places.length > 1) {
            if (mapPrivates.currentPlace !== mapPrivates.plannedTravel.places[mapPrivates.plannedTravel.places.length-1]) {
                let foundConnItem = null;
                for (var i = 0; image.children.length > i; ++i) {
                    if (image.children[i].objId === mapPrivates.plannedTravel.connections[0] &&
                        image.children[i].objType === PlayerMap.Path) {
                        foundConnItem = image.children[i];
                    }
                }
                if (null != foundConnItem) {
                    mapPrivates.zoomingAllowed = false;
                    foundConnItem.setupPathInterpolator();
                    return;
                }
            }
        }

        mapPrivates.plannedTravel = null;
        mapPrivates.zoomingAllowed = true;
    }

    function zoomAt(mx, my, factor)
    {
        var dOldZoom = flickableArea.zoom;
        var dNewZoom = Math.max(0.1, Math.min(10.0, dOldZoom * factor));

        if (dOldZoom === dNewZoom)
            return;

        // Image position inside content at current zoom
        var oldImageX = Math.max(0, (content.width - image.width));
        var oldImageY = Math.max(0, (content.height - image.height));

        var imageX = (oldImageX + flickableArea.contentX + mx) / dOldZoom;
        var imageY = (oldImageY + flickableArea.contentX + mx) / dOldZoom;

        flickableArea.zoom = dNewZoom;

        var newImgWidth = image.originalWidth * dNewZoom;
        var newImgHeight = image.originalHeight * dNewZoom;
        var imageXOrig = Math.max(0, (Math.max(flickableArea.width, newImgWidth) - newImgWidth));
        var imageYOrig = Math.max(0, (Math.max(flickableArea.height, newImgHeight) - newImgHeight));

        flickableArea.contentX =
                imageXOrig + imageX * dNewZoom - mx;

        flickableArea.contentY =
                imageYOrig + imageY * dNewZoom - my;

        // make sure map objects scale corectly
        for (let i = 0; image.children.length > i; ++i) {
            switch (image.children[i].objType) {
                case PlayerMap.Player:
                {
                    let foundPlayerPlace = mapPrivates.mapData.places.find((element) => element.id === mapPrivates.currentPlace);

                    // if the child is a location, calculate the new center
                    // Pixel position in the scaled image
                    var targetXP = imageXOrig + foundPlayerPlace.x * flickableArea.zoom;
                    var targetYP = imageYOrig + foundPlayerPlace.y * flickableArea.zoom;

                    let width = image.children[i].width;
                    let height = image.children[i].height;

                    image.children[i].fixedPosX = targetXP - width/2;
                    image.children[i].fixedPosY = targetYP - height/2;
                    break;
                }
                case PlayerMap.Place: // fallthrough
                {
                    let foundMapItem = mapPrivates.mapData.places.find((element) => element.id === image.children[i].objId);

                    // if the child is a location, calculate the new center
                    // Pixel position in the scaled image
                    var targetX = imageXOrig + foundMapItem.x * flickableArea.zoom;
                    var targetY = imageYOrig + foundMapItem.y * flickableArea.zoom;

                    let width = image.children[i].width;
                    let height = image.children[i].height;

                    image.children[i].x = targetX - width/2;
                    image.children[i].y = targetY - height/2;
                    break;
                }
                case PlayerMap.Path: {
                    let foundConnItem = mapPrivates.mapData.connections.find((element) => element.id === image.children[i].objId);
                    let foundFrom = mapPrivates.mapData.places.find((element) => element.id === foundConnItem.from);
                    let foundTo = mapPrivates.mapData.places.find((element) => element.id === foundConnItem.to);

                    // if the child is a Path, calculate new tl br
                    var targetX1 = imageXOrig + foundFrom.x * flickableArea.zoom;
                    var targetY1 = imageYOrig + foundFrom.y * flickableArea.zoom;
                    var targetX2 = imageXOrig + foundTo.x * flickableArea.zoom;
                    var targetY2 = imageYOrig + foundTo.y * flickableArea.zoom;

                    image.children[i].x = Math.min(targetX1, targetX2);
                    image.children[i].y = Math.min(targetY1, targetY2);
                    image.children[i].width = Math.max(targetX1, targetX2) - Math.min(targetX1, targetX2);
                    image.children[i].height = Math.max(targetY1, targetY2) - Math.min(targetY1, targetY2);
                    break;
                }
            }
        }
    }

    function moveToImagePixel(ix, iy, animate = true)
    {
        if (image.status !== Image.Ready) {
            return;
        }

        // Image position inside content at current zoom
        var imageX = Math.max(0, (content.width - image.width));
        var imageY = Math.max(0, (content.height - image.height));

        // Pixel position in the scaled image
        var targetX = imageX + ix * flickableArea.zoom;
        var targetY = imageY + iy * flickableArea.zoom;

        // Center this pixel in the view
        var targetContentX = targetX - flickableArea.width / 2;
        var targetContentY = targetY - flickableArea.height / 2;

        // Clamp to valid range
        cXAnim.to = Math.max(0,
            Math.min(flickableArea.contentWidth - flickableArea.width,
                     targetContentX));
        cYAnim.to = Math.max(0,
            Math.min(flickableArea.contentHeight - flickableArea.height,
                     targetContentY));
        if (animate) {
            zoomAnim.start();
        } else {
            flickableArea.contentX = cXAnim.to;
            flickableArea.contentY = cYAnim.to;
        }
    }

    // timer for certain animations
    Timer {
        id: updateTimer
        interval: 10
        running: true
        repeat: true

        property int updateCounter: 0
        property var lastDateMs: { return new Date().getTime(); }

        onTriggered: {
            updateCounter++;
            var newDateMs = new Date().getTime();
            var diffMs = newDateMs - lastDateMs;
            lastDateMs = newDateMs;
        }
    }

    // smooth zoom
    ParallelAnimation {
        id: zoomAnim
        loops: 1
        running: false
        NumberAnimation { id: cXAnim; target: flickableArea; property: "contentX"; to: 0; duration: 500 }
        NumberAnimation { id: cYAnim; target: flickableArea; property: "contentY"; to: 0; duration: 500 }
    }

    // player marker
    Component {
        id: player
        Rectangle {
            id: playerRect
            x: attachedToPath ? pathInterpolator.x - width / 2 : fixedPosX
            y: attachedToPath ? pathInterpolator.y - height / 2 : fixedPosY
            width: map.placeWidth
            height: map.placeHeight
            color: "transparent"

            border.width: 6
            border.color: "#ff00ff"

            radius: width / 2

            property int objType: PlayerMap.Player
            property bool attachedToPath: false
            property real fixedPosX: 0
            property real fixedPosY: 0
            property real visionRadius: 300

            onXChanged: {
                positionChanged();
            }
            onYChanged: {
                positionChanged();
            }
            Component.onCompleted: {
                image.player = playerRect;
                positionChanged();
            }

            function positionChanged() {
                let zoomedVisionRadius = visionRadius * flickableArea.zoom;
                let cellWidth = image.width / mapPrivates.explorationDataColumns;
                let cellHeight = image.height / mapPrivates.explorationDataRows;
                let bb = Qt.rect(x - zoomedVisionRadius,
                                 y - zoomedVisionRadius,
                                 zoomedVisionRadius * 2 + cellWidth, // we need to discover +1 so it looks better
                                 zoomedVisionRadius * 2);

                // Candidate cell indices
                let firstCol = Math.max(0,
                    Math.floor((bb.x - cellWidth / 2) / cellWidth));
                let lastCol = Math.min(mapPrivates.explorationDataColumns - 1,
                    Math.floor((bb.x + bb.width - cellWidth / 2) / cellWidth));

                let firstRow = Math.max(0,
                    Math.floor((bb.y - cellHeight / 2) / cellHeight));
                let lastRow = Math.min(mapPrivates.explorationDataRows - 1,
                    Math.floor((bb.y + bb.height - cellHeight / 2) / cellHeight));

                for (let row = firstRow; row <= lastRow; ++row) {
                    for (let col = firstCol; col <= lastCol; ++col) {
                        let centerX = (col + 0.5) * cellWidth;
                        let centerY = (row + 0.5) * cellHeight;

                        if (centerX >= bb.x &&
                            centerX <= bb.x + bb.width &&
                            centerY >= bb.y &&
                            centerY <= bb.y + bb.height) {
                            //console.log("Cell", row, col, "center:", centerX, centerY);
                            mapPrivates.explorationData[col + mapPrivates.explorationDataColumns * row] = true;
                        }
                    }
                }

                mapPrivates.explorationDataUpdated();
            }
        }
    }

    // Map places
    Component {
        id: mapIconComp
        Rectangle {
            id: mapIconRect
            width: map.placeWidth
            height: map.placeHeight
            color: "transparent"

            property int objType: PlayerMap.Place
            property int objId: -1
            property string name: ""
            property string icon: ""
            property string scene: ""
            property bool hovered: image.hovered === name && name !== ""
            property bool selected: image.selected === name && name !== ""

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: mapIconRect.height - height / 2
                width: iconText.width + 30
                height: iconText.height + 10
                color: "black"
                radius: 10

                border.width: 4
                border.color: objId === mapPrivates.currentPlace ? map.colorCurrentPlace : "transparent"

                TextItemFormated {
                    id: iconText
                    anchors.centerIn: parent
                    text: mapIconRect.name
                    pointSize: 8
                    maximumWidth: mapIconRect.width + 50
                }
            }
            IconResourceDelegate {
                id: mapIconInstance
                anchors.centerIn: parent
                width: mapIconRect.hovered ? map.placeWidth : (map.placeWidth - 20)
                height: mapIconRect.hovered ? map.placeHeight : (map.placeHeight - 20)
                pResource: {
                    let res = mapPrivates.currentlyLoadedProject.resource(mapIconRect.icon);
                    if (null == res) {
                        res = mapPrivates.currentlyLoadedProject.resource(map.unknownIcon);
                    }
                    return res;
                }
                bgVisible: true

                Connections {
                    target: mapIconRect
                    onHoveredChanged: {
                        mapIconInstance.reloadResource();
                    }
                }

                Button {
                    anchors.fill: parent
                    text: ""
                    flat: true

                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                    }

                    onClicked: {
                        image.selected = mapIconRect.name;
                        mapPrivates.plannedTravel =
                                AStar.bidirectionalAStar(mapPrivates.mapData,
                                                         mapPrivates.currentPlace,
                                                         mapIconRect.objId);
                        //console.log(mapPrivates.plannedTravel);
                    }
                }

                TimerDisplay {
                    id: timerDisplay
                    anchors.centerIn: parent
                    width: map.placeWidth + root.style.timerDisplay.groveWidth/2
                    height: map.placeWidth + root.style.timerDisplay.groveWidth/2
                    fillColor: "transparent"

                    visible: mapIconRect.selected
                    smooth: Settings.playerImageSmooth
                    antialiasing: Settings.playerAntialiasing

                    primaryColor: map.primaryColorSelection
                    secondaryColor: map.secondaryColorSelection
                    tertiaryColor: map.tertiaryColorSelection

                    borderWidth: root.style.timerDisplay.borderWidth
                    groveWidth: root.style.timerDisplay.groveWidth

                    decorationVisible: false
                    timeMsMax: 0
                    timeMsCurrent: 0
                    updateCounter: updateTimer.updateCounter*2
                    visibleCounter: false

                    Connections {
                        target: updateTimer
                        onTriggered: {
                            timerDisplay.update();
                        }
                    }
                }
            }
        }
    }

    // Map Paths
    Component {
        id: mapPath
        Rectangle {
            id: mapPathRect
            width: 0
            height: 0
            color: "transparent"

            property int objType: PlayerMap.Path
            property int objId: -1
            property int from: -1
            property int to: -1
            property var stops: []

            // Animate the dashOffset to shift the pattern
            property bool animationForward: {
                if (null == mapPrivates.plannedTravel) {
                    return true;
                }
                // check if we find from or to first
                for (var i = 0; mapPrivates.plannedTravel.places.length > i; ++i) {
                    if (mapPrivates.plannedTravel.places[i] === mapPathRect.from) {
                        return true;
                    } else if (mapPrivates.plannedTravel.places[i] === mapPathRect.to) {
                        return false;
                    }
                }
                return true;
            }

            function setupPathInterpolator() {
                pathInterpolator.path = motionPath;

                pathInterpolator.progress = 0;
                pathInterpolatorAnim.from = mapPrivates.plannedTravel.places[0] === from ? 0.0 : 1.0;
                pathInterpolatorAnim.to = mapPrivates.plannedTravel.places[0] === from ? 1.0 : 0.0;
                pathInterpolatorAnim.targetPlace = mapPrivates.plannedTravel.places[1];

                // set Player stuff
                for (var i = 0; image.children.length > i; ++i) {
                    if (image.children[i].objType === PlayerMap.Player) {
                        image.children[i].attachedToPath = true;
                        break;
                    }
                }

                pathInterpolatorAnim.start();
            }

            // for Path motionPath
            Instantiator {
                // Added safe check in case 'stops' updates or evaluates to null/undefined
                model: (mapPathRect.stops && mapPathRect.stops.length > 1) ? mapPathRect.stops : []

                delegate: PathCurve {
                    // Warning: If mapPathRect width/height is 0, these will evaluate to 0
                    x: mapPathRect.x + modelData.x * mapPathRect.width
                    y: mapPathRect.y + modelData.y * mapPathRect.height
                }

                // Explicitly modify the target pathElements array when elements cycle
                onObjectAdded: {
                    motionPath.pathElements.push(object);
                }
                onObjectRemoved: {
                    motionPath.pathElements.splice(index, 1);
                }
            }

            Path {
                id: motionPath

                startX: mapPathRect.x + (mapPathRect.stops.length > 0 ? mapPathRect.stops[0].x * mapPathRect.width : 0)
                startY: mapPathRect.y + (mapPathRect.stops.length > 0 ? mapPathRect.stops[0].y * mapPathRect.height : 0)
            }

            // for ShapePath
            Instantiator {
                // Added safe check in case 'stops' updates or evaluates to null/undefined
                model: (mapPathRect.stops && mapPathRect.stops.length > 1) ? mapPathRect.stops : []

                delegate: PathCurve {
                    // Warning: If mapPathRect width/height is 0, these will evaluate to 0
                    x: modelData.x * mapPathRect.width
                    y: modelData.y * mapPathRect.height
                }

                // Explicitly modify the target pathElements array when elements cycle
                onObjectAdded: {
                    pathShape.pathElements.push(object);
                }
                onObjectRemoved: {
                    pathShape.pathElements.splice(index, 1);
                }
            }

            Shape {
                anchors.fill: parent
                ShapePath {
                    id: pathShape

                    strokeColor: map.colorTravel
                    strokeWidth: 5
                    strokeStyle: ShapePath.DashLine
                    fillColor: "transparent"

                    dashPattern: [10, 5] // 10px dash, 5px space

                    dashOffset: mapPathRect.animationForward ? 0 : 15
                    NumberAnimation on dashOffset {
                        from: mapPathRect.animationForward ? 15 : 0
                        to: mapPathRect.animationForward ? 0 : 15 // Must match the sum of your dashPattern [10, 5]
                        duration: 1000
                        loops: Animation.Infinite
                        running: null != mapPrivates.plannedTravel ? mapPrivates.plannedTravel.connections.includes(mapPathRect.objId) : false
                    }

                    startX: mapPathRect.stops.length > 0 ? mapPathRect.stops[0].x * mapPathRect.width : 0
                    startY: mapPathRect.stops.length > 0 ? mapPathRect.stops[0].y * mapPathRect.height : 0
                }
            }
        }
    }

    // UI
    Flickable {
        id: flickableArea
        anchors.fill: parent
        clip: true
        interactive: true

        // High fall-off speed (decelerates quickly)
        flickDeceleration: 3000
        // Limits the max flick velocity
        maximumFlickVelocity: 1500

        property real zoom: 0.5

        contentWidth: Math.max(width, image.width)
        contentHeight: Math.max(height, image.height)

        PinchArea {
            id: pinchArea
            // The PinchArea must match the full size of the flickable content
            width: Math.max(flickableArea.width, content.width)
            height: Math.max(flickableArea.height, content.height)

            pinch.minimumScale: 0.5
            pinch.maximumScale: 4.0

            // Block flicking while zooming to prevent erratic jumps
            onPinchStarted: flickableArea.interactive = false
            onPinchFinished: flickableArea.interactive = true
            onPinchUpdated: {
                // currently deactivated because it causes flickering
                if (mapPrivates.zoomingAllowed && !map.lockZoom) {
                    var p = mapToItem(flickableArea, pinch.center.x, pinch.center.y);
                    map.zoomAt(p.x, p.y,
                               pinch.scale - pinch.previousScale > 0 ? 1.1 : 1/1.1)
                }
            }

            Item {
                id: content

                width: flickableArea.contentWidth
                height: flickableArea.contentHeight

                Image {
                    id: image

                    property var player: null

                    property real originalWidth: sourceSize.width
                    property real originalHeight: sourceSize.height
                    property string hovered: ""
                    property string selected: ""

                    width: originalWidth * flickableArea.zoom
                    height: originalHeight * flickableArea.zoom

                    asynchronous: true
                    smooth: Settings.playerImageSmooth
                    antialiasing: Settings.playerAntialiasing
                    mipmap: Settings.playerImageMipMap
                    source: ""

                    fillMode: Image.Stretch
                    scale: 1.0

                    // player interpolator
                    PathInterpolator {
                        id: pathInterpolator
                        path: null

                        property int objType: PlayerMap.PathInterpolator

                        onProgressChanged: {
                            var targetContentX = pathInterpolator.x - flickableArea.width / 2;
                            var targetContentY = pathInterpolator.y - flickableArea.height / 2;
                            // Clamp to valid range
                            flickableArea.contentX = Math.max(0,
                                Math.min(flickableArea.contentWidth - flickableArea.width,
                                         targetContentX));
                            flickableArea.contentY = Math.max(0,
                                Math.min(flickableArea.contentHeight - flickableArea.height,
                                         targetContentY));
                        }

                        NumberAnimation on progress {
                            id: pathInterpolatorAnim
                            from: 0
                            to: 1
                            duration: map.travelDuration
                            loops: 1
                            running: false

                            property int targetPlace : -1

                            onFinished: {
                                if (-1 !== targetPlace) {
                                    mapPrivates.currentPlace = targetPlace;
                                    targetPlace = -1;

                                    // Image position inside content at current zoom
                                    var imageX = Math.max(0, (content.width - image.width));
                                    var imageY = Math.max(0, (content.height - image.height));
                                    let foundPlayerPlace = mapPrivates.mapData.places.find((element) => element.id === mapPrivates.currentPlace);
                                    var targetXP = imageX + foundPlayerPlace.x * flickableArea.zoom;
                                    var targetYP = imageY + foundPlayerPlace.y * flickableArea.zoom;

                                    // set Player stuff
                                    for (var i = 0; image.children.length > i; ++i) {
                                        if (image.children[i].objType === PlayerMap.Player) {
                                            image.children[i].fixedPosX = targetXP - map.placeWidth/2;
                                            image.children[i].fixedPosY = targetYP - map.placeHeight/2;
                                            image.children[i].attachedToPath = false;
                                            moveToImagePixel(foundPlayerPlace.x, foundPlayerPlace.y, true);
                                            break;
                                        }
                                    }

                                    pathInterpolator.path = null;

                                    mapPrivates.plannedTravel.places.shift();
                                    mapPrivates.plannedTravel.connections.shift();

                                    Qt.callLater(function() {
                                        map.headToSelected();
                                    });
                                }
                            }
                        }
                    }

                    function populateMap()
                    {
                        // Image position inside content at current zoom
                        var imageX = Math.max(0, (content.width - image.width));
                        var imageY = Math.max(0, (content.height - image.height));

                        for (let i = 0; mapPrivates.mapData.connections.length > i; ++i) {
                            // Pixel position in the scaled image
                            let foundFrom = mapPrivates.mapData.places.find((element) => element.id === mapPrivates.mapData.connections[i].from);
                            let foundTo = mapPrivates.mapData.places.find((element) => element.id === mapPrivates.mapData.connections[i].to);

                            if (null != foundFrom && null != foundTo) {
                                var targetX1 = imageX + foundFrom.x * flickableArea.zoom;
                                var targetY1 = imageY + foundFrom.y * flickableArea.zoom;
                                var targetX2 = imageX + foundTo.x * flickableArea.zoom;
                                var targetY2 = imageY + foundTo.y * flickableArea.zoom;

                                mapPath.createObject(image,
                                                     {
                                                         objId: mapPrivates.mapData.connections[i].id,
                                                         x: Math.min(targetX1, targetX2),
                                                         y: Math.min(targetY1, targetY2),
                                                         width: Math.max(targetX1, targetX2) - Math.min(targetX1, targetX2),
                                                         height: Math.max(targetY1, targetY2) - Math.min(targetY1, targetY2),
                                                         from: mapPrivates.mapData.connections[i].from,
                                                         to: mapPrivates.mapData.connections[i].to,
                                                         stops: mapPrivates.mapData.connections[i].stops
                                                     });
                            }
                        }

                        // Pixel position in the scaled image
                        let foundPlayerPlace = mapPrivates.mapData.places.find((element) => element.id === mapPrivates.currentPlace);
                        var targetXP = imageX + foundPlayerPlace.x * flickableArea.zoom;
                        var targetYP = imageY + foundPlayerPlace.y * flickableArea.zoom;
                        player.createObject(image,
                                            {
                                                fixedPosX: targetXP - map.placeWidth/2,
                                                fixedPosY: targetYP - map.placeHeight/2,
                                            });

                        for (let i = 0; mapPrivates.mapData.places.length > i; ++i) {
                            // Pixel position in the scaled image
                            var targetX = imageX + mapPrivates.mapData.places[i].x * flickableArea.zoom;
                            var targetY = imageY + mapPrivates.mapData.places[i].y * flickableArea.zoom;

                            mapIconComp.createObject(image,
                                                     {
                                                         objId: mapPrivates.mapData.places[i].id,
                                                         x: targetX - map.placeWidth/2,
                                                         y: targetY - map.placeHeight/2,
                                                         name: mapPrivates.mapData.places[i].name,
                                                         icon: mapPrivates.mapData.places[i].icon,
                                                         scene: mapPrivates.mapData.places[i].scene
                                                     });
                        }
                    }

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            Qt.callLater(function() {
                                flickableArea.contentX =
                                        (flickableArea.contentWidth - flickableArea.width) / 2;
                                flickableArea.contentY =
                                        (flickableArea.contentHeight - flickableArea.height) / 2;
                            });

                            if (null != mapPrivates.mapData && mapPrivates.mapData.places.length > 0) {
                                // call delayed so image dimensions are already set
                                Qt.callLater(function() {
                                    image.populateMap();
                                    let foundMapItem = mapPrivates.mapData.places.find((element) => element.id === mapPrivates.currentPlace);
                                    map.moveToImagePixel(
                                        foundMapItem.x,
                                        foundMapItem.y,
                                        true
                                    );
                                    image.selected = foundMapItem.name;
                                });
                            }
                        }
                    }


                    FogOfWar {
                        id: fow
                        anchors.fill: parent

                        playerX: image.player ? (image.player.x + image.player.width / 2) : 0
                        playerY: image.player ? (image.player.y + image.player.height / 2) : 0

                        radius: image.player ? (image.player.visionRadius * flickableArea.zoom) : 0
                        feather: radius * 0.7

                        mapWidthFull: image.originalWidth
                        mapHeightFull: image.originalHeight

                        cloudSource: "image://DataBaseImageProivider/" + mapPrivates.currentlyLoadedProject.id + "/" + map.fogTexture
                        cloudTextureWidth: map.fogTextureWidth * flickableArea.zoom
                        cloudTextureHeight: map.fogTextureHeight * flickableArea.zoom

                        explorationDataColumns: mapPrivates.explorationDataColumns
                        explorationDataRows: mapPrivates.explorationDataRows
                        explorationData: mapPrivates.explorationData

                        Connections {
                            target: mapPrivates
                            onExplorationDataUpdated: {
                                fow.explorationDataUpdated();
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                propagateComposedEvents: true

                onPositionChanged: {
                    // Find which child component is under the mouse
                    var p = mapToItem(image, mouse.x, mouse.y);
                    let visualItem = image.childAt(p.x, p.y);
                    if (visualItem != null && visualItem.name != null) {
                        image.hovered = visualItem.name;
                    } else {
                        image.hovered = ""
                    }
                }
                onClicked: {
                    mouse.accepted = false;
                }
                onWheel: {
                    // currently deactivated because it causes flickering
                    if (mapPrivates.zoomingAllowed && !map.lockZoom) {
                        var p = mapToItem(flickableArea, wheel.x, wheel.y);
                        map.zoomAt(p.x, p.y,
                                   wheel.angleDelta.y > 0 ? 1.1 : 1/1.1)
                    }
                    wheel.accepted = true
                }
            }
        }
    }
}
