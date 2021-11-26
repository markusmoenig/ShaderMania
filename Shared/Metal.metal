//
//  Metal.metal
//  ShaderMania
//
//  Created by Markus Moenig on 25/8/20.
//

#include <metal_stdlib>
using namespace metal;

#import "Metal.h"

typedef struct
{
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
} RasterizerData;

// Quad Vertex Function
vertex RasterizerData
m4mQuadVertexShader(uint vertexID [[ vertex_id ]],
             constant VertexUniform *vertexArray [[ buffer(0) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(1) ]])
{
    RasterizerData out;
    
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
    float2 viewportSize = float2(*viewportSizePointer);
    
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
    out.clipSpacePosition.z = 0.0;
    out.clipSpacePosition.w = 1.0;
    
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

// --- SDF utilities

float m4mFillMask(float dist)
{
    return clamp(-dist, 0.0, 1.0);
}

float m4mBorderMask(float dist, float width)
{
    dist += 1.0;
    return clamp(dist + width, 0.0, 1.0) - clamp(dist, 0.0, 1.0);
}

float2 m4mRotateCCW(float2 pos, float angle)
{
    float ca = cos(angle), sa = sin(angle);
    return pos * float2x2(ca, sa, -sa, ca);
}

float2 m4mRotateCCWPivot(float2 pos, float angle, float2 pivot)
{
    float ca = cos(angle), sa = sin(angle);
    return pivot + (pos-pivot) * float2x2(ca, sa, -sa, ca);
}

float2 m4mRotateCW(float2 pos, float angle)
{
    float ca = cos(angle), sa = sin(angle);
    return pos * float2x2(ca, -sa, sa, ca);
}

float2 m4mRotateCWPivot(float2 pos, float angle, float2 pivot)
{
    float ca = cos(angle), sa = sin(angle);
    return pivot + (pos-pivot) * float2x2(ca, -sa, sa, ca);
}

// Disc
fragment float4 m4mDiscDrawable(RasterizerData in [[stage_in]],
                               constant DiscUniform *data [[ buffer(0) ]],
                               texture2d<float> inTexture [[ texture(1) ]] )
{
    float2 uv = in.textureCoordinate * float2( data->radius * 2 + data->borderSize, data->radius * 2 + data->borderSize);
    uv -= float2( data->radius + data->borderSize / 2 );
    
    float dist = length( uv ) - data->radius + data->onion;
    if (data->onion > 0.0)
        dist = abs(dist) - data->onion;
    
    const float mask = m4mFillMask( dist );
    float4 col = float4( data->fillColor.xyz, data->fillColor.w * mask);
    
    float borderMask = m4mBorderMask(dist, data->borderSize);
    float4 borderColor = data->borderColor;
    borderColor.w *= borderMask;
    col = mix( col, borderColor, borderMask );

    if (data->hasTexture == 1 && col.w > 0.0) {
        constexpr sampler textureSampler (mag_filter::linear,
                                          min_filter::linear);
        
        float2 uv = in.textureCoordinate;
        uv.y = 1 - uv.y;
        uv = m4mRotateCCWPivot(uv, data->rotation, 0.5);

        float4 sample = float4(inTexture.sample(textureSampler, uv));
        
        col.xyz = sample.xyz;
        col.w = col.w * sample.w;
    }
    
    return col;
}

// Box
fragment float4 m4mBoxDrawable(RasterizerData in [[stage_in]],
                               constant BoxUniform *data [[ buffer(0) ]],
                               texture2d<float> inTexture [[ texture(1) ]] )
{
    float2 uv = in.textureCoordinate * ( data->size );
    uv -= float2( data->size / 2.0 );
    
    float2 d = abs( uv ) - data->size / 2 + data->onion + data->round;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    if (data->onion > 0.0)
        dist = abs(dist) - data->onion;
    
    const float mask = m4mFillMask( dist );
    float4 col = float4( data->fillColor.xyz, data->fillColor.w * mask);
    
    float borderMask = m4mBorderMask(dist, data->borderSize);
    float4 borderColor = data->borderColor;
    borderColor.w *= borderMask;
    col = mix( col, borderColor, borderMask );
    
    if (data->hasTexture == 1 && col.w > 0.0) {
        constexpr sampler textureSampler (mag_filter::linear,
                                          min_filter::linear);
        
        float2 uv = in.textureCoordinate;
        uv.y = 1 - uv.y;
        uv = m4mRotateCCWPivot(uv, data->rotation, 0.5);

        float4 sample = float4(inTexture.sample(textureSampler, uv));
        
        col.xyz = sample.xyz;
        col.w = col.w * sample.w;
    }
    
    return col;
}

// Box
fragment float4 m4mLineDrawable(RasterizerData in [[stage_in]],
                               constant LineUniform *data [[ buffer(0) ]])
{
    float2 uv = in.textureCoordinate * ( data->size + data->borderSize / 2.0);
    uv -= float2(data->size / 2.0 + data->borderSize / 2.0);
    
    float2 o = uv - data->sp;
    float2 l = data->ep - data->sp;
    
    float h = clamp( dot(o,l)/dot(l,l), 0.0, 1.0 );
    float dist = -(data->width-distance(o,l*h));
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    
    return col;
}

// Rotated Box
fragment float4 m4mBoxDrawableExt(RasterizerData in [[stage_in]],
                               constant BoxUniform *data [[ buffer(0) ]],
                               texture2d<float> inTexture [[ texture(1) ]] )
{
    float2 uv = in.textureCoordinate * data->screenSize;
    uv.y = data->screenSize.y - uv.y;
    uv -= float2(data->size / 2.0);
    uv -= float2(data->pos.x, data->pos.y);

    uv = m4mRotateCCW(uv, data->rotation);
    
    float2 d = abs( uv ) - data->size / 2.0 + data->onion + data->round;// - data->borderSize;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    if (data->onion > 0.0)
        dist = abs(dist) - data->onion;

    const float mask = m4mFillMask( dist );//smoothstep(0.0, pixelSize, -dist);
    float4 col = float4( data->fillColor.xyz, data->fillColor.w * mask);
    
    const float borderMask = m4mBorderMask(dist, data->borderSize);
    float4 borderColor = data->borderColor;
    borderColor.w *= borderMask;
    col = mix( col, borderColor, borderMask );
    
    if (data->hasTexture == 1 && col.w > 0.0) {
        constexpr sampler textureSampler (mag_filter::linear,
                                          min_filter::linear);
        
        float2 uv = in.textureCoordinate;
        uv.y = 1 - uv.y;
        
        uv -= data->pos / data->screenSize;
        uv *= data->screenSize / data->size;
        
        uv = m4mRotateCCWPivot(uv, data->rotation, (data->size / 2.0) / data->screenSize * (data->screenSize / data->size));
        
        float4 sample = float4(inTexture.sample(textureSampler, uv));
        
        col.xyz = sample.xyz;
        col.w = col.w * sample.w;
    }

    return col;
}

// --- Box Drawable
fragment float4 m4mBoxPatternDrawable(RasterizerData in [[stage_in]],
                               constant BoxUniform *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->screenSize );
    uv -= float2( data->screenSize / 2.0 );
    
    float2 d = abs( uv ) - data->size / 2.0;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0);
    
    float4 checkerColor1 = data->fillColor;
    float4 checkerColor2 = data->borderColor;
    
    //uv = fragCoord;
    //uv -= float2( data->size / 2 );
    
    float4 col = checkerColor1;
    
    float cWidth = 12.0;
    float cHeight = 12.0;
    
    if ( fmod( floor( uv.x / cWidth ), 2.0 ) == 0.0 ) {
        if ( fmod( floor( uv.y / cHeight ), 2.0 ) != 0.0 ) col=checkerColor2;
    } else {
        if ( fmod( floor( uv.y / cHeight ), 2.0 ) == 0.0 ) col=checkerColor2;
    }
    
    return float4( col.xyz, m4mFillMask( dist ) );
}

