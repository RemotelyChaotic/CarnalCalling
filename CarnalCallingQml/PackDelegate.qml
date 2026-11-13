import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14
import JoipEngine 1.3
import JOIP.core 1.5
import JOIP.db 1.1
import CarnalCallingQml 1.0

Rectangle {
    id: packRoot
    width: StyleParams.deckCollectionWidthMin
    height: StyleParams.deckCollectionHeightMin
    color: "transparent"

    property var packData: model !== "undefined" ? model.pack : null
    property string packImage: typeof model !== "undefined" ? model.packImage : ""
    property int currentlyLoadedProjectId: typeof model !== "undefined" ? model.projId : -1

    BoosterPack3D {
        id: booster
        anchors.fill: parent

        packImage: packRoot.packImage
        currentlyLoadedProject: packRoot.currentlyLoadedProjectId
    }

    Timer {
        id: timer
        repeat: true
        running: true //parent.visible
        interval: 33 // 30fps

        onTriggered: {
            booster.cardRotationY += 2;
        }
    }
}
