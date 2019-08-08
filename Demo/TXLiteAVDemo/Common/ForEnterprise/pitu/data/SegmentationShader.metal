//
//  SegmentationShader.metal
//  ttpic
//
//  Created by stonefeng on 2017/7/6.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void refineFilter1(texture2d<float, access::sample>  inTexture   [[ texture(0) ]],
                          texture2d<float, access::write> outTexture  [[ texture(1) ]],
                          texture2d<float, access::sample> maskTexture  [[ texture(2) ]],
                          uint2                          gid         [[ thread_position_in_grid ]])
{
    float eps = 0.01f;
    float step_x = 1.0f / (float)outTexture.get_width();
    float step_y = 1.0f / (float)outTexture.get_height();
    
    constexpr sampler quadSampler(coord::normalized, filter::linear, address::clamp_to_edge);
    float fMult9 = 1.0f / 9.0f;
    float4 srcValue[9];
    float2 fIdx0 = float2((float)gid.x * step_x, (float)gid.y * step_y);
    float2 fIdx = fIdx0;
    srcValue[4] = float4(inTexture.sample(quadSampler, fIdx).rgb, maskTexture.sample(quadSampler, fIdx).r);
    
    fIdx = float2(fIdx0.x - step_x, fIdx0.y - step_y);
    srcValue[0] = float4(inTexture.sample(quadSampler, fIdx).rgb, maskTexture.sample(quadSampler, fIdx).r);
    
    fIdx = float2(fIdx0.x, fIdx0.y - step_y);
    srcValue[1] = float4(inTexture.sample(quadSampler, fIdx).rgb, maskTexture.sample(quadSampler, fIdx).r);
    
    fIdx = float2(fIdx0.x + step_x, fIdx0.y - step_y);
    srcValue[2] = float4(inTexture.sample(quadSampler, fIdx).rgb, maskTexture.sample(quadSampler, fIdx).r);
    
    fIdx = float2(fIdx0.x - step_x, fIdx0.y);
    srcValue[3] = float4(inTexture.sample(quadSampler, fIdx).rgb, maskTexture.sample(quadSampler, fIdx).r);
    
    fIdx = float2(fIdx0.x + step_x, fIdx0.y);
    srcValue[5] = float4(inTexture.sample(quadSampler, fIdx).rgb, maskTexture.sample(quadSampler, fIdx).r);
    
    fIdx = float2(fIdx0.x - step_x, fIdx0.y + step_y);
    srcValue[6] = float4(inTexture.sample(quadSampler, fIdx).rgb, maskTexture.sample(quadSampler, fIdx).r);
    
    fIdx = float2(fIdx0.x, fIdx0.y + step_y);
    srcValue[7] = float4(inTexture.sample(quadSampler, fIdx).rgb, maskTexture.sample(quadSampler, fIdx).r);
    
    fIdx = float2(fIdx0.x + step_x, fIdx0.y + step_y);
    srcValue[8] = float4(inTexture.sample(quadSampler, fIdx).rgb, maskTexture.sample(quadSampler, fIdx).r);
    
    float4 mean_I = float4(0.0);
    float3 mean_Ip = float3(0.0);
    float var_I_rr = 0.0;
    float var_I_rg = 0.0;
    float var_I_rb = 0.0;
    float var_I_gg = 0.0;
    float var_I_gb = 0.0;
    float var_I_bb = 0.0;
    for (int i = 0; i < 9; i++){
        mean_I += srcValue[i];
        mean_Ip += srcValue[i].rgb * srcValue[i].a;
        var_I_rr += srcValue[i].r * srcValue[i].r;
        var_I_rg += srcValue[i].r * srcValue[i].g;
        var_I_rb += srcValue[i].r * srcValue[i].b;
        var_I_gg += srcValue[i].g * srcValue[i].g;
        var_I_gb += srcValue[i].g * srcValue[i].b;
        var_I_bb += srcValue[i].b * srcValue[i].b;
    }
    mean_I *= fMult9;
    mean_Ip *= fMult9;
    
    var_I_rr = var_I_rr * fMult9 - mean_I.r * mean_I.r + eps;
    var_I_rg = var_I_rg * fMult9 - mean_I.r * mean_I.g;
    var_I_rb = var_I_rb * fMult9 - mean_I.r * mean_I.b;
    var_I_gg = var_I_gg * fMult9 - mean_I.g * mean_I.g + eps;
    var_I_gb = var_I_gb * fMult9 - mean_I.g * mean_I.b;
    var_I_bb = var_I_bb * fMult9 - mean_I.b * mean_I.b + eps;
    
    float3 cov_Ip = mean_Ip - mean_I.rgb * mean_I.a;
    float invrr = var_I_gg * var_I_bb - var_I_gb * var_I_gb;
    float invrg = var_I_gb * var_I_rb - var_I_rg * var_I_bb;
    float invrb = var_I_rg * var_I_gb - var_I_gg * var_I_rb;
    float invgg = var_I_rr * var_I_bb - var_I_rb * var_I_rb;
    float invgb = var_I_rb * var_I_rg - var_I_rr * var_I_gb;
    float invbb = var_I_rr * var_I_gg - var_I_rg * var_I_rg;
    float covDet = invrr * var_I_rr + invrg * var_I_rg + invrb * var_I_rb;
    
    float4 resultColor = float4(0.0);
    resultColor.r = (invrr * cov_Ip.r + invrg * cov_Ip.g + invrb * cov_Ip.b) / covDet;
    resultColor.g = (invrg * cov_Ip.r + invgg * cov_Ip.g + invgb * cov_Ip.b) / covDet;
    resultColor.b = (invrb * cov_Ip.r + invgb * cov_Ip.g + invbb * cov_Ip.b) / covDet;
    resultColor.a = (mean_I.a - resultColor.r * mean_I.r - resultColor.g * mean_I.g - resultColor.b * mean_I.b) * 0.5;
    
    outTexture.write(resultColor * 0.5 + float4(0.5), gid);
}

