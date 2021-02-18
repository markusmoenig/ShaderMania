
/*
 * ShaderMania 1.5
 *
 * To learn more about shader development:
 *
 * The Book Of Shaders                  https://thebookofshaders.com
 * The Art of Code YouTube Channel      https://www.youtube.com/channel/UCcAlTqd9zID6aNX3TzwxJXg
 *
 */

// Incoming Data structure

typedef struct
{
    float2              uv;         // UV coordinate 0..1
    float2              viewSize;   // Viewport size
    float2              fragCoord;  // uv * viewSize
    
    float               time;       // Global time
    unsigned int        frame;      // Frame number

    float4              outColor;   // The resulting RGBA color, set to (0,0,0,1) by default

    texture2d<float>    slot0;      // The 4 texture input slots
    texture2d<float>    slot1;
    texture2d<float>    slot2;
    texture2d<float>    slot3;
} Data;

// Variables with UI parameters, parameter data is stored and reset when the parameter name changes
// Up to 10 parameters per node are supported

// Float slider parameter
float size = ParamFloat<UI: "Slider", name: "Disk Size", min: 0, max: 1, default: 0.8>

// Float3 color picker parameter
float3 diskColor = ParamFloat3<UI: "Color", name: "Disk Color", default: #ffffff>
 
// Url, ShaderMania will add https:// at the front automatically
ParamUrl<name: "Watch Tutorial", url: "url without https://">

// Input slots (up to 4 are supported per node)
texture2d<float> input = ParamInput<name: "Input">

// To read from input slots
getLinearSample(texture2d<float>, float2 coord);
getNearestSample(texture2d<float>, float2 coord);
