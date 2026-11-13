import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Shapes 1.14
import QtGraphicalEffects 1.14
import JoipEngine 1.3
import JOIP.core 1.5
import CarnalCallingQml 1.0
import SortFilterProxyModel 0.2


GridView {
    id: cardList
    width: parent.width - StyleParams.hexWidth*3
    height: parent.height - StyleParams.hexHeight*3
    cellWidth: StyleParams.cardCollectionWidthMin+10
    cellHeight: StyleParams.cardCollectionHeightMin+10

    flow: GridView.FlowLeftToRight
    layoutDirection: Qt.LeftToRight
    verticalLayoutDirection: GridView.TopToBottom

    property bool innerMouseAreaEnabled: true

    property alias sourceModel: cardProxyModel.sourceModel
    property alias filters: cardProxyModel.filters

    signal itemClicked(int index, real x, real y, string setId, int id)

    clip: true
    highlightFollowsCurrentItem: true
    highlight: Rectangle {
        color: "transparent"
        width: cardList.cellWidth
        height: cardList.cellHeight
        x: null != cardList.currentItem ? cardList.currentItem.x : 0
        y: null != cardList.currentItem ? cardList.currentItem.y : 0
        Rectangle {
            anchors.centerIn: parent
            width: parent.width-8
            height: parent.height-8
            color: StyleParams.glowHexColor
            radius: 8
        }

        layer.enabled: true
        layer.effect: Glow {
            radius: StyleParams.glowHexRadius
            samples: 17
            spread: StyleParams.glowHexSpread
            color: StyleParams.glowHexColor
            transparentBorder: true
        }
    }

    model: SortFilterProxyModel {
        id: cardProxyModel

        sourceModel: null
        filters: []

        sorters: StringSorter {
            id: sorter
            roleName: "orderId"
        }
    }

    delegate: Rectangle {
        id: thisCard
        width: StyleParams.cardCollectionWidthMin
        height: StyleParams.cardCollectionHeightMin
        color: "transparent"

        Loader {
            id: cardLoader
            anchors.fill: parent
            source: ""
            asynchronous: true
            visible: status == Loader.Ready
        }

        HexShape {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - height
            width: StyleParams.hexWidth / 2
            height: StyleParams.hexHeight / 2

            fillColor: StyleParams.fillColorHexInactive
            strokeColor: StyleParams.strokeColorHexInactive
            strokeWidth: StyleParams.strokeColorHexInactiveWidth

            visible: model.cardData != null

            Text {
                anchors.fill: parent

                text: model.cardCount

                property real zoomFactorX: thisCard.width / StyleParams.cardWidthOrig

                font.family: null != root.currentlyLoadedProject ?
                                 root.currentlyLoadedProject.font : "Arial"
                font.pixelSize: StyleParams.cardCountPonintSize
                font.hintingPreference: Font.PreferNoHinting

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
                wrapMode: Text.WordWrap
                color: StyleParams.textColorMenu
                textFormat: Text.RichText
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: cardList.innerMouseAreaEnabled
            hoverEnabled: true

            onEntered: {
                let oldX = cardList.contentX;
                let oldY = cardList.contentY
                cardList.currentIndex = index;
                cardList.contentX = oldX;
                cardList.contentY = oldY;
            }

            onClicked: {
                if (null != model.cardData) {
                    let pointInLayout = mapToItem(layout, 0.0, 0.0);
                    cardList.itemClicked(
                                index,
                                pointInLayout.x,
                                pointInLayout.y,
                                model.cardData.setId,
                                model.cardData.id);
                }
            }
        }

        Connections {
            target: thisCard

            function onVisibleChanged() {
                if (thisCard.visible && cardLoader.status === Loader.Null) {
                    cardLoader.source = model.cardLayout;
                }
            }
        }

        Component.onCompleted: {
            if (visible) {
                cardLoader.source = model.cardLayout;
            }
        }
    }

    remove: Transition {
        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation {
                    property: "y"
                    from: cardList.contentY
                    to: cardList.contentY - 100
                    duration: 500
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 500
                }
            }
        }
    }
    populate: Transition {
        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation {
                    property: "y"
                    from: cardList.contentY + 100
                    duration: 500
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 500
                }
            }
        }
    }

    ScrollBar.vertical: ScrollBar {
        id: scrollV
        orientation: Qt.Vertical
        policy: Qt.ScrollBarAlwaysOn

        parent: cardList.parent

        anchors.top: cardList.top
        anchors.bottom: cardList.bottom
        width: StyleParams.hexWidth/3
        anchors.left:  StyleParams.dominantHand === DominantHand.Left  ? undefined : cardList.left
        anchors.right: StyleParams.dominantHand === DominantHand.Left  ? cardList.right : undefined
        anchors.leftMargin:  StyleParams.dominantHand === DominantHand.Left ? 0 : -width-StyleParams.hexWidth/2
        anchors.rightMargin: StyleParams.dominantHand === DominantHand.Left ? width+StyleParams.hexWidth/2 : 0

        contentItem: Rectangle {
            implicitWidth: parent.width - StyleParams.strokeColorHexInactiveWidth*2
            implicitHeight: 100
            radius: width / 2
            color: StyleParams.fillColorHexActive
        }
        background: Rectangle {
            implicitWidth: parent.width
            radius: width / 2
            color: StyleParams.fillColorHexInactive
            border.color: StyleParams.strokeColorHexInactive
        }
    }
}