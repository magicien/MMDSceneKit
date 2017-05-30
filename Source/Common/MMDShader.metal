//
//  MMDShader.metal
//  MMDSceneKit
//
//  Created by magicien on 12/27/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>


// Vertex
struct VertexInput {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
    float3 normal [[ attribute(SCNVertexSemanticNormal) ]];
    //float4 color [[ attribute(SCNVertexSemanticColor) ]];
    ushort4 boneIndices [[ attribute(SCNVertexSemanticBoneIndices) ]];
    float4 boneWeights [[ attribute(SCNVertexSemanticBoneWeights) ]];
    float2 texcoord [[ attribute(SCNVertexSemanticTexcoord0) ]];
};

// Model
struct NodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewProjectionTransform;
    float4x4 normalTransform;
    float4 skinningJointMatrices[765];
    float color[10000];
};

// Light
struct Light {
    //float3 ambient;
    //float4 diffuse;
    //float4 specular;
    //float modulate;
    
    //float4 positionVS_invSquareRadius;
    //float4 color_unscaledRadius;
    //float4 direction_tanConeAngle;
    //float2 spotAttenuation;
    //float4x4 invProjectionTransform;

    //float4  color;
    //float4  direction;
    //float4  position;
    //float4  attenuation;
    //float4  spotAttenuation;
    //float4x4    shadowMatrix;
    //float4  shadowRadius;
    //float4  shadowColor;
    //float4x4    goboMatrix;
    //float4  projectorColor;
    //float4  right;
    //float4  up;
    //float4x4    iesMatrix;
    float4 color0;
    float4 color1;
    float4 color2;
    float4 color3;
    float4 color4;
    float4 color5;
    float4 color6;
    float4 color7;
    float4 color8;
    float4 color9;
};

struct SCNShaderLight {
    float4 intensity;
    float3 direction;
    float _att;
    float3 _spotDirection;
    float _distance;
};

struct Uniforms {
    float4 diffuseColor;
    float4 specularColor;
    float4 ambientColor;
    float4 emissionColor;
    float4 reflectiveColor;
    float4 multiplyColor;
    float4 transparentColor;
    float metalness;
    float roughness;
    
    float diffuseIntensity;
    float specularIntensity;
    float normalIntensity;
    float ambientIntensity;
    float emissionIntensity;
    float reflectiveIntensity;
    float multiplyIntensity;
    float transparentIntensity;
    float metalnessIntensity;
    float roughnessIntensity;
    
    float materialShininess;
    float selfIlluminationOcclusion;
    float transparency;
    float3 fresnel; // x: ((n1-n2)/(n1+n2))^2 y:1-x z:exponent
 };




struct VertexOutput {
    float4 position [[ position ]];
    float2 texcoord;
    float3 normal;
    float3 eye;
    float2 sphereTexcoord;
    float4 color;
    float3 specular;
};



//vertex VertexOut textureVertex(VertexInput in [[ stage_in ]],
//                               constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
//                               constant NodeBuffer& scn_node [[ buffer(1) ]],
//                               constant CustomBuffer& custom [[ buffer(2) ]]) {
    
    
vertex VertexOutput mmdVertex(VertexInput in [[ stage_in ]],
                              constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
                              constant NodeBuffer& scn_node [[ buffer(1) ]],
                              constant Light& scn_lights [[ buffer(2) ]],
                              constant Uniforms& scn_commonprofile [[ buffer(3) ]],
                              texture2d<float> u_emissionTexture [[ texture(0) ]],
                              sampler u_emissionTextureSampler [[ sampler(0) ]],
                              texture2d<float> u_diffuseTexture [[ texture(2) ]],
                              sampler u_diffuseTextureSampler [[ sampler(2) ]],
                              texture2d<float> u_multiplyTexture [[ texture(6) ]],
                              sampler u_multiplyTextureSampler [[ sampler(6) ]]) {

    VertexOutput out;
    
    float3 pos = 0.0;
    float3 normal = 0.0;
    
    for(int i=0; i<4; i++){
        float weight = in.boneWeights[i];
        if(weight <= 0.0){
            continue;
        }
        int idx = in.boneIndices[i] * 3;
        float4x4 jointMatrix = float4x4(scn_node.skinningJointMatrices[idx],
                                        scn_node.skinningJointMatrices[idx+1],
                                        scn_node.skinningJointMatrices[idx+2],
                                        float4(0, 0, 0, 1));
        pos += (float4(in.position, 1.0) * jointMatrix).xyz * weight;
        //normal += in.normal * scn::mat3(jointMatrix) * weight;
    }
    out.eye = (scn_frame.viewTransform * float4(pos, 1.0)).xyz;
    out.position = scn_frame.viewProjectionTransform * float4(pos, 1.0);
    //out.eye = cameraPosition - pos;
    
    //out.color = scn_commonprofile.emissionColor;
    //out.color = u_emissionTexture.sample(u_emissionTextureSampler, float2(0.5, 0.5));
    
    //if( !useToon ) {
    //    out.color.rgb += max(0, dot(normal, -scn_lights.direction)) * scn_commonprofile.diffuseColor;
    //}
    //out.color.a = scn_commonprofile.u_diffuseColor.a;
    //out.color = saturate(out.color);
    
    //out.color = float4(0.2, 0.2, 0.2, 1.0);
    //out.color = scn_commonprofile.emissionColor;
    //out.color = u_emissionTexture.sample(u_emissionTextureSampler, in.texcoord);
    out.color = u_diffuseTexture.sample(u_diffuseTextureSampler, in.texcoord);
    //out.color = scn_commonprofile.diffuseColor;
    out.texcoord = in.texcoord;
    
    //float r = scn_node.color[0] + scn_node.color[1] + scn_node.color[2];
    //float g = scn_node.color[9] + scn_node.color[10] + scn_node.color[11];
    //float b = scn_node.color[18] + scn_node.color[19] + scn_node.color[20];
    //float r = scn_node.color[9997];
    //float g = scn_node.color[9998];
    //float b = scn_node.color[9999];
    //float r = scn_node.color[12];
    //float g = scn_node.color[13];
    //float b = scn_node.color[14];
    
    //float4 color = float4(r, g, b, 1.0);
    //out.color = scn_commonprofile.diffuseColor;
    //out.color = in.color;
    //out.color = float4(0.3, 0.3, 0.3, 1.0);
    //out.color = scn_commonprofile.ambientColor;
    
    //float3 halfVector = normalize(normalize(out.eye) - lightDirection);
    //out.specular = pow(max(0, dot(halfVector, out.normal)), scn_commonprofile.materialShininess) * scn_commonprofile.specularColor;
                                  
                                  
    //out.color = u_multiplyTexture.sample(u_multiplyTextureSampler, in.texcoord);
    out.specular = float3(0);
    
    //out.color = scn_lights.color1;
    //out.color = float4(0.0, 0.0, 1.0, 1.0);
    return out;
}

