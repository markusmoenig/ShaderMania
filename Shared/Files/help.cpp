


typedef struct
{
    float2              uv;         // UV coordinate 0..1
    float2              size;       // Viewport size
    float               time;       // Global time
    
    float4              outColor;   // The resulting RGBA color, set to (0,0,0,1) by default

    texture2d<float>    slot0;      // The 4 texture input slots
    texture2d<float>    slot1;
    texture2d<float>    slot2;
    texture2d<float>    slot3;
} DataIn;
