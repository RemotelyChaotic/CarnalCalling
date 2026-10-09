import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Shapes 1.14
import QtGraphicalEffects 1.14
import JoipEngine 1.3
import JOIP.core 1.5
import JOIP.db 1.1
import CarnalCallingQml 1.0
import SortFilterProxyModel 0.2

Rectangle {
    id: layout
    color: "transparent"

    property Project currentlyLoadedProject: root.currentlyLoadedProject
    property DataRepository repository: null

    property bool canToggleOnlyOwned: true
    property real offsetX: hexBg.x
    property real offsetY: hexBg.y
    readonly property alias numRows: hexBg.numRows
    readonly property alias numCols: hexBg.numCols
    readonly property var genderStrings: [ "None", "Male", "Female", "Herm"]

    visible: false

    function cardKey(setId, id)
    {
        return setId + ";" + id;
    }

    function showWith(ownedCards, onlyShowOwned = false)
    {
        cardModel.clear();
        showOnlyOwnedButtonCheckable.checked = onlyShowOwned;

        if (null != repository) {
            const ownedByKey = new Map();
            if (ownedCards) {
                for (const card of ownedCards) {
                    ownedByKey.set(cardKey(card.setId, card.id), card);
                }
            }

            let allPacks = repository.allPacks();

            let vAllCardsSorted = [];

            for (const packId of allPacks) {

                const pack = repository.getPack(packId);
                const rarityTypes = Object.keys(pack.cards);
                for (const rarity of rarityTypes) {
                    if (!rarity.startsWith('_')) {
                        for (const cardC of pack.cards[rarity]) {
                            vAllCardsSorted.push(cardC);
                        }
                    }
                }
            }

            vAllCardsSorted.sort((a, b) => {
                // Primary: setId (string comparison)
                const setIdCompare = a.setId.localeCompare(b.setId);
                if (setIdCompare !== 0) {
                  return setIdCompare;
                }

                // Secondary: id (numeric)
                return a.id - b.id;
            });

            if (null != ownedCards) {
                for (const c of vAllCardsSorted) {
                    const found = ownedByKey.get(cardKey(c.setId, c.id));
                    if (null != found) {
                        pushCard(found);
                    } else {
                        pushBackground(c);
                    }
                }
            }
        }

        addTimer.start();

        layout.visible = true;
    }

    function pushBackground(cardData)
    {
        if (null != cardData && null != cardData.id &&
            null != cardData.setId && -1 < cardData.id && "" !== cardData.setId)
        {
            let cardView = repository.getCardViewElements(cardData.id, cardData.setId);
            let cardFilter = cardData.setId + ";" + cardData.id;
            addTimer.itemsToAdd.push({
                                 "cardData": null,
                                 "cardViewElems": cardView,
                                 "cardLayout": "CardDelegateBack.qml",
                                 "cardCount": 0,
                                 "projId": currentlyLoadedProject.id,
                                 "cardFilter": cardFilter,
                                 "orderId": cardKey(cardData.setId, cardData.id)
                            });
        }
    }

    function pushCard(cardData)
    {
        if (null != cardData && null != cardData.id &&
            null != cardData.setId && -1 < cardData.id && "" !== cardData.setId)
        {
            let card = repository.getCard(cardData.id, cardData.setId);
            let cardFilter = card.setId + ";" + card.id + ";" + card.title + ";" +
                             card.description + ";" + card.faction + ";" + card.cardType + ";" +
                             card.slot + ";" + card.rarity + ";" +
                             genderStrings[card.gendering+1] + ";" +
                             card.tags.join(";");
            addTimer.itemsToAdd.push({
                                 "cardData": card,
                                 "cardViewElems": repository.getCardViewElements(card),
                                 "cardLayout": card.layout,
                                 "cardCount": cardData.count,
                                 "projId": currentlyLoadedProject.id,
                                 "cardFilter": cardFilter,
                                 "orderId": cardKey(cardData.setId, cardData.id)
                            });
        }
    }

    Timer {
        id: addTimer
        interval: 100
        repeat: true
        running: false

        property var itemsToAdd: []
        property int nextItem: 0

        onTriggered: {
            if (0 < itemsToAdd.length) {
                cardModel.append(itemsToAdd.splice(0,1)[0]);

                nextItem++
            } else {
                stop();
            }
        }
    }

    /*
    Rectangle {
        id: debugRenderer
        x: hexBg.x
        y: hexBg.y
        width: parent.width - hexBg.x *2
        height: parent.height - hexBg.y *2
        color: "transparent"
        border.color: "blue"
    }
    */

    HexGridRenderer {
        id: hexBg
        anchors.centerIn: parent
        width: gridWidth - hexWidth / 2
        height: gridHeight
        widthHint: parent.width
        heightHint: parent.height

        color: "transparent"

        hexWidth: StyleParams.hexWidth
        hexHeight: StyleParams.hexHeight
        lineWeight: StyleParams.strokeColorHexInactiveWidth/2

        hexFillString: StyleParams.fillColorHexInactive
        lineFillString: StyleParams.strokeColorHexInactive

        animateMouseOver: true
        gradientRendering: false
    }

    ListModel {
        id: cardModel
        dynamicRoles: false
    }

    GridView {
        id: cardList
        anchors.centerIn: parent
        width: parent.width - StyleParams.hexWidth*3
        height: parent.height - StyleParams.hexHeight*3
        cellWidth: StyleParams.cardCollectionWidthMin+10
        cellHeight: StyleParams.cardCollectionHeightMin+10

        flow: GridView.FlowLeftToRight
        layoutDirection: Qt.LeftToRight
        verticalLayoutDirection: GridView.TopToBottom

        signal itemClicked(int index, real x, real y, string setId, int id)

        onItemClicked: {
            previewDelegate.x = x;
            previewDelegate.y = y;
            previewDelegate.width = StyleParams.cardCollectionWidthMin;
            previewDelegate.height = StyleParams.cardCollectionHeightMin;

            let card = repository.getCard(id, setId);
            if (null != card) {
                previewDelegate.cardData = card;
                previewDelegate.cardViewElems = repository.getCardViewElements(card);
                previewDelegate.source = card.layout;
            }

            previewDelegate.show();
        }

        clip: false
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

            sourceModel: cardModel
            filters: AllOf {
                filters: [
                    RegExpFilter {
                        roleName: "cardFilter"
                        pattern: filterTextArea.text === "" ? ".*" : filterTextArea.text
                        caseSensitivity: Qt.CaseInsensitive
                    },
                    RegExpFilter {
                        roleName: "cardLayout"
                        pattern: showOnlyOwnedButtonCheckable.checked ? "^(?!CardDelegateBack[.]qml$).*" : ".*"
                        caseSensitivity: Qt.CaseInsensitive
                    }
                ]
            }

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
                    font.pixelSize: StyleParams.cardCreditsTextPonintSize * zoomFactorX
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
                enabled: !previewDelegate.visible
                hoverEnabled: true

                onEntered: {
                    cardList.currentIndex = index;
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

    Rectangle {
        id: overlayRect
        anchors.fill: parent
        color: "#88000000"
        opacity: previewDelegate.visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }

        MouseArea {
            anchors.fill: parent
            enabled: previewDelegate.visible
            onClicked: {
                previewDelegate.visible = false;
            }
        }
    }

    HexButtonWithToolTip {
        id: searchButton
        x: hexBg.x
        y: hexBg.y
        width: StyleParams.hexWidth
        height: StyleParams.hexHeight
        hexWidth: StyleParams.hexWidth
        hexHeight: StyleParams.hexHeight
        orientation: HexButtonWithToolTip.Top
        textBoxOffset: 6

        text: qsTr("Filter")
        imageSource: hovered ? StyleParams.searchHoverButton : StyleParams.searchButton
        glowHexColor: StyleParams.glowHexColor
    }

    TextArea {
        id: filterTextArea
        x: searchButton.x + searchButton.width
        y: hexBg.y
        width: StyleParams.hexWidth * 6
        height: StyleParams.hexHeight

        leftPadding: StyleParams.hexWidth * 0.25
        rightPadding: StyleParams.hexWidth * 0.25
        topPadding: 0
        bottomPadding: 0
        verticalAlignment: TextEdit.AlignVCenter

        color: StyleParams.textColorMenu

        text: ""
        placeholderText: qsTr("Enter a filter expression")
        placeholderTextColor: StyleParams.placeholderTextColorMenu
        font.pointSize: StyleParams.menuTextPonintSize
        font.family: null != root.currentlyLoadedProject ?
                         root.currentlyLoadedProject.font : "Arial"
        font.hintingPreference: Font.PreferNoHinting

        cursorDelegate: Rectangle {
            width: StyleParams.cursorWidth
            color: StyleParams.cursorColor
        }

        background: Shape {
            id: textBgShape
            width: parent.width
            height: parent.height
            layer.enabled: Settings.playerAntialiasing
            layer.samples: 4 // (anti-aliasing)

            property real dy: textBgShape.height / 2
            property real dx: StyleParams.hexWidth*0.25

            ShapePath {
                fillColor: StyleParams.fillColorHexActive
                strokeColor: StyleParams.strokeColorHexActive
                strokeWidth: StyleParams.strokeColorHexActiveWidth
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                startX: 0
                startY: textBgShape.dy
                PathLine { x: textBgShape.dx; y: 0 }
                PathLine { x: textBgShape.width - textBgShape.dx; y: 0 }
                PathLine { x: textBgShape.width; y: textBgShape.height / 2 }
                PathLine { x: textBgShape.width - textBgShape.dx; y: textBgShape.height }
                PathLine { x: textBgShape.dx; y: textBgShape.height }
                PathLine { x: 0; y: textBgShape.dy }
            }
        }
    }

    HexButtonWithToolTip {
        id: showOnlyOwnedButtonCheckable
        x: hexBg.x + filterTextArea.width + searchButton.width
        y: hexBg.y
        width: StyleParams.hexWidth
        height: StyleParams.hexHeight
        hexWidth: StyleParams.hexWidth
        hexHeight: StyleParams.hexHeight
        orientation: HexButtonWithToolTip.Top
        textBoxOffset: 6

        text: qsTr("Only Show Owned")
        imageSource: hovered ? StyleParams.onlyShowOwnedHoverButton : StyleParams.onlyShowOwnedButton
        glowHexColor: StyleParams.glowHexColor

        checkable: true
        visible: layout.canToggleOnlyOwned
    }

    CardPreviewRender {
        id: previewDelegate
        x: 0
        y: 0
        width: 0
        height: 0
        currentlyLoadedProject: layout.currentlyLoadedProject.id
    }
}
