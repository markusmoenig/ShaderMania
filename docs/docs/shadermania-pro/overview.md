---
sidebar_position: 1
title: Overview
---

# ShaderMania Pro overview

ShaderMania Pro projects are timeline scenes. Tracks can contain shaders, SDF objects, analytical objects, materials, images, lights, cameras, renderers, environments, and post effects. A project is built into a render graph and rendered progressively with the path tracer.

<a href="https://apps.apple.com/th/app/shadermania-pro/id6764767974?mt=12">
  <img src="/img/appstore.svg" alt="Download ShaderMania Pro on the App Store" width="160" />
</a>

## Timeline tracks

Each visible timeline item contributes to the current frame:

- **SDF objects** provide distance functions and optional normal or surface sampling code.
- **Analytical objects** provide built-in shapes such as spheres and planes.
- **Materials** define OpenPBR-style material parameters and optional procedural material code.
- **Images** can be sampled by shaders, SDFs, displacement functions, and material functions.
- **Shaders** can run before the renderer or after it as post effects.
- **Lights, cameras, renderers, and environments** define how the scene is viewed and lit.

Timeline track numbers are meaningful in code. For example, SDF objects can assign material tracks directly:

```cpp
hit.materialSlot0 = 2u;
hit.materialSlot1 = 3u;
```

If a material track does not exist at the requested frame, ShaderMania Pro uses an empty material.

## SDF objects

An SDF object usually implements a distance function:

```cpp
SDFHit distance(float3 p)
{
    float radius = ParamFloat<ui:Slider,name:Radius,min:0.001,max:3,default:1>;

    SDFHit hit;
    hit.distance = length(p - SMP_Position) - radius;
    hit.materialSlot0 = 2u;
    hit.objectId = SMP_ObjectId;
    return hit;
}
```

Object parameters are declared in the source. Removing the parameter from the source removes the UI control from the object.

## Procedural materials

Materials can be edited through normal material parameters, or through material functions that react to the actual hit point. This makes it possible to vary color, roughness, metallic weight, displacement, or emission based on world position, normal, ray direction, UVs, object IDs, or image samples.

Material displacement is evaluated as real SDF displacement during ray marching, so it affects silhouettes and intersections when used by an SDF object.

## Images

Image tracks can be sampled from shader, object, displacement, and material code by track number. Out-of-range image indices return black and report a zero size.

```cpp
float4 color = SMP_Image(5u, uv);
float2 size = SMP_ImageSize(5u);
```

ShaderMania Pro currently supports up to 4 timeline images.

## Post effects

Post shaders can access renderer buffers such as:

- beauty
- albedo
- normal
- depth
- UV
- position
- object/material IDs

This supports depth-aware, normal-aware, and material-aware post processing.

## Time and accumulation

ShaderMania Pro separates timeline time from progressive accumulation:

- `u.frame` is the current timeline frame.
- `u.time` is the current timeline time in seconds.
- `u.accumulationFrame` is the progressive render sample frame.

Use `u.frame` or `u.time` for animation that should follow the timeline. Use `u.accumulationFrame` only for sampling variation during progressive rendering.

## Limits

ShaderMania Pro currently supports:

- 8 material tracks available to renderer hooks.
- 8 SDF object slots.
- 4 light slots.
- 4 image tracks.
- 8 pre-render shader layers.
- 8 post-render shader layers.

These limits keep generated Metal source and compile times practical while still covering substantial procedural scenes.

## Export and sharing

ShaderMania Pro can export still images and frame-accurate video. Projects and selected timeline nodes can be saved to the private asset library, exported as asset files, or published to the public ShaderMania library.
