import QtQuick 2.14

ShaderEffect {
    id: root

    property real playerX: 0
    property real playerY: 0
    property real radius: 200
    property real feather: 100
    property real fogOpacity: 0.7

    anchors.fill: parent

    fragmentShader: "
        precision mediump float;

        uniform highp float playerX;
        uniform highp float playerY;
        uniform highp float radius;
        uniform highp float feather;
        uniform lowp float fogOpacity;

        uniform highp float qt_Opacity;
        varying highp vec2 qt_TexCoord0;

        uniform highp vec2 resolution;

        void main()
        {
            vec2 p = qt_TexCoord0 * resolution;

            float d = distance(p, vec2(playerX, playerY));

            float alpha = smoothstep(radius, radius + feather, d);

            gl_FragColor = vec4(0.0, 0.0, 0.0,
                                alpha * fogOpacity * qt_Opacity);
        }
    "

    property vector2d resolution: Qt.vector2d(width, height)
}