// Copy texture
fragment float4 m4mCopyTextureDrawable(RasterizerData in [[stage_in]],
                                constant TextureUniform *data [[ buffer(0) ]],
                                texture2d<half, access::read> inTexture [[ texture(1) ]])
{
    float2 uv = in.textureCoordinate * data->size;
    uv.y = data->size.y - uv.y;
    
    const half4 colorSample = inTexture.read(uint2(uv));
    float4 sample = float4( colorSample );

    sample.w *= data->globalAlpha;

    return float4(sample.x / sample.w, sample.y / sample.w, sample.z / sample.w, sample.w);
}

fragment float4 m4mTextureDrawable(RasterizerData in [[stage_in]],
                                constant TextureUniform *data [[ buffer(0) ]],
                                texture2d<half> inTexture [[ texture(1) ]])
{
    //constexpr sampler textureSampler (mag_filter::linear,
    //                                  min_filter::linear);
    
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    float2 uv = in.textureCoordinate;
    uv.y = 1 - uv.y;
    
    uv.x *= data->size.x;
    uv.y *= data->size.y;

    uv.x += data->pos.x;
    uv.y += data->pos.y;
    
    float4 sample = float4(inTexture.sample(textureSampler, uv));
    sample.w *= data->globalAlpha;

    return sample;
}

