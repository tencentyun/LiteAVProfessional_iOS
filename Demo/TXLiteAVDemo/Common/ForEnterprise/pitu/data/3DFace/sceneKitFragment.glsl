
precision highp float;
uniform sampler2D yourTexture;
varying vec2 texCoord;

void main(void) {
    vec4 color = texture2D(yourTexture, vec2(texCoord.x, 1.0 - texCoord.y));
    //gl_FragColor = vec4(color.b, color.g, color.r, color.a);
    gl_FragColor = vec4(1.0, 0.0, 0.0, 0.2);
}
