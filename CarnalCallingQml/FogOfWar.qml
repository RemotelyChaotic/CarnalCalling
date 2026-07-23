import QtQuick 2.14

Rectangle {
    id: fogEffect
    anchors.fill: parent
    color: "transparent"

    property real playerX: 0
    property real playerY: 0
    property real radius: 200
    property real feather: 100
    property real fogOpacity: 0.7

    property int mapWidthFull: 1024
    property int mapHeightFull: 1024

    property string cloudSource: ""
    property int cloudTextureWidth: 512
    property int cloudTextureHeight: 512

    property var explorationData: []
    property int explorationDataWidth: 512
    property int explorationDataHeight: 512

    onExplorationDataChanged: {
        dataCanvas.requestPaint();
    }

    ShaderEffect {
        id: fogEffectShader
        anchors.fill: parent

        property real playerX: fogEffect.playerX
        property real playerY: fogEffect.playerY
        property real radius: fogEffect.radius
        property real feather: fogEffect.feather
        property real fogOpacity: fogEffect.fogOpacity

        property vector2d mapResolution: Qt.vector2d(fogEffect.mapWidthFull, fogEffect.mapHeightFull)
        property vector2d screenResolution: Qt.vector2d(width, height)

        // Texure for clouds
        Image {
            id: cloudImage
            source: fogEffect.cloudSource
            sourceSize.width: fogEffect.cloudTextureWidth
            sourceSize.height: fogEffect.cloudTextureHeight
            visible: false // Keep it hidden; we only need its texture cache
        }
        property var cloudTexture: cloudImage
        property vector2d cloudResolution: Qt.vector2d(fogEffect.cloudTextureWidth, fogEffect.cloudTextureHeight)

        Canvas {
            id: dataCanvas
            width: fogEffect.explorationDataWidth
            height: fogEffect.explorationDataHeight
            visible: false // Keep it hidden; we only need its texture cache
            renderTarget: Canvas.Image
            renderStrategy: Canvas.Cooperative

            onPaint: {
                var ctx = getContext("2d");
                if (fogEffect.explorationData.length === 0) { return; }

                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = "rgba(0,0,0,1)";

                // do some vector rendering
                for (var y = 0; y < height; ++y) {
                    var x = 0;
                    while (x < width) {
                        while (x < width && !fogEffect.explorationData[x + y * width]) {
                            ++x;
                        }

                        var start = x;

                        while (x < width && fogEffect.explorationData[x + y * width]) {
                            ++x;
                        }

                        if (start < x) {
                            ctx.fillRect(start, y, x - start, 1);
                        }
                    }
                }
            }
        }
        property var explorationTexture: dataCanvas
        property vector2d explorationResulution: Qt.vector2d(fogEffect.explorationDataWidth, fogEffect.explorationDataHeight)

        // Update timer to animate the texture
        property real timeOffset: 0
        Timer {
            id: updateTimer
            interval: 16
            running: true
            repeat: true

            property var lastDateMs: { return new Date().getTime(); }

            onTriggered: {
                var newDateMs = new Date().getTime();
                var diffMs = newDateMs - lastDateMs;
                lastDateMs = newDateMs;
                fogEffectShader.timeOffset += diffMs/interval;
            }
        }

        fragmentShader: "
            precision mediump float;

            uniform highp float playerX;
            uniform highp float playerY;
            uniform highp float radius;
            uniform highp float feather;
            uniform lowp float fogOpacity;

            uniform highp float qt_Opacity;

            uniform highp vec2 mapResolution;
            uniform highp vec2 screenResolution;

            uniform sampler2D cloudTexture;
            uniform highp vec2 cloudResolution;

            uniform sampler2D explorationTexture;
            uniform highp vec2 explorationResulution;

            uniform mediump float timeOffset;

            varying highp vec2 qt_TexCoord0;

            void main()
            {
                vec2 p = qt_TexCoord0 * screenResolution;
                float d = distance(p, vec2(playerX, playerY));
                float alpha = smoothstep(radius, radius + feather, d);

                vec2 uvCloudTex = fract(vec2(p.x + timeOffset/2.0, p.y) / cloudResolution);
                vec4 cloudColor = texture2D(cloudTexture, uvCloudTex);

                vec4 explorationData = texture2D(explorationTexture, qt_TexCoord0);

                float explored = step(0.5, explorationData.a * alpha);
                vec4 fog = vec4(0.0, 0.0, 0.0,
                                alpha * fogOpacity * qt_Opacity);
                vec4 clouds = cloudColor;
                gl_FragColor = mix(fog,
                                    mix(fog, clouds, clouds.a),
                                    explored);
            }
        "
    }

    Component.onCompleted: {
        dataCanvas.requestPaint();
    }
}