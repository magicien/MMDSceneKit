/**
 * MMD Fragment Shader
 * translate from  full.fx ver2.0
 */
precision mediump float;

/*
struct BufferShadow_OUTPUT {
    vec4 pos;
    vec4 zCalcTex;
    vec2 tex;
    vec3 normal;
    vec3 eye;
    vec2 spTex;
    vec4 color;
};

varying BufferShadow_OUTPUT vOut;
*/
varying vec4 vPos;
varying vec4 vZCalcTex;
varying vec2 vTex;
varying vec3 vNormal;
varying vec2 vSpTex;
varying vec4 vColor;


/*
void hoge(in vec4 V, in vec4 N)
{
    
}
*/

void main()
{
    //float3 halfVector = normalize(normalize(vIn.eye) - lightDirection)
    //gl_Color = vOut.color
    gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0);
}
