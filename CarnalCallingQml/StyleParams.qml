pragma Singleton

import QtQuick 2.14
import JOIP.core 1.5

QtObject {
    property int currentProjectId: -1

    readonly property bool isMobile: Settings.platform === "Android"
    readonly property int dominantHand: Settings.dominantHand

    readonly property int iconWidth: isMobile ? 32 : 48
    readonly property int iconHeight: isMobile ? 32 : 48
    readonly property int hexWidth: isMobile ? 32 : 48
    readonly property int hexHeight: isMobile ? 32 : 48
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

    readonly property string colorPlayerBorder: "#ff00ff"
    readonly property string colorCurrentPlace: "#ff00ff"
    readonly property string colorPlaceBg: "black"
    readonly property string colorTravel: "#ff00ff"
    readonly property string primaryColorSelection: "#ff00ff"
    readonly property string secondaryColorSelection: "#660066"
    readonly property string tertiaryColorSelection: "#880088"

    readonly property string optionsButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "UnknownSvg"
    readonly property string optionsHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "UnknownSvg"
    readonly property string cardsButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "UnknownSvg"
    readonly property string cardsHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "UnknownSvg"
    readonly property string decksButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "UnknownSvg"
    readonly property string decksHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "UnknownSvg"
    readonly property string travelButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "UnknownSvg"
    readonly property string travelHoverButton: "image://DataBaseImageProivider/" + currentProjectId + "/" + "UnknownSvg"
    readonly property string pauseButton: Settings.styleFolderQml() + "/ButtonPause.svg"
    readonly property string pauseHoverButton: Settings.styleFolderQml() + "/ButtonPauseHover.svg"
    readonly property string playButton: Settings.styleFolderQml() + "/ButtonPlay.svg"
    readonly property string playHoverButton: Settings.styleFolderQml() + "/ButtonPlayHover.svg"
    readonly property string visibleButton: Settings.styleFolderQml() + "/ButtonVisible.svg"
    readonly property string visibleHoverButton: Settings.styleFolderQml() + "/ButtonVisibleHover.svg"
    readonly property string inVisibleButton: Settings.styleFolderQml() + "/ButtonInvisible.svg"
    readonly property string inVisibleHoverButton: Settings.styleFolderQml() + "/ButtonInvisibleHover.svg"
    readonly property string devicesButton: Settings.styleFolderQml() + "/ButtonPlug.png"
    readonly property string devicesHoverButton: Settings.styleFolderQml() + "/ButtonPlugHover.png"
    readonly property string exitButton: Settings.styleFolderQml() + "/ButtonExit.svg"
    readonly property string exitHoverButton: Settings.styleFolderQml() + "/ButtonExitHover.svg"
    readonly property string unknownMap: "UnknownSvg"
    readonly property string unknownIcon: "UnknownSvg"
    readonly property string fogTexture: "Clouds"
    readonly property int fogTextureWidth: 524
    readonly property int fogTextureHeight: 265
}