kernel void refineFilter2(texture2d<float>  inTexture   [[ texture(0) ]],
                          texture2d<float, access::write> outTexture  [[ texture(1) ]],
                          uint2                          gid         [[ thread_position_in_grid ]])
{
    float step_x = 1.0f / (float)outTexture.get_width();
    float step_y = 1.0f / (float)outTexture.get_height();
    
    constexpr sampler quadSampler(coord::normalized, filter::linear, address::clamp_to_edge);
    float4 srcValue = float4(0.0);
    float2 fIdx0 = float2((float)gid.x * step_x, (float)gid.y * step_y);
    float2 fIdx = fIdx0;
    srcValue += inTexture.sample(quadSampler, fIdx);
    
    fIdx = float2(fIdx0.x - step_x, fIdx0.y - step_y);
    srcValue += inTexture.sample(quadSampler, fIdx);
    
    fIdx = float2(fIdx0.x, fIdx0.y - step_y);
    srcValue += inTexture.sample(quadSampler, fIdx);
    
    fIdx = float2(fIdx0.x + step_x, fIdx0.y - step_y);
    srcValue += inTexture.sample(quadSampler, fIdx);
    
    fIdx = float2(fIdx0.x - step_x, fIdx0.y);
    srcValue += inTexture.sample(quadSampler, fIdx);
    
    fIdx = float2(fIdx0.x + step_x, fIdx0.y);
    srcValue += inTexture.sample(quadSampler, fIdx);
    
    fIdx = float2(fIdx0.x - step_x, fIdx0.y + step_y);
    srcValue += inTexture.sample(quadSampler, fIdx);
    
    fIdx = float2(fIdx0.x, fIdx0.y + step_y);
    srcValue += inTexture.sample(quadSampler, fIdx);
    
    fIdx = float2(fIdx0.x + step_x, fIdx0.y + step_y);
    srcValue += inTexture.sample(quadSampler, fIdx);
    
    outTexture.write(srcValue / 9.0, gid);
}

