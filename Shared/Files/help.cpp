
// ShaderMania 1.0

// To learn more about shader development:

// The Book Of Shaders                  https://thebookofshaders.com
// The Art of Code YouTube Channel      https://www.youtube.com/channel/UCcAlTqd9zID6aNX3TzwxJXg

// Incoming Data structure

typedef struct
{
    float2              uv;         // UV coordinate 0..1
    float2              size;       // Viewport size
    float               time;       // Global time
    unsigned int        frame;      // Frame number

    float4              outColor;   // The resulting RGBA color, set to (0,0,0,1) by default

    texture2d<float>    slot0;      // The 4 texture input slots
    texture2d<float>    slot1;
    texture2d<float>    slot2;
    texture2d<float>    slot3;
} Data;

/*
 *
 * To read from a texture slot:
 *
 *  constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
 *
 *  float4 sample = data.slot0.sample(textureSampler, data.uv);
 *
 */
