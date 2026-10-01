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

    readonly property int placeWidth: 50
    readonly property int placeHeight: 50
    readonly property int travelDuration: 3000

    readonly property string textColorMenu: "white"
    readonly property string fillColorHexActive: "#282828"
    readonly property string strokeColorHexActive: "black"
    readonly property int strokeColorHexActiveWidth: 2
    readonly property string fillColorHexInactive: "black"
    readonly property string strokeColorHexInactive: "#282828"
    readonly property int strokeColorHexInactiveWidth: 2
    readonly property string glowHexColor: "#00B4DE"
    readonly property int glowHexRadius: 15
    readonly property real glowHexSpread: 0.5

    readonly property string colorPlayerBorder: "#ff00ff"
    readonly property string colorCurrentPlace: "#ff00ff"
    readonly property string colorPlaceBg: "black"
    readonly property string colorTravel: "#ff00ff"
    readonly property string primaryColorSelection: "#ff00ff"
    readonly property string secondaryColorSelection: "#660066"
    readonly property string tertiaryColorSelection: "#880088"

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
    readonly property string exitButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonExit"
    readonly property string exitHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "ButtonExitHover"
    readonly property string unknownMap: "UnknownSvg"
    readonly property string unknownIcon: "UnknownSvg"
    readonly property string fogTexture: "Clouds"
    readonly property int fogTextureWidth: 524
    readonly property int fogTextureHeight: 265
}
