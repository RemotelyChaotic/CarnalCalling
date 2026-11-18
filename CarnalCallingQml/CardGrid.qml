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

    cellWidth: cellHintWidth + cellMargin
    cellHeight: cellHintHeight + cellMargin

    property real cellHintWidth: StyleParams.cardCollectionWidthMin
    property real cellHintHeight: StyleParams.cardCollectionHeightMin
    property real cellMargin: 10

    flow: GridView.FlowLeftToRight
    layoutDirection: Qt.LeftToRight
    verticalLayoutDirection: GridView.TopToBottom

    property bool showCardCount: true
    property bool innerMouseAreaEnabled: true
    property bool onlyShowNonZeroCount: false
    property string countRole: "cardCount"
    property string filterRole: "cardFilter"
    property string filterPattern: ""
    property string sortRole: "orderId"

    property alias sourceModel: cardProxyModel.sourceModel

    signal itemClicked(int index, real x, real y, string setId, int id, int button)

    clip: true
    highlightFollowsCurrentItem: true
    highlight: Rectangle {
        color: "transparent"
        width: cardList.cellWidth + cardList.cellMargin
        height: cardList.cellHeight + cardList.cellMargin
        x: null != cardList.currentItem ? cardList.currentItem.x : 0
        y: null != cardList.currentItem ? cardList.currentItem.y : 0
        Rectangle {
            anchors.centerIn: parent
            width: parent.width-cardList.cellMargin*0.8
            height: parent.height-cardList.cellMargin*0.8
            color: StyleParams.glowHexColor
            radius: cardList.cellMargin*0.8
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
        filters: AllOf {
            filters: [
                RegExpFilter {
                    roleName: cardList.filterRole
                    pattern: cardList.filterPattern
                    caseSensitivity: Qt.CaseInsensitive
                },
                RegExpFilter {
                    roleName: cardList.countRole
                    pattern: cardList.onlyShowNonZeroCount ? "^(?!0$).*" : ".*"
                    caseSensitivity: Qt.CaseInsensitive
                }
            ]
        }

        sorters: StringSorter {
            id: sorter
            roleName: cardList.sortRole
        }
    }

    delegate: Rectangle {
        id: thisCard
        width: cardList.cellHintWidth
        height: cardList.cellHintHeight
        color: "transparent"

        Loader {
            id: cardLoader
            anchors.fill: parent
            source: ""
            asynchronous: true
            visible: false
        }

        Desaturate {
            anchors.fill: cardLoader
            source: cardLoader
            desaturation: model.enabled ? 0.0 : 1.0
            visible: cardLoader.status == Loader.Ready
        }

        HexShape {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - height
            width: StyleParams.hexWidth / 2
            height: StyleParams.hexHeight / 2

            fillColor: StyleParams.fillColorHexInactive
            strokeColor: StyleParams.strokeColorHexInactive
            strokeWidth: StyleParams.strokeColorHexInactiveWidth

            visible: cardList.showCardCount && model.cardData != null

            Text {
                width: parent.width*1.5
                height: parent.height*1.5
                anchors.centerIn: parent

                text: model.cardCount

                font.family: null != root.currentlyLoadedProject ?
                                 root.currentlyLoadedProject.font : "Arial"
                font.pixelSize: StyleParams.cardCountPonintSize
                font.hintingPreference: Font.PreferNoHinting

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
                wrapMode: Text.WordWrap
                color: model.cardCountColor
                textFormat: Text.PlainText
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: cardList.innerMouseAreaEnabled && model.enabled
            hoverEnabled: true

            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onEntered: {
                let oldX = cardList.contentX;
                let oldY = cardList.contentY
                cardList.currentIndex = index;
                cardList.contentX = oldX;
                cardList.contentY = oldY;
            }

            onClicked: {
                if (null != model.cardData) {
                    let pointInLayout = mapToItem(cardList.parent, 0.0, 0.0);
                    cardList.itemClicked(
                                index,
                                pointInLayout.x,
                                pointInLayout.y,
                                model.cardData.setId,
                                model.cardData.id,
                                mouse.button);
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
                    from: 0
                    to: 1
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
        x: StyleParams.dominantHand === DominantHand.Left ?
            cardList.x + cardList.width + (StyleParams.hexWidth - width)/2 :
            cardList.x - (StyleParams.hexWidth + width)/2
        width: StyleParams.hexWidth/3

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