//fragment half4 mmdFragment(VertexOutput in [[ stage_in ]]){
fragment half4 mmdFragment(VertexOutput in [[ stage_in ]],
                           texture2d<float> u_emissionTexture [[ texture(0) ]],
                           sampler u_emissionTextureSampler [[ sampler(0) ]],
                           texture2d<float> u_diffuseTexture [[ texture(2) ]],
                           sampler u_diffuseTextureSampler [[ sampler(2) ]],
                           texture2d<float> u_multiplyTexture [[ texture(6) ]],
                           sampler u_multiplyTextureSampler [[ sampler(6) ]]) {
    float4 color = in.color;
    //if(useTexture){
    color *= u_multiplyTexture.sample(u_multiplyTextureSampler, in.texcoord);
    //}
    
    //color = u_emissionTexture.sample(u_emissionTextureSampler, in.texcoord);
    //color = u_diffuseTexture.sample(u_diffuseTextureSampler, in.texcoord);

    //if(useSphereMap){
    //
    //}
    
    //if(useToon){
    //
    //}
    
    //color.rgb += in.specular;
    
    return half4(color);
}

/*
vertex VertexOutput pass_edge_vertex(VertexInput in [[stage_in]],
//                                     constant NodeBuffer& scn_node [[ buffer(0) ]]){
                                     constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
                                     constant NodeBuffer& scn_node [[ buffer(1) ]])
//                                     constant float& screenSize [[ buffer(2) ]])
{
    VertexOutput out;
    
    float3 pos = 0.0;
    float3 posMove = 0.0;
    float3 normal = 0.0;
    
    for(int i=0; i<4; i++){
        float weight = in.boneWeights[i];
        if(weight <= 0.0){
            continue;
        }
        int idx = in.boneIndices[i] * 3;
        float4x4 jointMatrix = float4x4(scn_node.skinningJointMatrices[idx],
                                        scn_node.skinningJointMatrices[idx+1],
                                        scn_node.skinningJointMatrices[idx+2],
                                        float4(0, 0, 0, 1));
        pos += (float4(in.position, 1.0) * jointMatrix).xyz * weight;
        
        float3x3 normalMat = float3x3(jointMatrix[0].xyz, jointMatrix[1].xyz, jointMatrix[2].xyz);
        normal += (in.normal * normalMat) * weight;
    }
    //pos = normalize(pos) * posSize + posMove;
    
    out.eye = (scn_frame.viewTransform * float4(pos, 1.0)).xyz;
    //out.position = scn_frame.viewProjectionTransform * float4(pos, 1.0);
    
    float4 in_pos0 = float4(pos, 1.0);
    float4 in_pos1 = float4(pos + normal, 1.0);
    
    float edgeSize = 0.8;
    float screenSize = 400; // debug
    
    float4 pos0 = scn_frame.viewProjectionTransform * in_pos0;
    float4 pos1 = scn_frame.viewProjectionTransform * in_pos1;
    
    pos0.xy /= pos0.w;
    pos1.xy /= pos1.w;
    
    float d = distance(pos0.xy, pos1.xy);
    float coeff = screenSize * d;
    if(coeff > edgeSize){
        coeff = edgeSize / coeff;
    }

    out.position = scn_frame.viewProjectionTransform * float4(pos + normal * coeff, 1.0);
    
    return out;
};


fragment half4 pass_edge_fragment(VertexOutput in [[stage_in]])
//                                          texture2d<float, access::sample> colorSampler [[texture(0)]])
{
    float4 color = float4(0.0, 0.0, 0.0, 1.0);
    
    return half4(color);
};

*/
