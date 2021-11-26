//
//  Gizmo.metal
//  Shape-Z
//
//  Created by Markus Moenig on 23/1/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

#include <metal_stdlib>
#include "../Metal.h"

using namespace metal;

typedef struct
{
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
} RasterizerData;

float nodeFillMask(float dist)
{
    return clamp(-dist, 0.0, 1.0);
}

float nodeBorderMask(float dist, float width)
{
    return clamp(dist + width, 0.0, 1.0) - clamp(dist, 0.0, 1.0);
}

float nodeGradient_linear(float2 uv, float2 p1, float2 p2) {
    return clamp(dot(uv-p1,p2-p1)/dot(p2-p1,p2-p1),0.,1.);
}

float nodeEquilateralTriangle( float2 p )
{
    const float k = sqrt(3.0);
    
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x + k*p.y > 0.0 ) p = float2( p.x - k*p.y, -k*p.x - p.y )/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    return -length(p)*sign(p.y);
}

float nodeTriangleIsosceles( float2 p, float2 q )
{
    p.x = abs(p.x);
    
    float2 a = p - q*clamp( dot(p,q)/dot(q,q), 0.0, 1.0 );
    float2 b = p - q*float2( clamp( p.x/q.x, 0.0, 1.0 ), 1.0 );
    float s = -sign( q.y );
    float2 d = min( float2( dot(a,a), s*(p.x*q.y-p.y*q.x) ),
                 float2( dot(b,b), s*(p.y-q.y)  ));
    
    return -sqrt(d.x)*sign(d.y);
}

