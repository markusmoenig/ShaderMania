---
sidebar_position: 1
title: Shader format
---

# ShaderMania shader format

ShaderMania shaders are Metal fragment-style programs. Each shader provides a `mainImage` function that receives a mutable `Data` structure.

<a href="https://apps.apple.com/us/app/shadermania/id1541065830">
  <img src="/img/appstore.svg" alt="Download ShaderMania on the App Store" width="160" />
</a>

```cpp
void mainImage(thread Data &data)
{
    float2 uv = data.uv;
    data.outColor = float4(uv.x, uv.y, 0.0, 1.0);
}
```

## Incoming data

```cpp
typedef struct
{
    float2              uv;         // UV coordinate 0..1
    float2              viewSize;   // Viewport size
    float2              fragCoord;  // uv * viewSize

    float               time;       // Global time in seconds
    unsigned int        frame;      // Frame number

    float4              outColor;   // Resulting RGBA color, default (0,0,0,1)

    texture2d<float>    slot0;      // Texture input slots
    texture2d<float>    slot1;
    texture2d<float>    slot2;
    texture2d<float>    slot3;
} Data;
```

Write the final shader color to `data.outColor`.

## UI parameters

Parameter declarations create editable controls in ShaderMania. Parameter values are stored with the shader and reset when the parameter name changes. Up to 10 parameters per shader are supported.

### Float slider

```cpp
float size = ParamFloat<UI: "Slider", name: "Size", min: 0, max: 1, default: 0.8>
```

### Color picker

```cpp
float3 diskColor = ParamFloat3<UI: "Color", name: "Disk Color", default: #ffffff>
```

### URL button

ShaderMania adds `https://` automatically.

```cpp
ParamUrl<name: "Watch Tutorial", url: "example.com/tutorial">
```

## Texture inputs

Shaders can declare up to 4 named input slots.

```cpp
texture2d<float> input = ParamInput<name: "Input Slot Name">
```

Sample from texture inputs with the provided helpers:

```cpp
getLinearSample(texture2d<float>, float2 coord);
getNearestSample(texture2d<float>, float2 coord);
```

Example:

```cpp
void mainImage(thread Data &data)
{
    float4 source = getLinearSample(data.slot0, data.uv);
    data.outColor = source;
}
```
