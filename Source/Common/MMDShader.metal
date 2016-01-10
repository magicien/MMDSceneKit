//
//  MMDShader.metal
//  MMDSceneKit
//
//  Created by magicien on 12/27/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

/*
#include <metal_stdlib>
#include <simd/simd.h>
#include <metal_texture>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_graphics>

using namespace metal;
#include <SceneKit/scn_metal>


struct VertexInput {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float3 normal   [[attribute(SCNVertexSemanticNormal)]];
    float2 texcoord [[attribute(SCNVertexSemanticTexcoord0)]];
    float2 texcoord2 [[attribute(SCNVertexSemanticTexcoord1)]];
};

struct VertexOutput {
    float4 position [[position]];
    float3 eye;
    float3 normal;
    float4 color;
    float4 specular;
    float2 texcoord;
    float2 spTexcoord;
};

struct MyNodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewProjectionTransform;
};

struct MaterialUniform {
    float3 cameraPosition;
    float4 ambientColor;
    float4 diffuseColor;
    float4 specularColor;
//    float4 lightAmbientColor;
//    float4 lightDiffuseColor;
//    float4 lightSpecularColor;
    float sepcularPower;
    bool useTexture;
    bool useToon;
    bool useSphereMap;
    bool useSubTexture;
    bool spadd;
    float3 lightDirection;
};

vertex VertexOutput mmdVertex(VertexInput vIn [[ stage_in ]],
                              constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                              constant MyNodeBuffer& scn_node [[buffer(1)]],
                              constant MaterialUniform& m [[buffer(2)]]) {
    VertexOutput vOut;
    
    float4 inPosition = float4(vIn.position, 1.0);
    float4 inNormal = float4(vIn.normal, 1.0);
    
    vOut.position = scn_node.modelViewProjectionTransform * inPosition;
    vOut.eye = m.cameraPosition - float3(scn_node.modelTransform * inPosition);
    vOut.normal  = normalize( float3x3(scn_node.modelTransform) * vIn.normal );
    vOut.color.rgb = m.ambientColor.rgb;
    
    if(!m.useToon){
        vOut.color.rgb += max(0, dot(vOut.normal, -m.lightDirection)) * m.diffuseColor.rgb;
    }
    vOut.color.a = m.diffuseColor.a;
    vOut.color = saturate(vOut.color);
    vOut.texcoord = vIn.texcoord;
    
    if (m.useSphereMap) {
        if (m.useSubTexture) {
            vOut.spTexcoord = vIn.texcoord2;
        } else {
            float2 normalWV = float2(float3x3(scn_node.modelTransform) * vOut.normal);
            vOut.spTexcoord.x = normalWV.x * 0.5 + 0.5;
            vOut.spTexcoord.y = -normalWV.y * 0.5 + 0.5;
        }
    }
    
    float3 halfVector = normalize( normalize(vOut.eye) - m.lightDirection );
    vOut.specular = pow( max(0, dot(halfVector, vOut.normal)), m.specularPower) * m.specularColor;

    return vOut;
}

fragment half4 mmdFragment(VertexOutput fIn [[ stage_in ]],
                           texture2d<float> diffuseTexture [[ texture(0) ]],
                           texture2d<float> sphereTexture [[ texture(1) ]],
                           texture2d<float> toonTexture [[ texture(2) ]],
                           constant MaterialUniform& m [[buffer(2)]]) {
    constexpr sampler defaultSampler;
    float4 color = fIn.color;
        
    if (m.useTexture) {
        color *= diffuseTexture.sample(defaultSampler, fIn.texcoord);
    }
    if (m.useSphereMap) {
        float4 texColor = sphereTexture.sample(defaultSampler, fIn.spTexcoord);
        if (m.spadd) {
            color.rgb += texColor.rgb;
        } else {
            color.rgb *= texColor.rgb;
        }
        color.a *= texColor.a;
    }
    if (m.useToon) {
        float lightNormal = dot(fIn.normal, -m.lightDirection);
        color *= toonTexture.sample(defaultSampler, float2(0, 0.5 - lightNormal * 0.5));
    }
    color.rgb += fIn.specular;
    
    return half4(color);
}
*/