kernel void refineFilter3(texture2d<float>  inTexture   [[ texture(0) ]],
                          texture2d<float, access::write> outTexture  [[ texture(1) ]],
                          texture2d<float> maskTexture  [[ texture(2) ]],
                          uint2                          gid         [[ thread_position_in_grid ]])
{
    constexpr sampler quadSampler(coord::normalized, filter::linear, address::clamp_to_edge);
    float step_x = 1.0f / (float)outTexture.get_width();
    float step_y = 1.0f / (float)outTexture.get_height();
    float2 fIdx0 = float2((float)gid.x * step_x, (float)gid.y * step_y);
    
    float4 r = inTexture.sample(quadSampler, fIdx0);
    float4 s = (maskTexture.sample(quadSampler, fIdx0) - float4(0.5)) * 2.0;
    float src = s.r * r.r + s.g * r.g + s.b * r.b + s.a * 2.0;
    
    src = (src-0.5) * 2.0 + 0.5;
    if (src < 0.05) src = 0.0;
    if (src > 0.95) src = 1.0;
    
    outTexture.write(float4(src,src,src,1.0), gid);
}

kernel void buffer2Texture2(texture2d<float, access::write> outTexture  [[ texture(0) ]],
                            constant float* uData [[buffer(0)]],
                            uint2 gid [[thread_position_in_grid ]])
{
    int width = outTexture.get_width();
    int height = outTexture.get_height();
    float posx = (gid.x+0.5) * 20.0 / width - 0.5;
    float posy = (gid.y+0.5) * 26.0 / height - 0.5;
    
    int dx = floor(posx);
    int dy = floor(posy);
    int dx2 = dx + 1;
    int dy2 = dy + 1;
    if (dx < 0) dx = 0;
    if (dy < 0) dy = 0;
    if (dx2 == 20) dx2 = dx;
    if (dy2 == 26) dy2 = dy;
    float ratioX = posx - dx;
    float ratioY = posy - dy;
    float u1 = uData[dx + dy * 20];
    float u2 = uData[dx2 + dy * 20];
    float u3 = uData[dx2 + dy2 * 20];
    float u4 = uData[dx + dy2 * 20];
    u1 = max(0.0, min(1.0, (u1 - 0.3) * 2.0 + 0.5));
    u2 = max(0.0, min(1.0, (u2 - 0.3) * 2.0 + 0.5));
    u3 = max(0.0, min(1.0, (u3 - 0.3) * 2.0 + 0.5));
    u4 = max(0.0, min(1.0, (u4 - 0.3) * 2.0 + 0.5));
    
    float value = u1 * (1.0 - ratioX) * (1.0 - ratioY) +
    u2 * ratioX * (1.0 - ratioY) +
    u3 * ratioX * ratioY +
    u4 * (1.0 - ratioX) * ratioY;
    outTexture.write(float4(value, value, value, 1.0), gid);
}

