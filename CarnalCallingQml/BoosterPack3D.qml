import QtQuick 2.14
import QtQuick.Controls 2.14
import QtGraphicalEffects 1.14
import JOIP.core 1.5
import JoipEngine 1.3

Rectangle {
    id: previewDelegate
    x: 0
    y: 0
    width: StyleParams.deckCollectionWidthMin
    height: StyleParams.deckCollectionHeightMin
    color: "transparent"

    property int currentlyLoadedProject: -1
    property string packImage: ""

    // Kept with the same names so existing code that controls this
    // delegate does not need to change.
    property real cardRotationX: 0
    property real cardRotationY: 0
    property real cardRotationZ: 0

    // geometry options// Geometry options
    property real depth: 0.012
    property real sideTaper: 0.004

    // Width of the top and bottom sealed bands (UV coordinates)
    property real seamWidth: 0.085
    // Width of the left and right sealed bands
    property real sideSeamWidth: 0.035
    // Strength of the foil crimp pattern
    property real crimpStrength: 0.8

    property real seamFoilStrength: 0.35

    property vector3d foilColor: Qt.vector3d(0.68, 0.70, 0.74)

    Image {
        id: packFront
        anchors.fill: parent
        visible: false

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source: previewDelegate.packImage;
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: packBack
        anchors.fill: parent
        visible: false

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source: previewDelegate.packImage;
        fillMode: Image.PreserveAspectFit
    }

    ShaderEffectSource {
        id: cardTextureFront
        sourceItem: packFront
        width: previewDelegate.width
        height: previewDelegate.height
        live: true
        hideSource: false
        smooth: true
        visible: false
    }

    ShaderEffectSource {
        id: cardTextureBack
        sourceItem: packBack
        width: previewDelegate.width
        height: previewDelegate.height
        live: true
        hideSource: true
        smooth: true
        visible: false
    }

    ShaderEffect {
        id: boosterEffect

        anchors.fill: parent

        // Existing texture sources
        property variant frontTexture: cardTextureFront
        property variant backTexture: cardTextureBack

        // Existing rotation properties (degrees)
        property real uRotationX: previewDelegate.cardRotationX
        property real uRotationY: previewDelegate.cardRotationY
        property real uRotationZ: previewDelegate.cardRotationZ

        property real uAspectRatio: width / Math.max(1, height)

        // Very slim card-stack thickness
        property real uDepth: previewDelegate.depth
        property real uSideTaper: previewDelegate.sideTaper

        // Existing foil seam properties
        property real uSeamWidth: previewDelegate.seamWidth
        property real uSideSeamWidth: previewDelegate.sideSeamWidth
        property real uCrimpStrength: previewDelegate.crimpStrength
        property real seamFoilStrength: previewDelegate.seamFoilStrength

        property vector3d foilColor: previewDelegate.foilColor

        vertexShader: "
            #ifdef GL_ES
            precision highp float;
            #endif

            attribute highp vec4 qt_Vertex;
            attribute highp vec2 qt_MultiTexCoord0;

            uniform highp mat4 qt_Matrix;

            varying highp vec2 qt_TexCoord0;

            void main()
            {
                qt_TexCoord0 = qt_MultiTexCoord0;
                gl_Position = qt_Matrix * qt_Vertex;
            }
        "

        fragmentShader: "
            #ifdef GL_ES
            precision highp float;
            #endif

            varying highp vec2 qt_TexCoord0;

            uniform sampler2D frontTexture;
            uniform sampler2D backTexture;

            uniform highp float uRotationX;
            uniform highp float uRotationY;
            uniform highp float uRotationZ;
            uniform highp float uAspectRatio;

            uniform highp float uDepth;
            uniform highp float uSideTaper;

            uniform highp float uSeamWidth;
            uniform highp float uSideSeamWidth;
            uniform highp float uCrimpStrength;
            uniform highp float seamFoilStrength;

            uniform highp vec3 foilColor;

            uniform lowp float qt_Opacity;

            const float MAX_DISTANCE = 5.0;
            const int MAX_STEPS = 72;

            vec3 rotateX(vec3 p, float a)
            {
                float c = cos(a);
                float s = sin(a);

                return vec3(
                    p.x,
                    c * p.y - s * p.z,
                    s * p.y + c * p.z
                );
            }

            vec3 rotateY(vec3 p, float a)
            {
                float c = cos(a);
                float s = sin(a);

                return vec3(
                    c * p.x + s * p.z,
                    p.y,
                    -s * p.x + c * p.z
                );
            }

            vec3 rotateZ(vec3 p, float a)
            {
                float c = cos(a);
                float s = sin(a);

                return vec3(
                    c * p.x - s * p.y,
                    s * p.x + c * p.y,
                    p.z
                );
            }

            // Thickness profile:
            // - Flat, full-thickness centre.
            // - Straight taper at the top and bottom.
            // - Almost zero-width taper at the left and right.
            // This creates a card-stack shape rather than a rounded box.
            float thicknessAt(vec2 p, vec3 halfSize)
            {
                float edgeX = halfSize.x - abs(p.x);
                float edgeY = halfSize.y - abs(p.y);

                float taperX = max(
                    uSideTaper * 2.0 * halfSize.x,
                    0.0005
                );

                float taperY = max(
                    uSeamWidth * 2.0 * halfSize.y,
                    0.0005
                );

                float profileX = clamp(edgeX / taperX, 0.0, 1.0);
                float profileY = clamp(edgeY / taperY, 0.0, 1.0);

                // The minimum makes the thickness reach zero at every edge.
                float profile = min(profileX, profileY);

                return uDepth * profile;
            }

            float sceneDistance(vec3 p, vec3 halfSize)
            {
                float outsideX = abs(p.x) - halfSize.x;
                float outsideY = abs(p.y) - halfSize.y;

                float outsideXY = max(outsideX, outsideY);

                float localThickness = thicknessAt(p.xy, halfSize);
                float frontBack = abs(p.z) - localThickness;

                return max(outsideXY, frontBack);
            }

            vec3 calculateNormal(vec3 p, vec3 halfSize)
            {
                float e = 0.0015;

                return normalize(vec3(
                    sceneDistance(
                        p + vec3(e, 0.0, 0.0),
                        halfSize
                    ) -
                    sceneDistance(
                        p - vec3(e, 0.0, 0.0),
                        halfSize
                    ),

                    sceneDistance(
                        p + vec3(0.0, e, 0.0),
                        halfSize
                    ) -
                    sceneDistance(
                        p - vec3(0.0, e, 0.0),
                        halfSize
                    ),

                    sceneDistance(
                        p + vec3(0.0, 0.0, e),
                        halfSize
                    ) -
                    sceneDistance(
                        p - vec3(0.0, 0.0, e),
                        halfSize
                    )
                ));
            }

            void main()
            {
                vec2 screen = qt_TexCoord0 * 2.0 - 1.0;

                screen.x *= uAspectRatio;
                screen.y = -screen.y;

                vec3 rayOriginWorld = vec3(0.0, 0.0, 2.8);

                vec3 rayDirectionWorld = normalize(
                    vec3(screen.x, screen.y, -2.8)
                );

                float rx = radians(uRotationX);
                float ry = radians(uRotationY);
                float rz = radians(uRotationZ);

                // Transform ray into object space.
                vec3 rayOrigin = rotateX(
                    rotateY(
                        rotateZ(rayOriginWorld, -rz),
                        -ry
                    ),
                    -rx
                );

                vec3 rayDirection = rotateX(
                    rotateY(
                        rotateZ(rayDirectionWorld, -rz),
                        -ry
                    ),
                    -rx
                );

                vec3 halfSize = vec3(
                    0.92 * uAspectRatio,
                    0.92,
                    uDepth
                );

                // Ray marching
                float t = 0.0;
                bool hit = false;

                for (int i = 0; i < MAX_STEPS; ++i)
                {
                    vec3 p = rayOrigin + rayDirection * t;

                    float d = sceneDistance(p, halfSize);

                    if (d < 0.001)
                    {
                        hit = true;
                        break;
                    }

                    t += max(d, 0.0005);

                    if (t > MAX_DISTANCE)
                        break;
                }

                if (!hit)
                {
                    gl_FragColor = vec4(0.0);
                    return;
                }

                vec3 hitPosition =
                    rayOrigin + rayDirection * t;

                vec3 normalObject =
                    calculateNormal(hitPosition, halfSize);

                vec3 normalWorld = rotateZ(
                    rotateY(
                        rotateX(normalObject, rx),
                        ry
                    ),
                    rz
                );

                vec3 viewDirection =
                    normalize(-rayDirectionWorld);

                // Foil appearance
                vec3 foil = foilColor;

                float foilVariation =
                    0.96 + 0.035 * sin(
                        hitPosition.x * 90.0 +
                        hitPosition.y * 65.0
                    );

                foil *= foilVariation;

                // Artwork UV
                vec2 uv = vec2(
                    hitPosition.x / (2.0 * halfSize.x) + 0.5,
                    0.5 - hitPosition.y / (2.0 * halfSize.y)
                );

                uv = clamp(uv, 0.0, 1.0);

                float frontFace = smoothstep(
                    0.35,
                    0.85,
                    abs(normalObject.z)
                );

                vec3 artwork;

                if (normalObject.z > 0.0)
                {
                    artwork = texture2D(
                        frontTexture,
                        uv
                    ).rgb;
                }
                else
                {
                    artwork = texture2D(
                        backTexture,
                        vec2(1.0 - uv.x, uv.y)
                    ).rgb;
                }

                vec3 surfaceColor = mix(
                    foil,
                    artwork,
                    frontFace
                );

                // Top and bottom crimped seals.
                float verticalEdgeDistance = min(
                    uv.y,
                    1.0 - uv.y
                );

                float seam = 1.0 - smoothstep(
                    uSeamWidth * 0.72,
                    uSeamWidth,
                    verticalEdgeDistance
                );

                float ridges = 0.5 + 0.5 * sin(uv.x * 420.0);

                // Blend the artwork color with the foil.
                vec3 crimpBase = mix(artwork, foil, seamFoilStrength);

                // Add the metallic crimp ridges.
                float crimpShade = 0.76 + 0.36 * ridges;

                vec3 crimpColor = crimpBase * crimpShade;

                surfaceColor = mix(
                    surfaceColor,
                    crimpColor,
                    seam * uCrimpStrength * frontFace
                );

                float seamBoundary = 1.0 - smoothstep(
                    0.002,
                    0.006,
                    abs(
                        verticalEdgeDistance -
                        uSeamWidth * 0.88
                    )
                );

                surfaceColor *= 1.0 -
                    seamBoundary *
                    0.20 *
                    uCrimpStrength *
                    frontFace;

                // Crimping along the actual top/bottom edges.
                float topBottomFace = smoothstep(
                    0.40,
                    0.80,
                    abs(normalObject.y)
                );

                // Artwork-tinted foil on the sloped top and bottom edges.
                float edgeRidges = 0.5 + 0.5 * sin(
                    (hitPosition.x / halfSize.x) * 210.0
                );

                vec3 topBottomBase = mix(
                    artwork,
                    foil,
                    seamFoilStrength
                );

                vec3 topBottomFoil = topBottomBase * (
                    0.76 + 0.36 * edgeRidges
                );

                surfaceColor = mix(
                    surfaceColor,
                    topBottomFoil,
                    topBottomFace * uCrimpStrength
                );

                // Lighting
                vec3 lightDirection = normalize(
                    vec3(-0.35, 0.55, 0.75)
                );

                float diffuse = max(
                    dot(normalWorld, lightDirection),
                    0.0
                );

                float lighting = 0.48 + diffuse * 0.52;

                float rim = pow(
                    1.0 - max(
                        dot(normalWorld, viewDirection),
                        0.0
                    ),
                    2.0
                );

                surfaceColor *= lighting;
                surfaceColor += vec3(0.10) * rim;

                gl_FragColor = vec4(
                    surfaceColor,
                    qt_Opacity
                );
            }
        "
    }
}
