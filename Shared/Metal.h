//
//  Metal.h
//  ShaderMania
//
//  Created by Markus Moenig on 25/8/20.
//

#ifndef Metal_h
#define Metal_h

#include <simd/simd.h>

typedef struct
{
    vector_float2   position;
    vector_float2   textureCoordinate;
} VertexUniform;

typedef struct
{
    vector_float2   screenSize;
    vector_float2   pos;
    vector_float2   size;
    float           globalAlpha;

} TextureUniform;

typedef struct
{
    vector_float4   fillColor;
    vector_float4   borderColor;
    float           radius;
    float           borderSize;
    float           rotation;
    float           onion;
    
    int             hasTexture;
    vector_float2   textureSize;
} DiscUniform;

typedef struct
{
    vector_float2   screenSize;
    vector_float2   pos;
    vector_float2   size;
    float           round;
    float           borderSize;
    vector_float4   fillColor;
    vector_float4   borderColor;
    float           rotation;
    float           onion;
    
    int             hasTexture;
    vector_float2   textureSize;

} BoxUniform;

typedef struct
{
    vector_float2   size;
    vector_float2   sp, ep;
    float           width, borderSize;
    vector_float4   fillColor;
    vector_float4   borderColor;
    
} LineUniform;

typedef struct
{
    vector_float2   atlasSize;
    vector_float2   fontPos;
    vector_float2   fontSize;
    vector_float4   color;
} TextUniform;

typedef struct
{
    float           time;
    unsigned int    frame;    
} MetalData;

// MetalMania


typedef struct
{
    vector_float2 position;
    vector_float2 textureCoordinate;
} MM_Vertex;

typedef struct
{
    vector_float4 fillColor;
    vector_float4 borderColor;
    float radius, borderSize;
} MM_SPHERE;

typedef struct
{
    vector_float2 size;
    vector_float2 sp, ep;
    float width, borderSize;
    vector_float4 fillColor;
    vector_float4 borderColor;
    
} MM_LINE;

typedef struct
{
    vector_float2 size;
    vector_float2 sp, cp, ep;
    float width, borderSize;
    float fill1, fill2;
    vector_float4 fillColor;
    vector_float4 borderColor;
    
} MM_SPLINE;

typedef struct
{
    vector_float2 size;
    float round, borderSize;
    vector_float4 fillColor;
    vector_float4 borderColor;

} MM_BOX;

typedef struct
{
    vector_float2 size;
    float round, borderSize;
    vector_float4 fillColor;
    vector_float4 borderColor;
    vector_float4 rotation;

} MM_ROTATEDBOX;

typedef struct
{
    vector_float2 size;
    float round, borderSize;
    vector_float4 fillColor;
    vector_float4 borderColor;
    
} MM_BOXEDMENU;

typedef struct
{
    vector_float2 size;
    float round, borderSize;
    vector_float2 uv1;
    vector_float2 uv2;
    vector_float4 gradientColor1;
    vector_float4 gradientColor2;
    vector_float4 borderColor;
    
} MM_BOX_GRADIENT;

typedef struct
{
    vector_float2 screenSize;
    vector_float2 pos;
    vector_float2 size;
    float  prem;
    float  round;
    vector_float4 roundingRect;

} MM_TEXTURE;

typedef struct
{
    vector_float2 atlasSize;
    vector_float2 fontPos;
    vector_float2 fontSize;
    vector_float4 color;
} MM_TEXT;

typedef struct
{
    vector_float2 size;
    vector_float4 color;
    
} MM_COLORWHEEL;

typedef struct
{
    vector_float2 sc;
    vector_float2 r;
    vector_float4 color;
    
} MM_ARC;

typedef vector_float2 float2;
typedef vector_float4 float4;

typedef struct
{
    float2   size;
    float    selected;
    float    hoverIndex;
    float    scale;
    float    borderRound;
    
    float4   hasIcons1;
    
    float    leftTerminalCount;
    float    topTerminalCount;
    float    rightTerminalCount;
    float    bottomTerminalCount;
    
    float4   brandColor;

    float4   rightTerminals[10];
    
    float4   leftTerminal;
    float4   topTerminal;
    float4   bottomTerminals[5];
    
} NODE_DATA;

#endif /* Metal_h */
