inline float3 linearToSrgb(float3 c) {
    return pow(c, float3(1.0/2.2));
}

inline float4 linearToSrgb(float4 c) {
    return pow(c, float4(1.0/2.2));
}

inline float3 srgbToLinear(float3 c) {
    return pow(c, float3(2.2));
}

inline float4 srgbToLinear(float4 c) {
    return pow(c, float4(2.2));
}

#pragma transparent
#pragma arguments

float useTexture;
float useToon;
float useSphereMap;
float useSubtexture;

float spadd;

#pragma body

/*
float4 materialDiffuse = linearToSrgb(_surface.diffuse);
float4 materialSpecular = linearToSrgb(_surface.specular);
float4 materialEmission = linearToSrgb(_surface.emission);
float3 lightAmbient = linearToSrgb(_lightingContribution.ambient);
float3 lightDiffuse = linearToSrgb(_lightingContribution.diffuse);
float3 lightSpecular = linearToSrgb(_lightingContribution.specular);
*/
float4 materialDiffuse = _surface.diffuse;
float4 materialSpecular = _surface.specular;
float4 materialEmission = _surface.emission;
float3 lightAmbient = saturate(_lightingContribution.ambient);
float3 lightDiffuse = saturate(_lightingContribution.diffuse);
float3 lightSpecular = saturate(_lightingContribution.specular);

// workaround for a doubleSided bug
#ifdef USE_DOUBLE_SIDED
    if(_surface.normal.z < 0){
        _surface.normal *= -1.0;
    }
#endif

/*
#ifdef USE_PER_PIXEL_LIGHTING
    float3 lightDirection = -scn_lights.direction0.xyz;
#else
    float3 lightDirection = float3(0, 1, 0);
#endif
*/
float3 lightDirection = float3(0, 1, 0);

// light direction in view space
float3 lightDir = normalize((scn_frame.viewTransform * float4(lightDirection, 0)).xyz);
//float4 diffuseColor = materialDiffuse * float4(lightDiffuse, 1.0);
float4 diffuseColor = float4(0, 0, 0, 1);
// This is not typo; use materialDiffuse for ambientColor.
float3 ambientColor = materialDiffuse.rgb * lightDiffuse.rgb + materialEmission.rgb;
float3 specularColor = materialSpecular.rgb * lightSpecular.rgb;

float3 n = normalize(_surface.normal);

#define SKII1 1500
#define SKII2 8000
#define Toon  3

_output.color.rgb = ambientColor.rgb;
if(useToon <= 0){
    _output.color.rgb += diffuseColor.rgb;
}
_output.color.a = diffuseColor.a;
_output.color = saturate(_output.color);

float2 spTex;
if(useSphereMap > 0){
    if(useSubtexture > 0){
        spTex = _surface.specularTexcoord;
    }else{
        spTex.x = n.x * 0.5 + 0.5;
        spTex.y = -n.y * 0.5 + 0.5;
    }
}







float3 halfVector = normalize(normalize(_surface.view) - normalize(lightDir));
float3 specular = pow(max(0.0, dot(halfVector, n)), _surface.shininess) * specularColor;

//float4 lightScreen = scn_lights.shadowMatrix0 * float4(_surface.position, 1);
//float shadow = 1.0 - shadow2DProj(u_shadowTexture0, lightScreen);

if(useTexture > 0){
    _output.color *= u_multiplyTexture.sample(u_multiplyTextureSampler, _surface.multiplyTexcoord);
}

if(useSphereMap > 0){
    float4 texColor = u_reflectiveTexture.sample(u_reflectiveTextureSampler, spTex);
    if(spadd){
        _output.color.rgb += texColor.rgb;
    }else{
        _output.color.rgb *= texColor.rgb;
    }
    _output.color.a *= texColor.a;
}

if(useToon > 0){
    float lightNormal = dot(n, -lightDir);
    _output.color *= u_transparentTexture.sample(u_transparentTextureSampler, float2(0, 0.5 + lightNormal * 0.5));
}
//_output.color.rgb += specularColor.rgb;
//_output.color.rgb += specular;

// needs to multiply the alpha value when it uses "#pragma transparent"
_output.color.rgb *= _output.color.a;

//_output.color = srgbToLinear(_output.color);

//_output.color = float4(shadow, shadow, shadow, 1.0);
