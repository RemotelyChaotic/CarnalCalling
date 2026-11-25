pragma Singleton

import QtQuick 2.14
import JOIP.core 1.5

QtObject {
    property int currentProjectId: -1

    readonly property bool isMobile: Settings.platform === "Android"
    readonly property int dominantHand: Settings.dominantHand

    readonly property real iconWidth: isMobile ? 32 : 48
    readonly property real iconHeight: iconWidth * 0.8660254
    readonly property real hexWidth: isMobile ? 32 : 48
    readonly property real hexHeight: hexWidth * 0.8660254
    readonly property int menuTextPonintSize: 14
    readonly property int cardTitleTextPonintSize: 60
    readonly property int cardDescTextPonintSize: 50
    readonly property int cardCreditsTextPonintSize: 40
    readonly property int cardCountPonintSize: 12
    readonly property int toolTipTitleSize: 16
    readonly property int toolTipPonintSize: 12

    readonly property real cardWidthOrig: 1080
    readonly property real cardHeightOrig: 1920
    readonly property real cardCollectionWidthMin: isMobile ? 72 : 108
    readonly property real cardCollectionHeightMin: isMobile ? 128 : 192
    readonly property real deckBuildingWidthMin: isMobile ? 48 : 72
    readonly property real deckBuildingHeightMin: isMobile ? 85 : 128
    readonly property real deckCollectionWidthMin: isMobile ? 108 : 162
    readonly property real deckCollectionHeightMin: isMobile ? 192 : 288
    readonly property real deckCollectionGenderWidth: isMobile ? 33 : 50
    readonly property real deckCollectionGenderHeight: isMobile ? 33 : 50
    readonly property real toolTipHeight: isMobile ? 200 : 200
    readonly property real toolTipWidth: isMobile ? 150 : 150
    readonly property real toolTiptitleHeight: 20

    readonly property int placeWidth: 50
    readonly property int placeHeight: 50
    readonly property int travelDuration: 3000

    readonly property string textColorMenu: "white"
    readonly property string textColorWarn: "orange"
    readonly property string textColorError: "red"
    readonly property string textOutlineColorMenu: "#151515"
    readonly property string placeholderTextColorMenu: "#565656"
    readonly property string fillColorHexActive: "#2A2A2A"
    readonly property string strokeColorHexActive: "#151515"
    readonly property int strokeColorHexActiveWidth: 2
    readonly property string fillColorHexInactive: "#151515"
    readonly property string strokeColorHexInactive: "#2A2A2A"
    readonly property int strokeColorHexInactiveWidth: 2
    readonly property string glowHexColor: "#6CC929"
    readonly property int glowHexRadius: 15
    readonly property real glowHexSpread: 0.5
    readonly property string cursorColor: "#6CC929"
    readonly property int cursorWidth: 2

    readonly property string colorPlayerBorder: "#6CC929"
    readonly property string colorCurrentPlace: "#6CC929"
    readonly property string colorPlaceBg: "#151515"
    readonly property string colorTravel: "#6CC929"
    readonly property string primaryColorSelection: "#6CC929"
    readonly property string secondaryColorSelection: "#14747E"
    readonly property string tertiaryColorSelection: "#218984"

    readonly property string optionsButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonOptions"
    readonly property string optionsHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonOptionsHover"
    readonly property string cardsButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonCards"
    readonly property string cardsHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonCardsHover"
    readonly property string decksButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonDeck"
    readonly property string decksHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonDeckHover"
    readonly property string travelButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "UnknownSvg"
    readonly property string travelHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "UnknownSvg"
    readonly property string pauseButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonPause"
    readonly property string pauseHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonPauseHover"
    readonly property string playButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonPlay"
    readonly property string playHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonPlayHover"
    readonly property string visibleButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonVisible"
    readonly property string visibleHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonVisibleHover"
    readonly property string inVisibleButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonInvisible"
    readonly property string inVisibleHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonInvisibleHover"
    readonly property string devicesButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonPlug"
    readonly property string devicesHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonPlugHover"
    readonly property string backButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonBack"
    readonly property string backHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonBackHover"
    readonly property string exitButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonExit"
    readonly property string exitHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonExitHover"
    readonly property string searchButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonSearch"
    readonly property string searchHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonSearchHover"
    readonly property string onlyShowOwnedButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonOnlyShowOwned"
    readonly property string onlyShowOwnedHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonOnlyShowOwnedHover"
    readonly property string unknownMap: "UnknownSvg"
    readonly property string unknownIcon: "UnknownSvg"
    readonly property string fogTexture: "Clouds"
    readonly property int fogTextureWidth: 524
    readonly property int fogTextureHeight: 265
}