kernel void kernel_Float32toBGRA2(texture2d<float, access::write> outTexture  [[ texture(0) ]],
                                  constant float* uData [[buffer(0)]],
                                  constant int* dimensions [[buffer(1)]],
                                  uint2 gid [[thread_position_in_grid ]])
{
    float width = (float)outTexture.get_width();
    float height = (float)outTexture.get_height();
    int uniform_w = dimensions[0];
    int uniform_h = dimensions[1];
    float posx = (float)gid.x * (float)uniform_w / width;
    float posy = (float)gid.y * (float)uniform_h / height;
    
    int dx = floor(posx);
    int dy = floor(posy);
    int dx2 = dx + 1;
    int dy2 = dy + 1;
    if (dx < 0) dx = 0;
    if (dy < 0) dy = 0;
    if (dx2 == uniform_w) dx2 = dx;
    if (dy2 == uniform_h) dy2 = dy;
    float ratioX = posx - dx;
    float ratioY = posy - dy;
    float u1 = uData[dx + dy * uniform_w];
    float u2 = uData[dx2 + dy * uniform_w];
    float u3 = uData[dx2 + dy2 * uniform_w];
    float u4 = uData[dx + dy2 * uniform_w];
    float r0 = (u1 * (1.0 - ratioX) * (1.0 - ratioY) +
                u2 * ratioX * (1.0 - ratioY) +
                u3 * ratioX * ratioY +
                u4 * (1.0 - ratioX) * ratioY);
    
    int offset = uniform_w * uniform_h;
    u1 = uData[offset + dx + dy * uniform_w];
    u2 = uData[offset + dx2 + dy * uniform_w];
    u3 = uData[offset + dx2 + dy2 * uniform_w];
    u4 = uData[offset + dx + dy2 * uniform_w];
    float r1 = (u1 * (1.0 - ratioX) * (1.0 - ratioY) +
                u2 * ratioX * (1.0 - ratioY) +
                u3 * ratioX * ratioY +
                u4 * (1.0 - ratioX) * ratioY);
    
    float diff = exp(r1-r0);
    diff = diff/(diff + 1.0f);
    //    float r = diff;
    //    float r = diff > 0.5?1.0f:0.0f;
    float r = saturate((diff - 0.5f) * 1.5f + 0.5f);
    if (r < 0.05) r = 0;
    if (r > 0.95) r = 1.0f;
    
    outTexture.write(float4(r, r, r, 1.0), gid);
}

kernel void kernel_Float32toBGRA3(texture2d<float, access::write> outTexture  [[ texture(0) ]],
                                  constant float* uData [[buffer(0)]],
                                  constant float* weight [[buffer(1)]],
                                  constant int* dimensions [[buffer(2)]],
                                  uint2 gid [[thread_position_in_grid ]])
{
    float width = (float)outTexture.get_width();
    float height = (float)outTexture.get_height();
    int uniform_w = dimensions[0];
    int uniform_h = dimensions[1];
    float posx = (float)gid.x * (float)uniform_w / width;
    float posy = (float)gid.y * (float)uniform_h / height;
    
    int dx = floor(posx);
    int dy = floor(posy);
    int dx2 = dx + 1;
    int dy2 = dy + 1;
    if (dx < 0) dx = 0;
    if (dy < 0) dy = 0;
    if (dx2 == uniform_w) dx2 = dx;
    if (dy2 == uniform_h) dy2 = dy;
    float ratioX = posx - dx;
    float ratioY = posy - dy;
    
    int idx1 = dx + dy * uniform_w;
    int idx2 = dx2 + dy * uniform_w;
    int idx3 = dx2 + dy2 * uniform_w;
    int idx4 = dx + dy2 * uniform_w;
    
    if (weight[idx1] < 0.5 && weight[idx2] < 0.5 && weight[idx3] < 0.5 && weight[idx3] < 0.5) {
        outTexture.write(float4(0, 0, 0, 1.0), gid);
    }
    else {
        float u1 = uData[idx1];
        float u2 = uData[idx2];
        float u3 = uData[idx3];
        float u4 = uData[idx4];
        float r0 = (u1 * (1.0 - ratioX) * (1.0 - ratioY) +
                    u2 * ratioX * (1.0 - ratioY) +
                    u3 * ratioX * ratioY +
                    u4 * (1.0 - ratioX) * ratioY);
        
        int offset = uniform_w * uniform_h;
        u1 = uData[idx1+offset];
        u2 = uData[idx2+offset];
        u3 = uData[idx3+offset];
        u4 = uData[idx4+offset];
        float r1 = (u1 * (1.0 - ratioX) * (1.0 - ratioY) +
                    u2 * ratioX * (1.0 - ratioY) +
                    u3 * ratioX * ratioY +
                    u4 * (1.0 - ratioX) * ratioY);
        
        float diff = exp(r1-r0);
        diff = diff/(diff + 1.0f);
        float r = diff;
        //    float r = saturate((diff - 0.5f) * 1.5f + 0.5f);
        //    if (r < 0.05) r = 0;
        //    if (r > 0.95) r = 1.0f;
        
        outTexture.write(float4(r, r, r, 1.0), gid);
    }
}