float2 nodeRotateCW(float2 pos, float angle)
{
    float ca = cos(angle), sa = sin(angle);
    return pos * float2x2(ca, -sa, sa, ca);
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

typedef struct
{
    float2 size;
    
} MODULO_PATTERN;

float IsGridLine(float2 fragCoord)
{
    float2 vPixelsPerGridSquare = float2(40.0, 40.0);
    float2 vScreenPixelCoordinate = fragCoord.xy;
    float2 vGridSquareCoords = fract(vScreenPixelCoordinate / vPixelsPerGridSquare);
    float2 vGridSquarePixelCoords = vGridSquareCoords * vPixelsPerGridSquare;
    float2 vIsGridLine = step(vGridSquarePixelCoords, float2(1.0));
    
    float fIsGridLine = max(vIsGridLine.x, vIsGridLine.y);
    return fIsGridLine;
}

fragment float4 nodeGridPattern(RasterizerData in [[stage_in]],
                                constant MODULO_PATTERN *data [[ buffer(0) ]] )
{
    
    float4 checkerColor1 = float4(0.110, 0.114, 0.118, 1.000);
    float4 checkerColor2 = float4(0.094, 0.094, 0.098, 1.000);
    
    float2 uv = in.textureCoordinate * data->size;
    uv -= float2( data->size / 2 );

    float grid = IsGridLine( uv );
    float4 col = mix(checkerColor2, checkerColor1, grid);
    
    return col;
}


fragment float4 drawNode(RasterizerData        in [[stage_in]],
                         constant NODE_DATA   *data [[ buffer(0) ]] )
{
    float4 color = float4( 0 ), finalColor = float4( 0 );
    float2 size = data->size;
    float scale = data->scale;
    const float borderRound = data->borderRound * scale;

    float4 borderColor = float4(0.282, 0.286, 0.290, 1.000);//float4(0.173, 0.173, 0.173, 1.000);
    const float4 selBorderColor = float4(0.953, 0.957, 0.961, 1.000);//float4(0.820, 0.820, 0.820, 1.000);
    
    const float borderSize = 2 * scale;
    const float tRadius = 7 * scale;
    const float tDiam = 14 * scale;
    const float tSpacing = 25 * scale;

    if ( data->selected == 2 ) {
        // Success
        borderColor = float4(0.192, 0.573, 0.478, 1.000);
    } else
    if ( data->selected == 3 ) {
        // Failure
        borderColor = float4(0.988, 0.129, 0.188, 1.000);
    } else
    if ( data->selected == 4 ) {
        // Running
        borderColor = float4(0.620, 0.506, 0.165, 1.000);
    }
    
    // Body
    float2 uv = in.textureCoordinate * ( data->size + float2( borderSize ) * 2 );
    float2 uvCopy = uv;

    uv -= float2( data->size / 2.0 + borderSize / 2.0 );

    // Whole Body
    float2 d = abs( uv ) - data->size / 2 + borderRound + 5 * scale;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - borderRound;
    
    // Inner Cutout
    uv.y += 16 * scale;
    float2 innerSize = data->size - float2(borderSize - 2, borderSize + 16 * scale * 2 - 2);
    d = abs( uv ) - innerSize / 2 + borderRound + 5 * scale;
    float innerDist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - borderRound;

    float2 point = in.textureCoordinate * data->size;
    point.y = data->size.y - point.y;

    if ( data->leftTerminalCount == 1 )
    {
        uv = uvCopy;
        uv -= float2( 7 * scale, size.y - data->leftTerminal.w );
        dist = max( dist, -(length( uv ) - tRadius) );
    }
    
    if ( data->topTerminalCount == 1 )
    {
        uv = uvCopy;
        uv -= float2( size.x / 2, size.y - data->topTerminal.w );
        dist = max( dist, -(length( uv ) - tRadius) );
    }
    
    for( int i = 0; i < data->rightTerminalCount; i += 1)
    {
        uv = uvCopy;
        uv -= float2( size.x - 4 * scale, size.y - data->rightTerminals[i].w );
        dist = max( dist, -(length( uv ) - tRadius) );
    }
    
    if ( data->bottomTerminalCount > 0 )
    {
        float left = (size.x - (data->bottomTerminalCount * tDiam + (data->bottomTerminalCount-1) * tSpacing)) / 2 + tRadius;
        for( int i = 0; i < data->bottomTerminalCount; i += 1)
        {
            uv = uvCopy;
            uv -= float2( left, 8 * scale );
            dist = max( dist, -(length( uv ) - tRadius) );
            
            left += tSpacing + tDiam;
        }
    }
    
    // Body Color (Brand)
    color = data->brandColor;
    finalColor = mix( finalColor, color, nodeFillMask( dist ) * color.w );
    
    // Inner Color
    color = float4(0.165, 0.169, 0.173, 1.000);
    finalColor = mix( finalColor, color, nodeFillMask( innerDist ) * color.w );
    
    color = data->selected == 1 ? selBorderColor : borderColor;
    finalColor = mix( finalColor, color, nodeBorderMask( dist, borderSize ) * color.w );
    
    // Right Terminal Bodies
    for( int i = 0; i < data->rightTerminalCount; i += 1)
    {
        uv = uvCopy;
        //uv -= float2( 7 * scale, size.y - data->leftTerminals[i].w );
        uv -= float2( size.x - 4 * scale, size.y - data->rightTerminals[i].w );
        dist = length( uv ) - tRadius;
        
        color = float4( data->rightTerminals[i].xyz, 1);
        finalColor = mix( finalColor, color, nodeFillMask( dist ) * color.w );
    }
    
    if ( data->topTerminalCount == 1 )
    {
        uv = uvCopy;
        uv -= float2( size.x / 2, size.y - data->topTerminal.w );
        dist = length( uv ) - tRadius;
        
        color = float4( data->topTerminal.xyz, 1);
        finalColor = mix( finalColor, color, nodeFillMask( dist ) * color.w );
    }
    
    if ( data->leftTerminalCount == 1 )
    {
        uv = uvCopy;
        //uv -= float2( size.x - 4 * scale, size.y - data->rightTerminal.w );
        uv -= float2( 7 * scale, size.y - data->leftTerminal.w );
        dist = length( uv ) - tRadius;
        
        color = float4( data->leftTerminal.xyz, 1);
        finalColor = mix( finalColor, color, nodeFillMask( dist ) * color.w );
    }
    
    if ( data->bottomTerminalCount > 0 )
    {
        float left = (size.x - (data->bottomTerminalCount * tDiam + (data->bottomTerminalCount-1) * tSpacing)) / 2 + tRadius;
        for( int i = 0; i < data->bottomTerminalCount; i += 1)
        {
            uv = uvCopy;
            uv -= float2( left, 8 * scale );
            dist = length( uv ) - tRadius;
            
            color = float4( data->bottomTerminals[i].xyz, 1);
            finalColor = mix( finalColor, color, nodeFillMask( dist ) * color.w );
            left += tSpacing + tDiam;
        }
    }
    
    return finalColor;
}
