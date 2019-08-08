attribute vec4 position;
attribute vec2 textureCoordinate;
uniform mat4 modelViewProjection;

varying vec2 texCoord;

void main(void) {
    // Pass along to the fragment shader
    texCoord = textureCoordinate;
    
    // output the projected position
    gl_Position = modelViewProjection * position;
}