kernel void kernel_smallmap(texture2d<float, access::read> outTexture  [[ texture(0) ]],
                            constant float* uData [[buffer(0)]],
                            constant int* dimensions [[buffer(1)]],
                            device float* uData1 [[buffer(2)]],
                            uint2 gid [[thread_position_in_grid ]])
{
    int uniform_w = dimensions[0];
    int uniform_h = dimensions[1];
    int offset = uniform_w * uniform_h;
    int index = gid.y * uniform_w + gid.x;
    
    float u0 = uData[index];
    float u1 = uData[index + offset];
    float u = exp(u1- u0);
    u = u/(u + 1.0f);
    //    u = (u-0.5) * 2.0 + 0.5;
    uData1[index] = u > 0.05?1.0f:0.0f;
}

kernel void kernel_refineMask(texture2d<float, access::read> outTexture  [[ texture(0) ]],
                              constant float* srcData [[buffer(0)]],
                              device float* dstData [[buffer(1)]],
                              uint2 gid [[thread_position_in_grid ]])
{
    int width = outTexture.get_width();
    int height = outTexture.get_height();
    int offset[2];
    offset[0] = 0;
    offset[1] = width * height;
    
    int gx = gid.x;
    int gy = gid.y;
    int x[3];
    int y[3];
    x[0] = max(gx - 1, 0);
    x[1] = gid.x;
    x[2] = min(gx + 1, width - 1);
    y[0] = max(gy - 1, 0);
    y[1] = gid.y;
    y[2] = min(gy + 1, height - 1);
    
#define s2(a, b)				temp = a; a = min(a, b); b = max(temp, b);
#define mn3(a, b, c)			s2(a, b); s2(a, c);
#define mx3(a, b, c)			s2(b, c); s2(a, c);
    
#define mnmx3(a, b, c)			mx3(a, b, c); s2(a, b);                                   // 3 exchanges
#define mnmx4(a, b, c, d)		s2(a, b); s2(c, d); s2(a, c); s2(b, d);                   // 4 exchanges
#define mnmx5(a, b, c, d, e)	s2(a, b); s2(c, d); mn3(a, c, e); mx3(b, d, e);           // 6 exchanges
#define mnmx6(a, b, c, d, e, f) s2(a, d); s2(b, e); s2(c, f); mn3(a, b, c); mx3(d, e, f); // 7 exchanges
    
    for (int i = 0; i < 2; i++) {
        
        float temp, v[6];
        int offseti = offset[i];
        
        uint index = width * y[2] + x[0] + offseti;
        v[0] = srcData[index];
        index = width * y[0] + x[2] + offseti;
        v[1] = srcData[index];
        index = width * y[0] + x[0] + offseti;
        v[2] = srcData[index];
        index = width * y[2] + x[2] + offseti;
        v[3] = srcData[index];
        index = width * y[1] + x[0] + offseti;
        v[4] = srcData[index];
        index = width * y[1] + x[2] + offseti;
        v[5] = srcData[index];
        
        mnmx6(v[0], v[1], v[2], v[3], v[4], v[5]);
        
        index = width * y[2] + x[1] + offseti;
        v[5] = srcData[index];
        
        mnmx5(v[1], v[2], v[3], v[4], v[5]);
        
        index = width * y[0] + x[1] + offseti;
        v[5] = srcData[index];
        
        mnmx4(v[2], v[3], v[4], v[5]);
        
        index = width * y[1] + x[1] + offseti;
        v[5] = srcData[index];
        
        mnmx3(v[3], v[4], v[5]);
        
        dstData[index + offseti] = v[4];
    }
}

