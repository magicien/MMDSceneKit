/**
 * MMD Vertex Shader
 * translate from  full.fx ver2.0
 */
precision mediump float;

attribute vec4 aPos;
attribute vec3 aNormal;
attribute vec2 aTex;
attribute vec2 aTex2;

uniform mat4 modelTransform;
uniform mat4 viewTransform;
uniform mat4 projectionTransform;
uniform mat4 normalTransform;
uniform mat4 modelViewTransform;
uniform mat4 modelViewProjectionTransform;



//uniform mat4 worldViewProjMatrix;
//uniform mat4 worldMatrix;
//uniform mat4 viewMatrix;
uniform mat4 lightWorldViewProjMatrix;

uniform vec3 lightDirection;
uniform vec3 cameraPosition;

uniform vec4 materialDiffuse;
uniform vec3 materialAmbient;
uniform vec3 materialEmissive;
uniform vec3 materialSpecular;
uniform float specularPower;
uniform vec3 materialToon;
uniform vec4 edgeColor;
uniform vec4 groundShadowColor;

uniform vec3 lightDiffuse;
uniform vec3 lightAmbient;
uniform vec3 lightSpecular;

//static float4 DiffuseColor  = MaterialDiffuse  * float4(LightDiffuse, 1.0f);
//static float3 AmbientColor  = MaterialAmbient  * LightAmbient + MaterialEmmisive;
//static float3 SpecularColor = MaterialSpecular * LightSpecular;

uniform vec4 textureAddValue;
uniform vec4 textureMulValue;
uniform vec4 sphereAddValue;
uniform vec4 sphereMulValue;

uniform bool useTexture;
uniform bool useSphereMap;
uniform bool useToon;
uniform bool useSubTexture;
uniform bool usePerspective;
uniform bool isTransparent;
uniform bool addSphere;

#define SKII1 1500
#define SKII2 8000
#define Toon  3


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
varying vec3 vEye;
varying vec2 vSpTex;
varying vec4 vColor;

vec2 normalWV;

void main()
{
    /*
    vOut.pos = aPos * worldViewProjMatrix;
    vOut.eye = cameraPosition - aPos * worldMatrix;
    vOut.normal = normalize(aNormal * mat3(worldMatrix));
    vOut.zCalcTex = aPos * lightWorldViewProjMatrix;
    vOut.color.rgb = AmbientColor;
    if (useToon) {
        vOut.color.rgb += max(0, dot(vOut.normal, -lightDirection)) * DiffuseColor.rgb;
    }
    vOut.color.a = DiffuseColor.a;
    vOut.color = clamp(vOut.color, 0.0, 1.0);
    
    vOut.tex = aTex;
    if (useSphereMap) {
        if (useSubTexture) {
            vOut.spTex = aTex2
        } else {
            float2 normalWV = vOut.normal * mat3(viewMatrix);
            vOut.spTex.x = normalWV.x * 0.5f + 0.5f;
            vOut.spTex.y = -normalWV.y * 0.5f + 0.5f;
        }
    }
    */
    vNormal = normalize(mat3(modelTransform) * aNormal);
    vTex = aTex;

    /*
    vColor.rgb = AmbientColor;
    if (useToon) {
        vColor.rgb += max(0, dot(vNormal, -lightDirection)) * DiffuseColor.rgb;
    }
    vColor.a = DiffuseColor.a;
    vColor = clamp(vColor, 0.0, 1.0);
    */
    
    vTex = aTex;
    if (useSphereMap) {
        if (useSubTexture) {
            vSpTex = aTex2;
        } else {
            //vec2 normalWV = vNormal * mat3(viewMatrix);
            normalWV = vec2(mat3(viewTransform) * vNormal);
            vSpTex.x = normalWV.x * 0.5 + 0.5;
            vSpTex.y = -normalWV.y * 0.5 + 0.5;
        }
    }

    gl_Position = modelViewProjectionTransform * aPos;
}
