
/*
 * ShaderMania 1.5
 *
 * Nodes are shaders or images. The currently selected node is rendered in the preview. You can easily change
 * which shader is rendered by just selecting it. The selection state is saved with the project.
 *
 * You can add nodes from existing shaders from the Shader Library by clicking on the shader and selecting "Add to Project".
 *
 * For more information have a look at the Wiki at https://github.com/markusmoenig/ShaderMania/wiki
 *
 */

// Incoming Data structure

typedef struct
{
    float2              uv;         // UV coordinate 0..1
    float2              viewSize;   // Viewport size
    float2              fragCoord;  // uv * viewSize
    
    float               time;       // Global time in seconds
    unsigned int        frame;      // Frame number

    float4              outColor;   // The resulting RGBA color, set to (0,0,0,1) by default

    texture2d<float>    slot0;      // The 4 texture input slots
    texture2d<float>    slot1;
    texture2d<float>    slot2;
    texture2d<float>    slot3;
} Data;

// Variables with UI parameters, parameter data is stored and reset when the parameter name changes
// Up to 10 parameters per node / shader are supported

// Float slider parameter
float size = ParamFloat<UI: "Slider", name: "Parameter Name", min: 0, max: 1, default: 0.8>

// Float3 color picker parameter
float3 diskColor = ParamFloat3<UI: "Color", name: "Parameter Name", default: #ffffff>
 
// Url, ShaderMania will add https:// at the front automatically
ParamUrl<name: "Watch Tutorial", url: "url without https://">

// Input slots (up to 4 are supported per node)
texture2d<float> input = ParamInput<name: "Input Slot Name">

// To read from input slots
getLinearSample(texture2d<float>, float2 coord);
getNearestSample(texture2d<float>, float2 coord);