kernel void erodeFilter(texture2d<half, access::read>  inTexture   [[ texture(0) ]],
                        texture2d<half, access::write> outTexture  [[ texture(1) ]],
                        uint2                          gid         [[ thread_position_in_grid ]])
{
    half4 inColor  = inTexture.read(gid);
    
    uint2 position = uint2(gid.x - 1, gid.y - 1);
    inColor = min(inTexture.read(position), inColor);
    
    position = uint2(gid.x, gid.y - 1);
    inColor = min(inTexture.read(position), inColor);
    
    position = uint2(gid.x + 1, gid.y - 1);
    inColor = min(inTexture.read(position), inColor);
    
    position = uint2(gid.x - 1, gid.y);
    inColor = min(inTexture.read(position), inColor);
    
    position = uint2(gid.x + 1, gid.y);
    inColor = min(inTexture.read(position), inColor);
    
    position = uint2(gid.x - 1, gid.y + 1);
    inColor = min(inTexture.read(position), inColor);
    
    position = uint2(gid.x, gid.y + 1);
    inColor = min(inTexture.read(position), inColor);
    
    position = uint2(gid.x + 1, gid.y + 1);
    inColor = min(inTexture.read(position), inColor);
    
    outTexture.write(inColor, gid);
}

kernel void dilateFilter(texture2d<half, access::read>  inTexture   [[ texture(0) ]],
                         texture2d<half, access::write> outTexture  [[ texture(1) ]],
                         //                         constant fixUniform  &uData [[buffer(0)]],
                         uint2                          gid         [[ thread_position_in_grid ]])
{
    int deltaX = 1;//uData.deltaX;
    int deltaY = 1;//uData.deltaY;
    half4 inColor  = inTexture.read(gid);
    uint2 xGid = uint2(gid.x + deltaX, gid.y + deltaY);
    inColor = max(inColor, inTexture.read(xGid));
    xGid = uint2(xGid.x + deltaX, xGid.y + deltaY);
    inColor = max(inColor, inTexture.read(xGid));
    xGid = uint2(gid.x - deltaX, gid.y - deltaY);
    inColor = max(inColor, inTexture.read(xGid));
    xGid = uint2(xGid.x - deltaX, xGid.y - deltaY);
    inColor = max(inColor, inTexture.read(xGid));
    
    outTexture.write(inColor, gid);
}


kernel void fixNormalFilter(texture2d<half, access::read>  inTexture   [[ texture(0) ]],
                            texture2d<half, access::write> outTexture  [[ texture(1) ]],
                            uint2                          gid         [[ thread_position_in_grid ]])
{
    half4 inColor  = inTexture.read(gid);
    inColor = 2.0 * (inColor - half4(0.3)) + half4(0.5);
    inColor = max(half4(0.0), min(half4(1.0), inColor));
    outTexture.write(half4(inColor.rgb, 1.0), gid);
}

kernel void kernel_diff(texture2d<float, access::write> outTexture  [[ texture(0) ]],
                        texture2d<float, access::read> inTexture0  [[ texture(1) ]],
                        texture2d<float, access::read> inTexture1  [[ texture(2) ]],
                        uint2 gid [[thread_position_in_grid ]])
{
    float r0 = inTexture0.read(gid).r;
    float r1 = inTexture1.read(gid).r;
    
    float diff = exp(r1-r0);
    diff = diff/(diff + 1.0f);
    float r = diff;
    //    float r = (diff > 0.5f)?1.0f:0.0f;
    //    float r = (diff - 0.5f) * 1.5f + 0.5f;
    //    if (r < 0.5) r = 0;
    //    if (r > 0.5) r = 1.0f;
    outTexture.write(float4(r, r, r, 1.0), gid);
}

