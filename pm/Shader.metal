//
//  Shader.metal
//  pm
//
//  Created by wanghuai on 2017/6/19.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexInput {
    float3 position [[attribute(0)]];
    float2 texcoord0 [[attribute(1)]];
};

struct ShaderInOut {
    float4 position [[position]];
    float2 texcoord0;
};


vertex ShaderInOut basic_vertex(
                                VertexInput in [[stage_in]],
                                constant float4x4& projMat [[buffer(1)]],
                                constant float4x4& mvMat [[buffer(2)]],
                                unsigned int vid [[ vertex_id ]]) {
    ShaderInOut out;
    out.position = projMat * mvMat * float4(in.position, 1.0);
    out.texcoord0 = in.texcoord0;
    out.texcoord0.x *= 2;
    return out;
}

fragment half4 basic_fragment(
                              ShaderInOut in [[stage_in]],
                              sampler smp [[sampler(0)]],
                              texture2d<uint> diffuseTexture [[texture(0)]]) {
    uint4 color = diffuseTexture.sample(smp, float2(in.texcoord0));
    half4 ret = half4(color)/255.0;
    return half4(ret);
}