float m4mMedian(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

fragment float4 m4mTextDrawable(RasterizerData in [[stage_in]],
                                constant TextUniform *data [[ buffer(0) ]],
                                texture2d<float> inTexture [[ texture(1) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    float2 uv = in.textureCoordinate;
    uv.y = 1 - uv.y;

    uv /= data->atlasSize / data->fontSize;
    uv += data->fontPos / data->atlasSize;

    float4 sample = inTexture.sample(textureSampler, uv );
        
    float d = m4mMedian(sample.r, sample.g, sample.b) - 0.5;
    float w = clamp(d/fwidth(d) + 0.5, 0.0, 1.0);
    return float4( data->color.x, data->color.y, data->color.z, w * data->color.w );
}

kernel void makeCGIImage(
texture2d<half, access::write>          outTexture  [[texture(0)]],
texture2d<half, access::read>           inTexture [[texture(2)]],
uint2 gid                               [[thread_position_in_grid]])
{
    //float2 size = float2( outTexture.get_width(), outTexture.get_height() );
    half4 color = inTexture.read(gid).zyxw;
    color.xyz = pow(color.xyz, 2.2);
    outTexture.write(color, gid);
}

// MetalMania routines

fragment float4 mmDiscDrawable(RasterizerData in [[stage_in]],
                                constant MM_SPHERE *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * float2( data->radius * 2 + data->borderSize, data->radius * 2 + data->borderSize );
    uv -= float2( data->radius + data->borderSize / 2 );
    
    float dist = length( uv ) - data->radius;
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    return col;
}


float m4mGradient_linear(float2 uv, float2 p1, float2 p2) {
    return clamp(dot(uv-p1,p2-p1)/dot(p2-p1,p2-p1),0.,1.);
}

fragment float4 mmLineDrawable(RasterizerData in [[stage_in]],
                               constant MM_LINE *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
    uv -= float2( data->size / 2.0 + data->borderSize / 2.0 );
//    uv -= (data->sp + data->ep) / 2;

    float2 o = uv - data->sp;
    float2 l = data->ep - data->sp;
    
    float h = clamp( dot(o,l)/dot(l,l), 0.0, 1.0 );
    float dist = -(data->width-distance(o,l*h));
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    
    return col;
}

float mmBezier(float2 pos, float2 p0, float2 p1, float2 p2)
{
    // p(t)    = (1-t)^2*p0 + 2(1-t)t*p1 + t^2*p2
    // p'(t)   = 2*t*(p0-2*p1+p2) + 2*(p1-p0)
    // p'(0)   = 2(p1-p0)
    // p'(1)   = 2(p2-p1)
    // p'(1/2) = 2(p2-p0)
    float2 a = p1 - p0;
    float2 b = p0 - 2.0*p1 + p2;
    float2 c = p0 - pos;
    
    float kk = 1.0 / dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(c,b)) / 3.0;
    float kz = kk * dot(c,a);
    
    float2 res;
    
    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float h = q*q + 4.0*p3;
    
    if(h >= 0.0)
    {
        h = sqrt(h);
        float2 x = (float2(h, -h) - q) / 2.0;
        float2 uv = sign(x)*pow(abs(x), float2(1.0/3.0));
        float t = uv.x + uv.y - kx;
        t = clamp( t, 0.0, 1.0 );
        
        // 1 root
        float2 qos = c + (2.0*a + b*t)*t;
        res = float2( length(qos),t);
    } else {
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        float3 t = float3(m + m, -n - m, n - m) * z - kx;
        t = clamp( t, 0.0, 1.0 );
        
        // 3 roots
        float2 qos = c + (2.0*a + b*t.x)*t.x;
        float dis = dot(qos,qos);
        
        res = float2(dis,t.x);
        
        qos = c + (2.0*a + b*t.y)*t.y;
        dis = dot(qos,qos);
        if( dis<res.x ) res = float2(dis,t.y );
        
        qos = c + (2.0*a + b*t.z)*t.z;
        dis = dot(qos,qos);
        if( dis<res.x ) res = float2(dis,t.z );
        
        res.x = sqrt( res.x );
    }
    return res.x;
}

fragment float4 mmSplineDrawable(RasterizerData in [[stage_in]],
                                constant MM_SPLINE *data [[ buffer(0) ]] )
{
    float2 size = data->size;// - float2(400, 400);
    float2 uv = in.textureCoordinate * ( size + float2( data->borderSize ) * 2.0 );
    uv -= float2( size / 2.0 + data->borderSize / 2.0 );
    //    uv -= (data->sp + data->ep) / 2;
    
    float dist = mmBezier( uv, data->sp, data->cp, data->ep ) - data->width;
    
//    float2 o = uv - data->sp;
//    float2 l = data->ep - data->sp;
    
//    float h = clamp( dot(o,l)/dot(l,l), 0.0, 1.0 );
//    float dist = -(data->width-distance(o,l*h));
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    
    return col;
}

// --- Box Drawable
fragment float4 mmBoxDrawable(RasterizerData in [[stage_in]],
                               constant MM_BOX *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
    uv -= float2( data->size / 2.0 + data->borderSize );

    float2 d = abs( uv ) - data->size / 2 + data->round;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    return col;
}

fragment float4 mmRotatedBoxDrawable(RasterizerData in [[stage_in]],
                               constant MM_ROTATEDBOX *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
    uv -= float2( data->size / 2.0 + data->borderSize );

    uv = m4mRotateCW(uv, data->rotation.x * 3.14159265359 / 180.);
    
    float2 d = abs( uv ) - data->size / 2 + data->round;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    return col;
}

// --- Box Drawable
fragment float4 mmBoxPatternDrawable(RasterizerData in [[stage_in]],
                               constant MM_BOX *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
    uv -= float2( data->size / 2.0 + data->borderSize );
    
    float2 d = abs( uv ) - data->size / 2 + data->round;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    float4 checkerColor1 = data->fillColor;
    float4 checkerColor2 = data->borderColor;
    
    //uv = fragCoord;
    uv -= float2( data->size / 2 );
    
    float4 col = checkerColor1;
    
    float cWidth = 24.0;
    float cHeight = 24.0;
    
    if ( fmod( floor( uv.x / cWidth ), 2.0 ) == 0.0 ) {
        if ( fmod( floor( uv.y / cHeight ), 2.0 ) != 0.0 ) col=checkerColor2;
    } else {
        if ( fmod( floor( uv.y / cHeight ), 2.0 ) == 0.0 ) col=checkerColor2;
    }
    
    return float4( col.xyz, m4mFillMask( dist ) );
}

// --- Box Gradient
fragment float4 mmBoxGradientDrawable(RasterizerData in [[stage_in]],
                                       constant MM_BOX_GRADIENT *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0);
    uv -= float2( data->size / 2.0 + data->borderSize / 2.0 );
    
    float2 d = abs( uv ) - data->size / 2 + data->round;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    uv = in.textureCoordinate;
    uv.y = 1 - uv.y;
    float s = m4mGradient_linear( uv, data->uv1, data->uv2 ) / 1;
    s = clamp(s, 0.0, 1.0);
    float4 col = float4( mix( data->gradientColor1.rgb, data->gradientColor2.rgb, s ), m4mFillMask( dist ) );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    
    return col;
}

// --- Box Drawable
fragment float4 mmBoxedMenuDrawable(RasterizerData in [[stage_in]],
                                     constant MM_BOXEDMENU *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
    uv -= float2( data->size / 2.0 + data->borderSize / 2.0 );
    
    // Main
    float2 d = abs( uv ) - data->size / 2 + data->round;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    
    // --- Lines
    
    float lineWidth = 1.5;
    float lineRound = 4.0;
    
    //const float4 lineColor = float4(0.957, 0.957, 0.957, 1.000);
    const float4 lineColor = float4(0.95, 0.95, 0.95, 1.000);

    // --- Middle
    uv = in.textureCoordinate * data->size;
    uv -= data->size / 2.0;

    d = abs( uv ) -  float2( data->size.x / 3, lineWidth) + lineRound;
    dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - lineRound;
    
//    col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, lineColor, m4mFillMask( dist ) );

    // --- Top
    uv = in.textureCoordinate * data->size;
    uv -= data->size / 2.0;
    uv.y -= data->size.y / 4;
    
    d = abs( uv ) -  float2( data->size.x / 3, lineWidth) + lineRound;
    dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - lineRound;
    col = mix( col, lineColor, m4mFillMask( dist ) );
    
    // --- Bottom
    uv = in.textureCoordinate * data->size;
    uv -= data->size / 2.0;
    uv.y += data->size.y / 4;
    
    d = abs( uv ) -  float2( data->size.x / 3, lineWidth) + lineRound;
    dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - lineRound;
    col = mix( col, lineColor, m4mFillMask( dist ) );
    
    return col;
}

// --- Boxed Plus Drawable
fragment float4 mmBoxedPlusDrawable(RasterizerData in [[stage_in]],
                                      constant MM_BOXEDMENU *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
    uv -= float2( data->size / 2.0 + data->borderSize / 2.0 );
    
    // Main
    float2 d = abs( uv ) - data->size / 2 + data->round;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    
    // --- Lines
    
    float lineWidth = 2.5;
    float lineRound = 4.0;
    
    // --- Middle
    uv = in.textureCoordinate * data->size;
    uv -= data->size / 2.0;
    
    d = abs( uv ) -  float2( data->size.x / 3, lineWidth) + lineRound;
    dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - lineRound;
    col = mix( col,  float4( 0.957, 0.957, 0.957, 1 ), m4mFillMask( dist ) );
    
    d = abs( uv ) -  float2(lineWidth, data->size.y / 3) + lineRound;
    dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - lineRound;
    col = mix( col,  float4( 0.957, 0.957, 0.957, 1 ), m4mFillMask( dist ) );
    
    return col;
}

// --- Boxed Minus Drawable
fragment float4 mmBoxedMinusDrawable(RasterizerData in [[stage_in]],
                                     constant MM_BOXEDMENU *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
    uv -= float2( data->size / 2.0 + data->borderSize / 2.0 );
    
    // Main
    float2 d = abs( uv ) - data->size / 2 + data->round;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    
    // --- Lines
    
    float lineWidth = 2.5;
    float lineRound = 4.0;
    
    // --- Middle
    uv = in.textureCoordinate * data->size;
    uv -= data->size / 2.0;
    
    d = abs( uv ) -  float2( data->size.x / 3, lineWidth) + lineRound;
    dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - lineRound;
    col = mix( col,  float4( 0.957, 0.957, 0.957, 1 ), m4mFillMask( dist ) );
    
    return col;
}

/// Texture drawable
fragment float4 mmTextureDrawable(RasterizerData in [[stage_in]],
                                constant MM_TEXTURE *data [[ buffer(0) ]],
                                texture2d<half> inTexture [[ texture(1) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    float2 uv = in.textureCoordinate;// * data->screenSize;
    uv.y = 1 - uv.y;
    
    const half4 colorSample = inTexture.sample (textureSampler, uv );
        
    float4 sample = float4( colorSample );

    if (data->round > 0) {
        float2 uv = in.textureCoordinate * data->size;
        uv -= float2( data->size / 2.0 ) + data->roundingRect.xy;
        
        float2 d = abs( uv ) - data->roundingRect.zw + data->round;
        float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
        
        sample.w *= m4mFillMask(dist);
    }
    
    if (data->prem == 1) {
        return float4(sample.x / sample.w, sample.y / sample.w, sample.z / sample.w, sample.w);
    } else {
        return sample;
    }
}

/// Draw a text char
fragment float4 mmTextDrawable(RasterizerData in [[stage_in]],
                                constant MM_TEXT *data [[ buffer(0) ]],
                                texture2d<half> inTexture [[ texture(1) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    float2 uv = in.textureCoordinate;
    uv.y = 1 - uv.y;

    uv /= data->atlasSize / data->fontSize;
    uv += data->fontPos / data->atlasSize;

    const half4 colorSample = inTexture.sample (textureSampler, uv );
    
    float4 sample = float4( colorSample );
    
    float d = m4mMedian(sample.r, sample.g, sample.b) - 0.5;
    float w = clamp(d/fwidth(d) + 0.5, 0.0, 1.0);
    return float4( data->color.x, data->color.y, data->color.z, w * data->color.w );
}


#define M_PI 3.1415926535897932384626433832795

float3 getHueColor(float2 pos)
{
    float theta = 3.0 + 3.0 * atan2(pos.x, pos.y) / M_PI;
    
//    float3 color = float3(0.0);
    return clamp(abs(fmod(theta + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

float2 hsl2xy(float3 hsl)
{
    float h = hsl.r;
    float s = hsl.g;
    float l = hsl.b;
    float theta = 0;
    
    if(h==0.0){
        if(s==1.0){
            theta = 4.0-l;
        } else {
            theta = 2.0+s;
        }
    }else if(h==1.0){
        if(s==0.0){
            theta = l;
        } else {
            theta = 6.0-s;
        }
    }else{
        if(s==0.0){
            theta = 2.0-h;
        } else {
            theta = 4.0+h;
        }
    }
    
    theta = M_PI/6 * theta;
    return float2(cos(theta), sin(theta));
}

float3 rgb2hsl( float3 col )
{
    const float eps = 0.0000001;

    float minc = min( col.r, min(col.g, col.b) );
    float maxc = max( col.r, max(col.g, col.b) );
    float3  mask = step(col.grr,col.rgb) * step(col.bbg,col.rgb);
    float3 h = mask * (float3(0.0,2.0,4.0) + (col.gbr-col.brg)/(maxc-minc + eps)) / 6.0;
    return float3( fract( 1.0 + h.x + h.y + h.z ),              // H
                (maxc-minc)/(1.0-abs(minc+maxc-1.0) + eps),  // S
                (minc+maxc)*0.5 );                           // L
}

// --- ColorWheel Drawable
fragment float4 mmColorWheelDrawable(RasterizerData in [[stage_in]],
                               constant MM_COLORWHEEL *data [[ buffer(0) ]] )
{
    float2 uv = float2(2.0, -2.0) * (in.textureCoordinate * data->size - 0.5 * data->size) / data->size.y;

    float l = length(uv);

    l = 1.0 - abs((l - 0.875) * 8.0);
    l = clamp(l * data->size.y * 0.0625, 0.0, 1.0);
    
    float4 col = float4(l * getHueColor(uv), l);
    
    if (l < 0.75)
    {
        uv = uv / 0.75;
        
        float3 inhsl = data->color.xyz;//rgb2hsl(data->color.xyz);
        inhsl.x /= 360;

        float angle = ((inhsl.x * 360) - 180) * M_PI / 180;
        float2 mouse = float2( sin(angle), cos(angle) );

        float3 pickedHueColor = getHueColor(mouse);

        mouse = normalize(mouse);
        
        float sat = 1.5 - (dot(uv, mouse) + 0.5); // [0.0,1.5]
        
        if (sat < 1.5)
        {
            float h = sat / sqrt(3.0);
            float2 om = cross(float3(mouse, 0.0), float3(0.0, 0.0, 1.0)).xy;

            float lum = dot(uv, om);
            
            if (abs(lum) <= h)
            {
                l = clamp((h - abs(lum)) * data->size.y * 0.5, 0.0, 1.0) * clamp((1.5 - sat) / 1.5 * data->size.y * 0.5, 0.0, 1.0); // Fake antialiasing
                col = float4(l * mix(pickedHueColor, float3(0.5 * (lum + h) / h), sat / 1.5), l);
            }
        }
        
        //col.xyz = pickedHueColor;
    }
    
    col.w *= data->color.w;

    return col;
}

fragment float4 mmArcDrawable(RasterizerData in [[stage_in]],
                                      constant MM_ARC *data [[ buffer(0) ]] )
{
    float ra = data->r.x;
    float rb = data->r.y;
    
    float2 p = in.textureCoordinate * (ra+rb) * 2;
    p -= float2(ra + rb);
    
    float2 sca = float2(sin(data->sc.x), cos(data->sc.x));
    float2 scb = float2(sin(data->sc.y), cos(data->sc.y));

    p *= float2x2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
    float dist = sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
    
    float4 col = float4( data->color.x, data->color.y, data->color.z, m4mFillMask( dist ) );
    return col;
}
