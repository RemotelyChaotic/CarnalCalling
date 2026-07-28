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

    // true means explored, false means unexplored
    property var explorationData: []
    property int explorationDataColumns: 512
    property int explorationDataRows: 512
    signal explorationDataUpdated()

    onExplorationDataChanged: {
        dataCanvas.requestPaint();
    }
    onExplorationDataUpdated: {
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
            width: fogEffect.explorationDataColumns
            height: fogEffect.explorationDataRows
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
        property vector2d explorationResolution:
            Qt.vector2d(screenResolution.x / fogEffect.explorationDataColumns,
                        screenResolution.y / fogEffect.explorationDataRows)

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
            uniform highp vec2 explorationResolution;

            uniform mediump float timeOffset;

            varying highp vec2 qt_TexCoord0;

            float rand(vec2 co)
            {
                return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
            }

            vec2 getDynamicCloudCoord(vec2 pIn, vec2 offset, float speed)
            {
                return pIn + offset + vec2(timeOffset * speed, 0.0);
            }

            float getExplorationAlphaOfCloud(vec2 cloudAnchorCoord)
            {
                vec2 tile = cloudAnchorCoord * screenResolution / explorationResolution;
                vec2 tileIndex = floor(tile);
                vec2 frac = fract(tile);
                vec2 texSize = screenResolution / explorationResolution;
                vec2 uv0 = (tileIndex + vec2(0.5)) / texSize;
                vec2 uv1 = (tileIndex + vec2(1.5, 0.5)) / texSize;
                float a0 = texture2D(explorationTexture, uv0).a;
                float a1 = texture2D(explorationTexture, uv1).a;
                return mix(a0, a1, frac.x);
            }

            vec4 renderCloudLayer(vec2 p,
                                  vec2 offset,
                                  float speed,
                                  out float exploredAlpha)
            {
                // get cloud texture UV and color
                // To move the clouds we just offset the coordinate with time
                vec2 dynCloudCoord = getDynamicCloudCoord(p, offset, speed);
                vec2 uvCloudTex = fract(dynCloudCoord / cloudResolution);
                vec4 cloudColor = texture2D(cloudTexture, uvCloudTex);

                // get current cloud bb in screen space uv
                vec2 cloudTLCoord = (p - uvCloudTex * cloudResolution) / screenResolution;
                vec2 cloudBRCoord = (p + (vec2(1.0,1.0)-uvCloudTex) * cloudResolution) / screenResolution;
                vec2 cloudAnchorCoord = vec2(
                    (cloudTLCoord.x + cloudBRCoord.x) * 0.5,
                    //(cloudTLCoord.y + cloudBRCoord.y) * 0.5,
                    cloudBRCoord.y
                );

                // Get exploration alpha of a cloud anchored at cloudAnchorCoord. Interpolated
                // between neighbouring tiles.
                exploredAlpha = getExplorationAlphaOfCloud(cloudAnchorCoord);

                //float visibility = 1.0 - smoothstep(0.2, 0.8, exploredAlpha);
                float visibility = pow(1.0 - exploredAlpha, 3.0);
                cloudColor.a *= visibility;

                //return vec4(vec3(exploredAlpha), 1.0);
                return cloudColor;
            }

            void main()
            {
                // current point in screen space coordinates
                vec2 p = qt_TexCoord0 * screenResolution;
                float d = distance(p, vec2(playerX, playerY));
                float alpha = smoothstep(radius, radius + feather, d);

                // calculate cloud layers
                float explored0 = 1.0;
                float explored1 = 1.0;
                float explored2 = 1.0;

                vec4 cloud0 = renderCloudLayer(
                    p,
                    vec2(0.0, 0.0),
                    0.5,
                    explored0);
                vec4 cloud1 = renderCloudLayer(
                    p,
                    vec2(cloudResolution.x * 0.5, 37.0),
                    0.35,
                    explored1);
                vec4 cloud2 = renderCloudLayer(
                    p,
                    vec2(cloudResolution.x * 0.25, -18.0),
                    0.7,
                    explored2);

                vec4 clouds = cloud0;
                clouds.rgb = mix(clouds.rgb, cloud1.rgb, cloud1.a);
                clouds.a = 1.0 - (1.0 - clouds.a) * (1.0 - cloud1.a);
                clouds.rgb = mix(clouds.rgb, cloud2.rgb, cloud2.a);
                clouds.a = 1.0 - (1.0 - clouds.a) * (1.0 - cloud2.a);

                //Debug: paint the exploratioin map
                vec4 explorationData = texture2D(explorationTexture, qt_TexCoord0);
                float exploredAlphaDebug = step(0.5, explorationData.a * alpha);

                //float explored = explored0 * explored1 * explored2 * alpha;
                vec4 fog = vec4(/*exploredAlphaDebug*255.0*/0.0, 0.0, 0.0,
                                alpha * fogOpacity * qt_Opacity);
                gl_FragColor = mix(fog,
                                    mix(fog, clouds, clouds.a),
                                    alpha);
            }
        "
    }

    Component.onCompleted: {
        dataCanvas.requestPaint();
    }
}