

                                                                         
typedef struct
{
    float2              uv;         // UV coordinate 0..1
    float2              size;       // Viewport size
    float               time;       // Global time

    texture2d<float>    slot0;
    texture2d<float>    slot1;
    texture2d<float>    slot2;
    texture2d<float>    slot3;
} DataIn;
