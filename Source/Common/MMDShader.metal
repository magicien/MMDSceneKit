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
//    float2 texcoord2 [[attribute(SCNVertexSemanticTexcoord1)]];
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
    float specularPower;
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
    
    float3x3 transRot = float3x3(scn_node.modelTransform[0].xyz, scn_node.modelTransform[1].xyz, scn_node.modelTransform[2].xyz);
    vOut.normal  = normalize( transRot * vIn.normal );
    vOut.color.rgb = m.ambientColor.rgb;
    
    if(!m.useToon){
        vOut.color.rgb += fmax(0.0, dot(vOut.normal, -m.lightDirection)) * m.diffuseColor.rgb;
    }
    vOut.color.a = m.diffuseColor.a;
    vOut.color = saturate(vOut.color);
    vOut.texcoord = vIn.texcoord;
    
    if (m.useSphereMap) {
        if (m.useSubTexture) {
            //vOut.spTexcoord = vIn.texcoord2;
        } else {
            float2 normalWV = (transRot * vOut.normal).xy;
            vOut.spTexcoord.x = normalWV.x * 0.5 + 0.5;
            vOut.spTexcoord.y = -normalWV.y * 0.5 + 0.5;
        }
    }
    
    float3 halfVector = normalize( normalize(vOut.eye) - m.lightDirection );
    vOut.specular = pow( fmax(0.0, dot(halfVector, vOut.normal)), m.specularPower) * m.specularColor;

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
    color.rgb += fIn.specular.rgb;
    
    return half4(color);
}
*/

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>


// 頂点属性
struct VertexInput {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
//    float3 normal [[ attribute(SCNVertexSemanticNormal) ]];
//    float4 color [[ attribute(SCNVertexSemanticColor) ]];
    ushort2 boneIndices [[ attribute(SCNVertexSemanticBoneIndices) ]];
    float2 boneWeights [[ attribute(SCNVertexSemanticBoneWeights) ]];
    
    float2 texcoord [[ attribute(SCNVertexSemanticTexcoord0) ]];
};

// モデルデータ
struct NodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewProjectionTransform;
//    float4x4 position_transforms[4];
};

// 変数
/*
struct CustomBuffer {
    float4 color;
};
 */

struct VertexOutput {
    float4 position [[ position ]];
    float2 texcoord;
//    float4 color;
};

struct CustomBuffer {
    float screenSize;
};


//vertex VertexOut textureVertex(VertexInput in [[ stage_in ]],
//                               constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
//                               constant NodeBuffer& scn_node [[ buffer(1) ]],
//                               constant CustomBuffer& custom [[ buffer(2) ]]) {

vertex VertexOutput mmdVertex(VertexInput in [[ stage_in ]],
                           uint iid [[ instance_id ]],
                           uint baseId [[ base_instance ]],
                               constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
                               constant NodeBuffer* scn_node [[ buffer(1) ]]) {
    VertexOutput out;
    float4x4 mat = float4x4(0);
    mat += scn_node[in.boneIndices[0] + baseId].modelTransform * in.boneWeights[0];
    mat += scn_node[in.boneIndices[1] + baseId].modelTransform * in.boneWeights[1];
    
    //out.position = scn_node[iid].modelViewProjectionTransform * mat * float4(in.position, 1.0);
    out.position = scn_frame.viewProjectionTransform * mat * float4(in.position, 1.0);
    out.texcoord = in.texcoord;
    return out;
}

fragment half4 mmdFragment(VertexOutput in [[ stage_in ]],
                               texture2d<float> texture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    float4 color;
//    color = texture.sample(defaultSampler, in.texcoord) + in.color;
    color = texture.sample(defaultSampler, in.texcoord);
//    color = in.position.z;
    return half4(color);
}


vertex VertexOutput pass_edge_vertex(VertexInput in [[stage_in]],
                                     constant NodeBuffer& scn_node [[ buffer(0) ]])
//                                     constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
//                                     constant NodeBuffer& scn_node [[ buffer(1) ]])
//                                     constant float& screenSize [[ buffer(2) ]])
{
    VertexOutput out;
    /*
    float4 in_pos0 = float4(in.position, 1.0);
    float4 in_pos1 = float4(in.position + in.normal, 1.0);
    
    float edgeSize = 1.0;
    float screenSize = 200; // debug
    
    float4 pos0 = scn_node.modelViewProjectionTransform * in_pos0;
    float4 pos1 = scn_node.modelViewProjectionTransform * in_pos1;
    
    pos0.xy /= pos0.w;
    pos1.xy /= pos1.w;
    
    float d = distance(pos0.xy, pos1.xy);
    float coeff = screenSize * d;
    if(coeff > edgeSize){
        coeff = edgeSize / coeff;
    }
    */
    
    //out.position = scn_node.modelViewProjectionTransform * float4(in.position + in.normal * coeff, 1.0);
    //out.position = float4(in.position, 1.0) * scn_node.modelViewProjectionTransform;
    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    //out.position = float4(in.position, 1.0);
    
    return out;
};


fragment half4 pass_edge_fragment(VertexOutput in [[stage_in]])
//                                          texture2d<float, access::sample> colorSampler [[texture(0)]])
{
    float4 color = float4(0.0, 0.0, 1.0, 1.0);
    
    return half4(color);
};

