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

    property int maxInstancesOfCardInDeck: 3
    property int minDeckSize: 10
    property int maxDeckSize: 40

    property int numRows: 0
    property int numCols: 0

    property bool canToggleOnlyOwned: true

    readonly property var genderStrings: [ "None", "Male", "Female", "Herm"]
    readonly property string tagCard: "card"
    readonly property string iconActionTag: "icontype:Action"
    readonly property string iconSocialTag: "icontype:Social"
    readonly property string iconClothesTag: "icontype:Clothes"
    readonly property string iconNoneTag: "None"
    readonly property string actionType: "Action"
    readonly property string socialType: "Social"

    visible: false

    property int currentDeck: -1
    property alias depth: stack.depth
    property var ownedCards : []

    function popStack()
    {
        deckTypesModel.clear();
        deckCardModel.clear();
        deckCardModel.currentDeck = null;

        while (stack.depth > 1) {
            stack.pop();
        }

        layout.currentDeck = -1;
        cardList.visible = false;
    }

    function showWith(ownedDecks, ownedCardsP)
    {
        if (null != ownedCardsP) {
            ownedCards = ownedCardsP;
        }

        popStack();

        let nextId = 0;
        for (let deck of ownedDecks)
        {
            let displayCardData = null;
            if (null != deck.displayCard) {
                displayCardData = repository.getCard(deck.displayCard.id, deck.displayCard.setId);
            }

            nextId = Math.max(deck.id + 1, nextId);
            pushDeck(deck, displayCardData);
        }

        pushNewDeck(nextId);

        addTimerDecks.start();

        layout.visible = true;
    }

    function pushDeck(deckData, displayCardData)
    {
        if (null != deckData)
        {
            let iconAction = "";
            let iconSocial = "";
            let iconClothes = "";
            let displayCardView =
                displayCardData != null ?
                    repository.getCardViewElements(displayCardData.id, displayCardData.setId) :
                    null;
            if (null != displayCardData) {
                let cardType =
                    displayCardData.tags.find((t) => t.startsWith(tagCard + ":"));
                if (null != cardType) {
                    let icons = repository.iconImages[cardType];
                    iconAction = icons[iconActionTag][iconNoneTag].image;
                    iconSocial = icons[iconSocialTag][iconNoneTag].image;
                    iconClothes = icons[iconClothesTag][iconNoneTag].image;
                }
            }

            let deckFilter = deckData.id + ";" + deckData.name + ";" +
                             genderStrings[deckData.gendering+1] + ";" +
                             deckData.tags.join(";");

            addTimerDecks.itemsToAdd.push({
                                 "id": deckData.id,
                                 "deckData": deckData,
                                 "displayCardData": displayCardData,
                                 "displayCardView": displayCardView,
                                 "cardLayout": (null != displayCardData ? displayCardData.layout : ""),
                                 "iconAction": iconAction,
                                 "iconSocial": iconSocial,
                                 "iconClothes": iconClothes,
                                 "projId": currentlyLoadedProject.id,
                                 "isAddNew": false,
                                 "bgImage": "image://DataBaseImageProivider/" +
                                            currentlyLoadedProject.id + "/" +
                                            "UnknownSvg",
                                 "deckFilter": deckFilter,
                                 "orderId": deckData.id
                            });
        }
    }

    function pushNewDeck(nextId)
    {
        addTimerDecks.itemsToAdd.push({
                            "id": nextId,
                            "deckData": null,
                            "displayCardData": null,
                            "displayCardView": null,
                            "cardLayout": "",
                            "iconAction": "",
                            "iconSocial": "",
                            "iconClothes": "",
                            "projId": currentlyLoadedProject.id,
                            "isAddNew": true,
                            "bgImage": "image://DataBaseImageProivider/" +
                                       currentlyLoadedProject.id + "/" +
                                       "IconAdd",
                            "deckFilter": "",
                            "orderId": 999999999
                        });
    }

    function rebuildPackModel()
    {
        deckTypesModel.clear();
        for (let pack of repository.packs) {
            let keys = Object.keys(pack.cards);
            for (let k of keys) {
                if (!k.startsWith("_") && pack.cards[k].length > 0) {
                    let setID = pack.cards[k][0].setId;
                    let cardId = pack.cards[k][0].id;
                    pushNewPack(pack, cardId, setID);
                    break;
                }
            }
        }
    }

    function pushNewPack(pack, cardId, setID)
    {
        let cardView = repository.getCardViewElements(cardId, setID);
        let deckFilter = pack.setId + ";" + pack.title + ";" +
                         pack.description + ";" + pack.faction + ";" +
                         pack.tags.join(";");
        if (null != cardView) {
            deckTypesModel.append({
                                    "pack": pack,
                                    "packImage": cardView.back.image,
                                    "projId": currentlyLoadedProject.id,
                                    "deckFilter": deckFilter,
                                    "orderId": pack.setId
                                });
        }
    }

    function cardKey(setId, id)
    {
        return setId + ";" + String(id).padStart(4, '0');
    }

    function getNrInDeck(setId, id)
    {
        return null != deckCardModel.currentDeck && null != deckCardModel.currentDeck.deck ?
                    deckCardModel.currentDeck.deck.filter(c => c.id === id && c.setId === setId).length :
                    0;
    }

    function rebuildDeckCardModel(deckData)
    {
        deckCardModel.clear();
        deckCardModel.currentDeck = deckData;
        deckCardModel.updateDeckCount();

        if (null != repository && null != deckData &&
            null != deckData.deck && null != deckData.sideDeck) {

            let vAllCardsSorted = [];
            if (deckData.deck) {
                for (const card of deckData.deck) {
                    vAllCardsSorted.push(card);
                }
            }

            vAllCardsSorted.sort((a, b) => {
                const setIdCompare = cardKey(a.setId,a.id).localeCompare(cardKey(b.setId,b.id));
                return setIdCompare;
            });

            for (const c of vAllCardsSorted) {
                let cardData = repository.getCard(c.id, c.setId);
                pushCard(addTimerDeckCards, cardData,
                         { "cardInDeck" : 1, "cardMax": 1, "display": "" }, true);
            }
        }

        addTimerDeckCards.start();
    }

    function rebuildCardModel(setId, deckData)
    {
        cardModel.clear();

        if (null != repository) {
            let vAllCardsSorted = [];
            if (null != ownedCards) {
                for (const card of ownedCards) {
                    if (card.setId === setId) {
                        vAllCardsSorted.push(card);
                    }
                }
            }

            vAllCardsSorted.sort((a, b) => {
                const setIdCompare = cardKey(a.setId,a.id).localeCompare(cardKey(b.setId,b.id));
                return setIdCompare;
            });

            for (const c of vAllCardsSorted) {
                let nrInDeck = getNrInDeck(c.setId, c.id);
                let cardData = repository.getCard(c.id, c.setId);
                let enabled = cardData.gendering === -1 || deckData.gendering === -1 ||
                    cardData.gendering === deckData.gendering;
                pushCard(addTimerCards,
                         cardData,
                         { "cardInDeck" : nrInDeck, "cardMax": c.count,
                           "display": nrInDeck + "/" + c.count },
                         enabled);
            }
        }

        addTimerCards.start();
    }

    function pushCard(timer, cardData, count, enabled)
    {
        if (null != cardData && null != cardData.id &&
            null != cardData.setId && -1 < cardData.id && "" !== cardData.setId)
        {
            let cardFilter = cardData.setId + ";" + cardData.id + ";" + cardData.title + ";" +
                             cardData.description + ";" + cardData.faction + ";" + cardData.cardType + ";" +
                             cardData.slot + ";" + cardData.rarity + ";" +
                             genderStrings[cardData.gendering+1] + ";" +
                             cardData.tags.join(";");
            timer.itemsToAdd.push({
                                 "enabled": enabled,
                                 "cardData": cardData,
                                 "cardViewElems": repository.getCardViewElements(cardData),
                                 "cardLayout": cardData.layout,
                                 "cardInDeck": count.cardInDeck,
                                 "cardMax": count.cardMax,
                                 "cardCount": count.display,
                                 "cardCountColor": count.cardInDeck >= maxInstancesOfCardInDeck ?
                                                       StyleParams.textColorError : StyleParams.textColorMenu,
                                 "projId": currentlyLoadedProject.id,
                                 "cardFilter": cardFilter,
                                 "genderFilter": cardData.gendering,
                                 "orderId": cardKey(cardData.setId, cardData.id)
                            });
        }
    }

    Timer {
        id: addTimerDecks
        interval: 100
        repeat: true
        running: false

        property var itemsToAdd: []
        property int nextItem: 0

        onTriggered: {
            if (0 < itemsToAdd.length) {
                deckModel.append(itemsToAdd.splice(0,1)[0]);

                nextItem++
            } else {
                stop();
            }
        }
    }
    Timer {
        id: addTimerDeckCards
        interval: 100
        repeat: true
        running: false

        property var itemsToAdd: []
        property int nextItem: 0

        onTriggered: {
            if (0 < itemsToAdd.length) {
                deckCardModel.append(itemsToAdd.splice(0,1)[0]);

                nextItem++
            } else {
                stop();
            }
        }
    }
    Timer {
        id: addTimerCards
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

    ListModel {
        id: deckModel
        dynamicRoles: false
    }
    ListModel {
        id: deckTypesModel
        dynamicRoles: false
    }
    ListModel {
        id: deckCardModel
        dynamicRoles: false

        property var currentDeck: null
        signal updateDeckCount();
    }
    ListModel {
        id: cardModel
        dynamicRoles: false
    }

    StackView {
        id: stack
        initialItem: stackViewItemDecks

        y: StyleParams.hexHeight
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - StyleParams.hexWidth*2
        height: cardList.visible ?
                    (parent.height - StyleParams.hexHeight) / 2 :
                    (parent.height - StyleParams.hexHeight*2)

        pushEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to:1
                duration: 200
            }
        }
        pushExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to:0
                duration: 200
            }
        }
        popEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to:1
                duration: 200
            }
        }
        popExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to:0
                duration: 200
            }
        }
    }

    Component {
        id: stackViewItemDecks

        GridView {
            id: deckList
            width: stack.width
            height: stack.height

            cellWidth: StyleParams.deckCollectionWidthMin+10
            cellHeight: StyleParams.deckCollectionHeightMin+10

            flow: GridView.FlowLeftToRight
            layoutDirection: Qt.LeftToRight
            verticalLayoutDirection: GridView.TopToBottom

            signal addNewDeck(int newId)
            signal openDeck(int id, var deckData)

            onAddNewDeck: {
                layout.currentDeck = newId;
                layout.rebuildPackModel();
                stack.push(deckCardListView);
                stack.push(newDeckSelect);
            }
            onOpenDeck: {
                layout.currentDeck = id;
                stack.push(deckCardListView);
                layout.rebuildDeckCardModel(deckData);
                layout.rebuildCardModel(deckData.sets.length > 0 ? deckData.sets[0] : "",
                                        deckData);
                cardList.visible = true;
            }

            clip: false
            highlightFollowsCurrentItem: true
            highlight: Rectangle {
                color: "transparent"
                width: deckList.cellWidth
                height: deckList.cellHeight
                x: null != deckList.currentItem ? deckList.currentItem.x : 0
                y: null != deckList.currentItem ? deckList.currentItem.y : 0
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

                sourceModel: deckModel
                filters: AllOf {
                    filters: [
                        RegExpFilter {
                            roleName: "deckFilter"
                            pattern: filterTextArea.text === "" ? ".*" : filterTextArea.text
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
                id: thisDeck
                width: StyleParams.deckCollectionWidthMin
                height: StyleParams.deckCollectionHeightMin
                color: "transparent"

                property int itemMargin: 10

                Image {
                    y: thisDeck.itemMargin
                    width: parent.width - thisDeck.itemMargin*2
                    height: parent.height - thisDeck.itemMargin*2
                    anchors.horizontalCenter: parent.horizontalCenter

                    asynchronous: true
                    smooth: Settings.playerImageSmooth
                    antialiasing: Settings.playerAntialiasing
                    mipmap: Settings.playerImageMipMap
                    source: model.bgImage;
                    fillMode: Image.PreserveAspectFit
                }
                Loader {
                    id: cardLoader
                    anchors.fill: parent
                    source: ""
                    asynchronous: true
                    visible: status === Loader.Ready

                    onLoaded: {
                        item.cardData = model.displayCardData;
                        item.cardViewElems = model.displayCardView;
                    }
                }

                Rectangle {
                    id: deckBox
                    anchors.fill: parent
                    color: "black"
                    border.color: "green"
                    border.width: 2
                    visible: false
                }
                Item {
                    id: maskContainer
                    anchors.fill: parent
                    visible: false
                    Rectangle {
                        x: 10
                        y: 10
                        width: parent.width - 2*thisDeck.itemMargin
                        height: parent.height/2 - 2*thisDeck.itemMargin
                        color: "white"
                    }
                }
                OpacityMask {
                    anchors.fill: parent
                    source: deckBox
                    maskSource: maskContainer
                    invert: true
                    visible: !model.isAddNew
                }

                HexLineShape {
                    y: parent.height/2 + thisDeck.itemMargin +
                       StyleParams.strokeColorHexActiveWidth - height/2
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width-20
                    height: StyleParams.hexHeight

                    visible: model.deckData != null

                    Text {
                        anchors.fill: parent

                        text: model.deckData != null ? model.deckData.name : ""

                        font.family: null != root.currentlyLoadedProject ?
                                         root.currentlyLoadedProject.font : "Arial"
                        font.pixelSize: StyleParams.menuTextPonintSize
                        font.hintingPreference: Font.PreferNoHinting

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideNone
                        wrapMode: Text.WordWrap
                        color: StyleParams.textColorMenu
                        textFormat: Text.RichText
                    }
                }

                Image {
                    id: gender
                    x: 0
                    y: parent.height - height
                    width: StyleParams.deckCollectionGenderWidth
                    height: StyleParams.deckCollectionGenderHeight

                    asynchronous: true
                    smooth: Settings.playerImageSmooth
                    antialiasing: Settings.playerAntialiasing
                    mipmap: Settings.playerImageMipMap

                    source: model.deckData != null ?
                                repository.commonIconSets["icontype:gender"][""+model.deckData.gendering].image :
                                ""
                    visible: model.deckData != null
                }

                HexShape {
                    id: itemCountSideDeck
                    x: parent.width - width - 2
                    y: parent.height - height - 2
                    width: StyleParams.hexWidth
                    height: StyleParams.hexHeight

                    fillColor: StyleParams.fillColorHexActive
                    strokeColor: StyleParams.strokeColorHexActive
                    strokeWidth: StyleParams.strokeColorHexActiveWidth

                    visible: model.deckData != null

                    Image {
                        anchors.centerIn: parent
                        width: parent.width - 10
                        height: parent.height - 10

                        asynchronous: true
                        smooth: Settings.playerImageSmooth
                        antialiasing: Settings.playerAntialiasing
                        mipmap: Settings.playerImageMipMap

                        source: model.iconClothes
                    }
                }
                Text {
                    x: itemCountSideDeck.x - width
                    y: itemCountSideDeck.y + height
                    width: itemCountSideDeck.width
                    height: itemCountSideDeck.height / 2

                    text: model.deckData != null ? model.deckData.numSocial : 0

                    font.italic: true
                    font.family: null != root.currentlyLoadedProject ?
                                     root.currentlyLoadedProject.font : "Arial"
                    font.pixelSize: StyleParams.cardCountPonintSize
                    font.hintingPreference: Font.PreferNoHinting

                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideNone
                    wrapMode: Text.WordWrap
                    color: StyleParams.textColorMenu
                    textFormat: Text.RichText

                    visible: itemCountSideDeck.visible
                }

                HexShape {
                    id: shapeNumSocial
                    x: itemCountSideDeck.x - width*3/4
                    y: itemCountSideDeck.y - height / 2
                    width: StyleParams.hexWidth
                    height: StyleParams.hexHeight

                    fillColor: StyleParams.fillColorHexActive
                    strokeColor: StyleParams.strokeColorHexActive
                    strokeWidth: StyleParams.strokeColorHexActiveWidth

                    visible: model.deckData != null

                    Image {
                        anchors.centerIn: parent
                        width: parent.width - 10
                        height: parent.height - 10

                        asynchronous: true
                        smooth: Settings.playerImageSmooth
                        antialiasing: Settings.playerAntialiasing
                        mipmap: Settings.playerImageMipMap

                        source: model.iconSocial
                    }
                }
                Text {
                    x: shapeNumSocial.x - width
                    y: shapeNumSocial.y
                    width: shapeNumSocial.width
                    height: shapeNumSocial.height / 2

                    text: model.deckData != null ? model.deckData.numSocial : 0

                    font.italic: true
                    font.family: null != root.currentlyLoadedProject ?
                                     root.currentlyLoadedProject.font : "Arial"
                    font.pixelSize: StyleParams.cardCountPonintSize
                    font.hintingPreference: Font.PreferNoHinting

                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideNone
                    wrapMode: Text.WordWrap
                    color: StyleParams.textColorMenu
                    textFormat: Text.RichText

                    visible: shapeNumSocial.visible
                }

                HexShape {
                    id: shapeNumAction
                    x: itemCountSideDeck.x
                    y: itemCountSideDeck.y - height
                    width: StyleParams.hexWidth
                    height: StyleParams.hexHeight

                    fillColor: StyleParams.fillColorHexActive
                    strokeColor: StyleParams.strokeColorHexActive
                    strokeWidth: StyleParams.strokeColorHexActiveWidth

                    visible: model.deckData != null

                    Image {
                        anchors.centerIn: parent
                        width: parent.width - 10
                        height: parent.height - 10

                        asynchronous: true
                        smooth: Settings.playerImageSmooth
                        antialiasing: Settings.playerAntialiasing
                        mipmap: Settings.playerImageMipMap

                        source: model.iconAction
                    }
                }
                Text {
                    x: shapeNumAction.x - width
                    y: shapeNumAction.y
                    width: shapeNumAction.width
                    height: shapeNumAction.height / 2

                    text: model.deckData != null ? model.deckData.numAction : ""+0

                    font.italic: true
                    font.family: null != root.currentlyLoadedProject ?
                                     root.currentlyLoadedProject.font : "Arial"
                    font.pixelSize: StyleParams.cardCountPonintSize
                    font.hintingPreference: Font.PreferNoHinting

                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideNone
                    wrapMode: Text.WordWrap
                    color: StyleParams.textColorMenu
                    textFormat: Text.RichText

                    visible: shapeNumAction.visible
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        let oldX = deckList.contentX;
                        let oldY = deckList.contentY
                        deckList.currentIndex = index;
                        deckList.contentX = oldX;
                        deckList.contentY = oldY;
                    }

                    onClicked: {
                        if (model.isAddNew) {
                            deckList.addNewDeck(model.id);
                        } else {
                            deckList.openDeck(model.id, model.deckData);
                        }
                    }
                }

                Connections {
                    target: thisDeck

                    function onVisibleChanged() {
                        if (thisDeck.visible && cardLoader.status === Loader.Null &&
                            model.cardLayout !== "") {

                            cardLoader.source = model.cardLayout;
                        }
                    }
                }

                Component.onCompleted: {
                    if (visible && model.cardLayout !== "") {
                        cardLoader.source = model.cardLayout;
                    }
                }
            }

            remove: Transition {
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation {
                            property: "y"
                            from: deckList.contentY
                            to: deckList.contentY - 100
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
                            from: deckList.contentY + 100
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

                visible: stack.depth == 1

                parent: deckList.parent

                anchors.top: deckList.top
                anchors.bottom: deckList.bottom
                x: StyleParams.dominantHand === DominantHand.Left ?
                    deckList.x + deckList.width + (StyleParams.hexWidth - width)/2 :
                    deckList.x - (StyleParams.hexWidth + width)/2
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
    }

    Component {
        id: newDeckSelect

        ListView {
            id: deckSelectView
            width: parent.width
            height: parent.height-StyleParams.hexHeight

            property real cellWidth: StyleParams.deckCollectionWidthMin
            property real cellHeight: StyleParams.deckCollectionHeightMin

            orientation: ListView.Horizontal
            verticalLayoutDirection: GridView.TopToBottom

            signal setClicked(var setId)

            onSetClicked: {
                let deckData = {
                    "id": layout.currentDeck,
                    "deck": [],
                    "sideDeck": [],
                    "displayCard": null,
                    "sets": [ setId ],
                    "gendering": -1,
                    "numSocial": 0,
                    "numAction": 0,
                    "tags": []
                };
                layout.rebuildDeckCardModel(deckData);
                layout.rebuildCardModel(setId, deckData);
                stack.pop();
                cardList.visible = true;
            }

            clip: false

            model: SortFilterProxyModel {
                id: deckTypeProxyModel

                sourceModel: deckTypesModel
                filters: AllOf {
                    filters: [
                        RegExpFilter {
                            roleName: "deckFilter"
                            pattern: filterTextArea.text === "" ? ".*" : filterTextArea.text
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
                id: thisPackType
                width: deckSelectView.cellWidth
                height: deckSelectView.cellHeight
                color: "transparent"

                property int itemMargin: 10
                property bool selected: false

                Loader {
                    id: packLoader
                    y: thisPackType.itemMargin
                    width: parent.width - thisPackType.itemMargin*2
                    height: parent.height - thisPackType.itemMargin*2
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: model.pack.layout
                    asynchronous: true
                    visible: !thisPackType.selected && status === Loader.Ready

                    onLoaded: {
                        item.packData = model.pack;
                    }
                }

                Glow {
                    anchors.fill: packLoader
                    radius: StyleParams.glowHexRadius
                    color: StyleParams.glowHexColor
                    source: packLoader
                    enabled: thisPackType.selected
                    visible: thisPackType.selected
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        thisPackType.selected = !thisPackType.selected;
                        deckSelectView.setClicked(model.pack.setId);
                    }
                }
            }

            remove: Transition {
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation {
                            property: "y"
                            from: deckSelectView.contentY
                            to: deckSelectView.contentY - 100
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
                            from: deckSelectView.contentY + 100
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
                id: scrollVDeckTypes
                orientation: Qt.Vertical
                policy: Qt.ScrollBarAlwaysOn

                visible: stack.depth == 3

                parent: deckSelectView.parent

                anchors.top: deckSelectView.top
                anchors.bottom: deckSelectView.bottom
                x: StyleParams.dominantHand === DominantHand.Left ?
                    deckSelectView.x + deckSelectView.width + (StyleParams.hexWidth - width)/2 :
                    deckSelectView.x - (StyleParams.hexWidth + width)/2
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
    }

    Component {
        id: deckCardListView

        CardGrid {
            id: deckCardList
            width: stack.width
            height: stack.height

            cellHintWidth: StyleParams.deckBuildingWidthMin
            cellHintHeight: StyleParams.deckBuildingHeightMin
            cellMargin: 5

            flow: GridView.FlowLeftToRight
            layoutDirection: Qt.LeftToRight
            verticalLayoutDirection: GridView.TopToBottom

            showCardCount: false
            innerMouseAreaEnabled: true

            sourceModel: deckCardModel
            filterPattern: filterTextArea.text === "" ? ".*" : filterTextArea.text

            onItemClicked: {
                // get card and enabled state plus source index
                let cardData = repository.getCard(id, setId);
                let enabled = model.get(index, "enabled");
                let sourceRow = model.mapToSource(index);

                if (null != cardData && enabled &&
                    null != deckCardModel.currentDeck) {

                    // modify the current deck
                    deckCardModel.currentDeck.deck.splice(index, 1);
                    deckCardModel.updateDeckCount();

                    let newGendering = -1;
                    for (let c of deckCardModel.currentDeck.deck) {
                        if (c.gendering !== -1) {
                            newGendering = c.gendering;
                            break;
                        }
                    }
                    deckCardModel.currentDeck.gendering = newGendering;

                    if (cardData.cardType === layout.actionType) {
                        deckCardModel.currentDeck.numAction--;
                    } else if (cardData.cardType === layout.socialType) {
                        deckCardModel.currentDeck.numSocial--;
                    }

                    // modify model
                    deckCardModel.remove(sourceRow);

                    // modify the card model
                    let indexInCardModel = -1;
                    for (let i = 0; i < cardList.model.count; ++i) {
                        let modelInList = cardList.model.get(i, "cardData");
                        if (modelInList.id === id && modelInList.setId === setId) {
                            indexInCardModel = i;
                            break;
                        }
                    }

                    if (-1 != indexInCardModel)
                    {
                        sourceRow = cardList.model.mapToSource(indexInCardModel);
                        let nrInDeck = layout.getNrInDeck(setId, id);
                        let max = cardList.model.get(indexInCardModel, "cardMax");
                        if (layout.maxInstancesOfCardInDeck <= nrInDeck || nrInDeck >= max) {
                            cardModel.setProperty(sourceRow, "cardCountColor", StyleParams.textColorError);
                        } else {
                            cardModel.setProperty(sourceRow, "cardCountColor", StyleParams.textColorMenu);
                        }
                        cardModel.setProperty(sourceRow, "cardInDeck", nrInDeck);
                        cardModel.setProperty(sourceRow, "cardCount", ""+nrInDeck+"/"+max);
                    }

                    // Update enabled state of all cards
                    cardList.updateEnabledStateOfAll();
                }
            }

            ScrollBar.vertical.visible: stack.depth == 2

            removeDisplaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
            add: Transition {
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

            Text {
                id: deckCounter
                width: parent.width
                height: StyleParams.menuTextPonintSize + 2
                anchors.top: parent.top

                text: "" + deckCardModel.currentDeck.deck.length + "/" + layout.maxDeckSize

                function updateCount()
                {
                    if (null != deckCardModel.currentDeck)
                    {
                        text = "" + deckCardModel.currentDeck.deck.length + "/" + layout.maxDeckSize;
                        if (deckCardModel.currentDeck.deck.length < layout.minDeckSize)
                        {
                            color = StyleParams.textColorWarn;
                        }
                        else if (deckCardModel.currentDeck.deck.length >= layout.maxDeckSize)
                        {
                            color = StyleParams.textColorError;
                        }
                        else
                        {
                            color = StyleParams.textColorMenu;
                        }
                    }
                }

                font.family: null != root.currentlyLoadedProject ?
                                 root.currentlyLoadedProject.font : "Arial"
                font.pixelSize: StyleParams.menuTextPonintSize
                font.hintingPreference: Font.PreferNoHinting

                horizontalAlignment: StyleParams.dominantHand === DominantHand.Left ?
                                         Text.AlignLeft : Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
                wrapMode: Text.WordWrap
                color: StyleParams.textColorMenu
                textFormat: Text.PlainText

                Connections {
                    target: deckCardModel
                    onUpdateDeckCount: {
                        deckCounter.updateCount();
                    }
                }
            }

            Component.onCompleted: {
                deckCounter.updateCount();
            }
        }
    }

    CardGrid {
        id: cardList
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: parent.width - StyleParams.hexWidth*2
        height: visible ? (parent.height - StyleParams.hexHeight)/2 : 0

        visible: false

        Behavior on height {
            NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
        }

        cellHintWidth: StyleParams.cardCollectionWidthMin
        cellHintHeight: StyleParams.cardCollectionHeightMin
        cellMargin: 10

        flow: GridView.FlowLeftToRight
        layoutDirection: Qt.LeftToRight
        verticalLayoutDirection: GridView.TopToBottom

        innerMouseAreaEnabled: true

        sourceModel: cardModel
        filterPattern: filterTextArea.text === "" ? ".*" : filterTextArea.text

        function updateEnabledStateOfAll() {
            for (let idx = 0; model.count > idx; ++idx) {
                let sourceRow = model.mapToSource(idx);
                let genderingCard = model.get(idx, "genderFilter");
                let enabled = genderingCard === -1 ||
                    deckCardModel.currentDeck.gendering === -1 ||
                    genderingCard === deckCardModel.currentDeck.gendering;
                cardModel.setProperty(sourceRow, "enabled", enabled);
            }
        }

        function createAndRunCardFlier(from, to, sourceSize, destSize,
                                       parent,
                                       delegate, card, cardViewElems,
                                       fnToRunAfter)
        {
            var flyer = flyingComponent.createObject(parent, {
                "x": from.x,
                "y": from.y,
                "width": sourceSize.width,
                "height": sourceSize.height,
                "endX": to.x,
                "endY": to.y,
                "endWidth": destSize.width,
                "endHeight": destSize.height,
                "delegate": delegate,
                "cardData": card,
                "cardViewElems": cardViewElems,
                "finishFunction": fnToRunAfter
            });

            if (flyer === null) {
                console.log(qsTr("Could not create flying delegate"));
                return;
            };

            flyer.start();
        }

        onItemClicked: {
            // get card and enabled state plus source index
            let cardData = repository.getCard(id, setId);
            let cardView = repository.getCardViewElements(cardData);
            let enabled = model.get(index, "enabled");
            let sourceRow = model.mapToSource(index);

            let nrInDeck = getNrInDeck(setId, id);
            let max = model.get(index, "cardMax");
            let delegateType = model.get(index, "cardLayout");

            if (null != cardData && enabled &&
                nrInDeck < max && nrInDeck < layout.maxInstancesOfCardInDeck &&
                null != deckCardModel.currentDeck) {

                let item = itemAtIndex(index);
                let from = item.mapToItem(layout, 0.0, 0.0);
                let to = Qt.point(stack.x, stack.y);
                let sourceSize = Qt.size(item.width, item.height);
                let destSize = Qt.size(StyleParams.deckBuildingWidthMin + 5,
                                       StyleParams.deckBuildingHeightMin + 5);

                // modify the current deck
                if (deckCardModel.currentDeck.gendering === -1) {
                    deckCardModel.currentDeck.gendering = cardData.gendering;
                }
                deckCardModel.currentDeck.deck.push({"setId": setId, "id": id});
                deckCardModel.currentDeck.deck.sort((a, b) => {
                    const setIdCompare = cardKey(a.setId,a.id).localeCompare(cardKey(b.setId,b.id));
                    return setIdCompare;
                });
                deckCardModel.updateDeckCount();
                if (cardData.cardType === layout.actionType) {
                    deckCardModel.currentDeck.numAction++;
                } else if (cardData.cardType === layout.actionType) {
                    deckCardModel.currentDeck.numSocial++;
                }

                // modify the item models
                nrInDeck = getNrInDeck(setId, id);
                if (layout.maxInstancesOfCardInDeck <= nrInDeck || nrInDeck >= max) {
                    cardModel.setProperty(sourceRow, "cardCountColor", StyleParams.textColorError);
                } else {
                    cardModel.setProperty(sourceRow, "cardCountColor", StyleParams.textColorMenu);
                }
                cardModel.setProperty(sourceRow, "cardInDeck", nrInDeck);
                cardModel.setProperty(sourceRow, "cardCount", ""+nrInDeck+"/"+max);

                // Update enabled state of all cards
                updateEnabledStateOfAll();

                createAndRunCardFlier(from, to, sourceSize, destSize,
                                      layout, delegateType, cardData, cardView,
                                      function(){

                    // push the card into the deck's item model
                    pushCard(addTimerDeckCards, cardData,
                             { "cardInDeck" : 1, "cardMax": 1, "display": "" }, true);
                    addTimerDeckCards.start();
                });
            }
        }

        ScrollBar.vertical.visible: stack.depth == 2
    }

    // This Component is a factory, not a single reusable animation.
    Component {
        id: flyingComponent

        Item {
            id: flyer

            width: 40
            height: 40

            property real endX: 0
            property real endY: 0
            property real endWidth: 0
            property real endHeight: 0
            property string delegate: ""
            property var cardData: null
            property var cardViewElems: null
            property var finishFunction: null

            function start() {
                animation.start()
            }

            Loader {
                anchors.fill: parent
                source: flyer.delegate
                asynchronous: false
                visible: true

                onLoaded: {
                    item.currentlyLoadedProjectId = layout.currentlyLoadedProject.id
                    item.cardData = flyer.cardData
                    item.cardViewElems = flyer.cardViewElems
                }
            }

            ParallelAnimation {
                id: animation

                NumberAnimation {
                    target: flyer
                    property: "x"
                    to: flyer.endX
                    duration: 600
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: flyer
                    property: "y"
                    to: flyer.endY
                    duration: 600
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: flyer
                    property: "width"
                    to: flyer.endWidth
                    duration: 600
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: flyer
                    property: "height"
                    to: flyer.endHeight
                    duration: 600
                    easing.type: Easing.OutCubic
                }

                onStopped: {
                    flyer.finishFunction();
                    flyer.destroy();
                }
            }
        }
    }

    HexButtonWithToolTip {
        id: searchButton
        x: 0
        y: 0
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
        y: 0
        width: {
            if (StyleParams.hexWidth * 7 > parent.width) {
                let hexStride = StyleParams.hexWidth*0.75;
                let numCols = Math.floor(parent.width / hexStride) - 1;

                // Last column with the same parity as column 1
                let lastCol = numCols % 2 === 0
                        ? numCols - 1
                        : numCols;

                return Math.max(0, (lastCol - 1) * hexStride - StyleParams.hexWidth);
            }
            return StyleParams.hexWidth * 5;
        }
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

        background: HexLineShape {
            width: parent.width
            height: parent.height
        }
    }
}
