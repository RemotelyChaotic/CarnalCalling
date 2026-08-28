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

    signal travelFinished(string nextScene)

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
        fadeoutAnim.start();
    }

    function switchScene()
    {
        let foundPlayerPlace = mapPrivates.mapData.places.find((element) => element.id === mapPrivates.currentPlace);
        if (null != foundPlayerPlace) {
            travelFinished(foundPlayerPlace.scene);
        }
    }

    function zoomAt(mxFlickable, myFlickable, factor)
    {
        var dOldZoom = flickableArea.zoom;
        var dNewZoom = Math.max(0.1, Math.min(10.0, dOldZoom * factor));

        if (dOldZoom === dNewZoom) {
            return;
        }

        // Position of the mouse in the zoomed content coordinate system
        var contentMouseX = flickableArea.contentX + mxFlickable;
        var contentMouseY = flickableArea.contentY + myFlickable;

        // Image position inside content at current zoom
        var oldImageW = Math.max(0, image.width);
        var oldImageH = Math.max(0, image.height);

        var imageX = contentMouseX / dOldZoom;
        var imageY = contentMouseY / dOldZoom;

        flickableArea.zoom = dNewZoom;

        var newImageW = Math.max(0, image.width);
        var newImageH = Math.max(0, image.height);

        flickableArea.contentX = (imageX * dNewZoom) - mxFlickable;
        flickableArea.contentY = (imageY * dNewZoom) - myFlickable;
        flickableArea.returnToBounds();
    }

    function moveToImagePixel(ixImage, iyImage, animate = true)
    {
        if (image.status !== Image.Ready) {
            return;
        }

        var xInViewport = ixImage * flickableArea.zoom;
        var yInViewport = iyImage * flickableArea.zoom;

        // Center this pixel in the view
        var targetContentX = xInViewport - flickableArea.width / 2;
        var targetContentY = yInViewport - flickableArea.height / 2;

        // Clamp to valid range
        cXAnim.to = Math.max(0,
            Math.min(flickableArea.contentWidth - flickableArea.width,
                     targetContentX));
        cYAnim.to = Math.max(0,
            Math.min(flickableArea.contentHeight - flickableArea.height,
                     targetContentY));
        if (animate) {
            panAnim.start();
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

    // smooth fadeout
    SequentialAnimation {
        id: fadeoutAnim
        loops: 1
        running: false

        // Fixed viewport position
        property real zoomCenterX: 0
        property real zoomCenterY: 0
        // Content point underneath the center, in unscaled coordinates
        property real zoomImageX: 0
        property real zoomImageY: 0
        onRunningChanged: {
            if (running) {
                zoomCenterX = flickableArea.width / 2;
                zoomCenterY = flickableArea.height / 2;
                zoomImageX =
                    (flickableArea.contentX + zoomCenterX)
                    / flickableArea.zoom;
                zoomImageY =
                    (flickableArea.contentY + zoomCenterY)
                    / flickableArea.zoom;
                zoomProgress = 0
            }
        }

        property int zoomProgress: 0
        onZoomProgressChanged: {
            var step = 1.05;
            zoomAt(
                zoomCenterX,
                zoomCenterY,
                step
            );
            // Correct the position after zoomAt().
            //
            // zoomAt() calls returnToBounds(), so if the requested
            // position gets clamped, explicitly put the captured
            // image point back under the center.
            flickableArea.contentX =
                    zoomImageX * flickableArea.zoom - zoomCenterX;
            flickableArea.contentY =
                    zoomImageY * flickableArea.zoom - zoomCenterY;
        }
        NumberAnimation { target: fadeoutAnim; property: "zoomProgress"; to: 40; duration: 1000 }
        ScriptAction { script: switchScene(); }
    }

    // smooth pan
    ParallelAnimation {
        id: panAnim
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
            x: attachedToPath ? pathInterpolator.x - width / 2 : fixedPosX - width / 2
            y: attachedToPath ? pathInterpolator.y - height / 2 : fixedPosY - height / 2
            width: map.placeWidth / flickableArea.zoom
            height: map.placeHeight / flickableArea.zoom
            color: "transparent"

            border.width: 6 / flickableArea.zoom
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
                let zoomedVisionRadius = visionRadius;
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
            x: fixedPosX - width / 2
            y: fixedPosY - height / 2
            width: map.placeWidth / flickableArea.zoom
            height: map.placeHeight / flickableArea.zoom
            color: "transparent"

            property int objType: PlayerMap.Place
            property int objId: -1
            property string name: ""
            property string icon: ""
            property string scene: ""
            property bool hovered: image.hovered === name && name !== ""
            property bool selected: image.selected === name && name !== ""

            property real fixedPosX: 0
            property real fixedPosY: 0

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: mapIconRect.height - height / 2
                width: iconText.width + 30
                height: iconText.height + 10
                color: "black"
                radius: 10

                border.width: 4 / flickableArea.zoom
                border.color: objId === mapPrivates.currentPlace ? map.colorCurrentPlace : "transparent"

                TextItemFormated {
                    id: iconText
                    anchors.centerIn: parent
                    text: mapIconRect.name
                    pointSize: 8 / flickableArea.zoom
                    maximumWidth: mapIconRect.width / flickableArea.zoom + 50
                }
            }
            IconResourceDelegate {
                id: mapIconInstance
                anchors.centerIn: parent
                width: mapIconRect.hovered ? map.placeWidth / flickableArea.zoom : (map.placeWidth / flickableArea.zoom - 20 / flickableArea.zoom)
                height: mapIconRect.hovered ? map.placeHeight / flickableArea.zoom : (map.placeHeight / flickableArea.zoom - 20 / flickableArea.zoom)
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
                Connections {
                    target: flickableArea
                    onZoomChanged: {
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
                    width: map.placeWidth / flickableArea.zoom + root.style.timerDisplay.groveWidth/2 / flickableArea.zoom
                    height: map.placeWidth / flickableArea.zoom + root.style.timerDisplay.groveWidth/2 / flickableArea.zoom
                    fillColor: "transparent"

                    visible: mapIconRect.selected
                    smooth: Settings.playerImageSmooth
                    antialiasing: Settings.playerAntialiasing

                    primaryColor: map.primaryColorSelection
                    secondaryColor: map.secondaryColorSelection
                    tertiaryColor: map.tertiaryColorSelection

                    borderWidth: root.style.timerDisplay.borderWidth / flickableArea.zoom
                    groveWidth: root.style.timerDisplay.groveWidth / flickableArea.zoom

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
                    strokeWidth: 5 / flickableArea.zoom
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

        contentWidth: pinchArea.width * zoom
        contentHeight: pinchArea.height * zoom
        boundsBehavior: Flickable.DragAndOvershootBounds

        PinchArea {
            id: pinchArea
            // The PinchArea must match the full size of the flickable content
            width: content.width
            height: content.height

            scale: flickableArea.zoom
            transformOrigin: Item.TopLeft

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
                width: image.width
                height: image.height

                Image {
                    id: image
                    anchors.centerIn: parent
                    width: originalWidth
                    height: originalHeight

                    property var player: null

                    property real originalWidth: sourceSize.width
                    property real originalHeight: sourceSize.height
                    property string hovered: ""
                    property string selected: ""

                    asynchronous: true
                    smooth: Settings.playerImageSmooth
                    antialiasing: Settings.playerAntialiasing
                    mipmap: Settings.playerImageMipMap
                    source: ""

                    fillMode: Image.PreserveAspectFit

                    // player interpolator
                    PathInterpolator {
                        id: pathInterpolator
                        path: null

                        property int objType: PlayerMap.PathInterpolator

                        onProgressChanged: {
                            var targetContentX = pathInterpolator.x * flickableArea.zoom - flickableArea.width / 2;
                            var targetContentY = pathInterpolator.y * flickableArea.zoom - flickableArea.height / 2;
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

                                    let foundPlayerPlace = mapPrivates.mapData.places.find((element) => element.id === mapPrivates.currentPlace);
                                    var targetXP = foundPlayerPlace.x;
                                    var targetYP = foundPlayerPlace.y;

                                    // set Player stuff
                                    for (var i = 0; image.children.length > i; ++i) {
                                        if (image.children[i].objType === PlayerMap.Player) {
                                            image.children[i].fixedPosX = targetXP;
                                            image.children[i].fixedPosY = targetYP;
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
                        for (let i = 0; mapPrivates.mapData.connections.length > i; ++i) {
                            // Pixel position in the scaled image
                            let foundFrom = mapPrivates.mapData.places.find((element) => element.id === mapPrivates.mapData.connections[i].from);
                            let foundTo = mapPrivates.mapData.places.find((element) => element.id === mapPrivates.mapData.connections[i].to);

                            if (null != foundFrom && null != foundTo) {
                                var targetX1 = foundFrom.x
                                var targetY1 = foundFrom.y;
                                var targetX2 = foundTo.x;
                                var targetY2 = foundTo.y;
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
                        var targetXP = foundPlayerPlace.x;
                        var targetYP = foundPlayerPlace.y;
                        player.createObject(image,
                                            {
                                                fixedPosX: targetXP,
                                                fixedPosY: targetYP,
                                            });

                        for (let i = 0; mapPrivates.mapData.places.length > i; ++i) {
                            // Pixel position in the scaled image
                            var targetX = mapPrivates.mapData.places[i].x;
                            var targetY = mapPrivates.mapData.places[i].y;

                            mapIconComp.createObject(image,
                                                     {
                                                         objId: mapPrivates.mapData.places[i].id,
                                                         fixedPosX: targetX,
                                                         fixedPosY: targetY,
                                                         name: mapPrivates.mapData.places[i].name,
                                                         icon: mapPrivates.mapData.places[i].icon,
                                                         scene: mapPrivates.mapData.places[i].scene
                                                     });
                        }
                    }

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            Qt.callLater(function() {
                                flickableArea.zoom = 0.5;
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

                        radius: image.player ? image.player.visionRadius : 0
                        feather: radius * 0.7

                        mapWidthFull: image.originalWidth
                        mapHeightFull: image.originalHeight

                        cloudSource: "image://DataBaseImageProivider/" + mapPrivates.currentlyLoadedProject.id + "/" + map.fogTexture
                        cloudTextureWidth: map.fogTextureWidth
                        cloudTextureHeight: map.fogTextureHeight

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
            if (mapPrivates.zoomingAllowed && !map.lockZoom) {
                var p = mapToItem(flickableArea, wheel.x, wheel.y);
                map.zoomAt(p.x, p.y,
                           wheel.angleDelta.y > 0 ? 1.1 : 1/1.1)
            }
            wheel.accepted = true
        }
    }
}