kernel void kernel_diff2(texture2d<float, access::read> preTexture  [[ texture(0) ]],
                         texture2d<float, access::read> curTexture  [[ texture(1) ]],
                         texture2d<float, access::read> preTexture0  [[ texture(2) ]],
                         texture2d<float, access::read> preTexture1  [[ texture(3) ]],
                         texture2d<float, access::read> cnnTexture0  [[ texture(4) ]],
                         texture2d<float, access::read> cnnTexture1  [[ texture(5) ]],
                         texture2d<float, access::write> dstTexture0  [[ texture(6) ]],
                         texture2d<float, access::write> dstTexture1  [[ texture(7) ]],
                         uint2 gid [[thread_position_in_grid ]])
{
    float4 curColor4 = curTexture.read(gid);
    float4 preColor4 = preTexture.read(gid);
    float diff = fabs(curColor4.r - preColor4.r) + fabs(curColor4.g - preColor4.g) + fabs(curColor4.b - preColor4.b);
    diff = min(1.0f, diff * 1.7f);
    
    float pre0 = preTexture0.read(gid).r;
    float cnn0 = cnnTexture0.read(gid).r;
    float r0 = mix(pre0, cnn0, diff);
    r0 = mix(cnn0, r0, 0.5f);
    dstTexture0.write(float4(r0, r0, r0, 1.0f), gid);
    
    float pre1 = preTexture1.read(gid).r;
    float cnn1 = cnnTexture1.read(gid).r;
    float r1 = mix(pre1, cnn1, diff);
    r1 = mix(cnn1, r1, 0.5f);
    dstTexture1.write(float4(r1, r1, r1, 1.0f), gid);
}

kernel void kernel_resize(texture2d<float, access::write> outTexture  [[ texture(0) ]],
                          texture2d<float, access::read> inTexture  [[ texture(1) ]],
                          uint2 gid [[thread_position_in_grid ]])
{
    uint out_w = outTexture.get_width();
    uint out_h = outTexture.get_height();
    uint in_w = inTexture.get_width();
    uint in_h = inTexture.get_height();
    
    float posx = (float)(gid.x * in_w) / (float)out_w;
    float posy = (float)(gid.y * in_h) / (float)out_h;
    
    int dx = floor(posx);
    int dy = floor(posy);
    
    float u1 = inTexture.read(uint2(dx, dy)).r;
    float u2 = inTexture.read(uint2(dx+1, dy)).r;
    float u3 = inTexture.read(uint2(dx+1, dy+1)).r;
    float u4 = inTexture.read(uint2(dx, dy+1)).r;
    
    float ratioX = posx - dx;
    float ratioY = posy - dy;
    float r = (u1 * (1.0 - ratioX) * (1.0 - ratioY) +
               u2 * ratioX * (1.0 - ratioY) +
               u3 * ratioX * ratioY +
               u4 * (1.0 - ratioX) * ratioY);
    
    outTexture.write(float4(r, r, r, 1.0), gid);
}

struct VertexIO
{
    float4 m_Position [[position]];
    float2 m_TexCoord [[user(texturecoord)]];
};

fragment half4 texturedQuadFragmentMaskBgFg2(VertexIO         inFrag  [[ stage_in ]],
                                             texture2d<half>  tex2D   [[ texture(0) ]],
                                             texture2d<half>  mask2D  [[ texture(1) ]])
{
    constexpr sampler quadSampler(coord::normalized, filter::linear, address::clamp_to_edge);
    
    half4 src = tex2D.sample(quadSampler, inFrag.m_TexCoord);
    half4 mask = mask2D.sample(quadSampler, inFrag.m_TexCoord);
    half4 bgColor = half4(0.078431373,0.15686275,0.31372549,1.0);
    half alpha = saturate(mask.r * 1.4f - 0.15f);
    if (alpha < 0.3) alpha = 0.0f;
    if (alpha > 0.5) alpha = 1.0f;
    return mix(bgColor, src, alpha);
}

kernel void kernel_box(texture2d<float, access::read>  inTexture   [[ texture(0) ]],
                       texture2d<float, access::write> outTexture  [[ texture(1) ]],
                       constant int* dimensions                   [[ buffer(1) ]],
                       uint2                          gid         [[ thread_position_in_grid ]])
{
    int kernel_w = dimensions[0];
    int kernel_h = dimensions[1];
    int iter_w = 2*kernel_w+1;
    int iter_h = 2*kernel_h+1;
    
    float4 inColor  = float4(0.0f);
    for (int i = 0; i < iter_w; i++) {
        for (int j = 0; j < iter_h; j++) {
            uint2 position = uint2(gid.x - kernel_w + i, gid.y - kernel_h + j);
            inColor += inTexture.read(position);
        }
    }
    
    inColor = inColor/(float)(iter_w*iter_h);
    outTexture.write(inColor, gid);
}

kernel void kernel_box_horizon(texture2d<float, access::read>  inTexture   [[ texture(0) ]],
                               texture2d<float, access::write> outTexture  [[ texture(1) ]],
                               constant int* dimensions                   [[ buffer(1) ]],
                               uint2                          gid         [[ thread_position_in_grid ]])
{
    int kernel_w = dimensions[0];
    int iter_w = 2*kernel_w+1;
    
    float4 inColor  = float4(0.0f);
    for (int i = 0; i < iter_w; i++) {
        uint2 position = uint2(gid.x - kernel_w + i, gid.y);
        inColor += inTexture.read(position);
    }
    
    inColor = inColor/(float)iter_w;
    outTexture.write(inColor, gid);
}

kernel void kernel_box_vertical(texture2d<float, access::read>  inTexture   [[ texture(0) ]],
                                texture2d<float, access::write> outTexture  [[ texture(1) ]],
                                constant int* dimensions                   [[ buffer(1) ]],
                                uint2                          gid         [[ thread_position_in_grid ]])
{
    int kernel_h = dimensions[1];
    int iter_h = 2*kernel_h+1;
    
    float4 inColor  = float4(0.0f);
    for (int j = 0; j < iter_h; j++) {
        uint2 position = uint2(gid.x, gid.y - kernel_h + j);
        inColor += inTexture.read(position);
    }
    
    inColor = inColor/(float)(iter_h);
    outTexture.write(inColor, gid);
}

kernel void kernel_dilate_horizon(texture2d<float, access::read>  inTexture   [[ texture(0) ]],
                                  texture2d<float, access::write> outTexture  [[ texture(1) ]],
                                  constant int* dimensions                   [[ buffer(1) ]],
                                  uint2                          gid         [[ thread_position_in_grid ]])
{
    int kernel_w = dimensions[0];
    int iter_w = 2*kernel_w+1;
    
    float4 inColor  = float4(0.0f);
    for (int i = 0; i < iter_w; i++) {
        uint2 position = uint2(gid.x - kernel_w + i, gid.y);
        float4 color = inTexture.read(position);
        inColor = max(color, inColor);
    }
    
    outTexture.write(inColor, gid);
}

kernel void kernel_dilate_vertical(texture2d<float, access::read>  inTexture   [[ texture(0) ]],
                                   texture2d<float, access::write> outTexture  [[ texture(1) ]],
                                   constant int* dimensions                   [[ buffer(1) ]],
                                   uint2                          gid         [[ thread_position_in_grid ]])
{
    int kernel_h = dimensions[1];
    int iter_h = 2*kernel_h+1;
    
    float4 inColor  = float4(0.0f);
    for (int j = 0; j < iter_h; j++) {
        uint2 position = uint2(gid.x, gid.y - kernel_h + j);
        float4 color = inTexture.read(position);
        inColor = max(color, inColor);
    }
    
    outTexture.write(inColor, gid);
}



