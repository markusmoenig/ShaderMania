//
//  MMDrawable.swift
//  Framework
//
//  Created by Markus Moenig on 04.01.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

protocol MMDrawable
{
//    static func size() -> Int
    
    var state : MTLRenderPipelineState! { get set }
    
    init( _ renderer : MMRenderer )
}

/// Draws a sphere
class MMDrawSphere : MMDrawable
{
    let mmRenderer : MMRenderer
    var state : MTLRenderPipelineState!

    required init( _ renderer : MMRenderer )
    {
        let function = renderer.defaultLibrary.makeFunction( name: "mmDiscDrawable" )
        state = renderer.createNewPipelineState( function! )
        mmRenderer = renderer
    }
    
    func draw( x: Float, y: Float, radius: Float, borderSize: Float, fillColor: SIMD4<Float>, borderColor: SIMD4<Float> = SIMD4<Float>(0,0,0,0))
    {
        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
        let settings: [Float] = [
            fillColor.x, fillColor.y, fillColor.z, fillColor.w,
            borderColor.x, borderColor.y, borderColor.z, borderColor.w,
            radius * scaleFactor, borderSize * scaleFactor,
            0, 0
        ];
        
        let renderEncoder = mmRenderer.renderEncoder!
        
        let vertexBuffer = mmRenderer.createVertexBuffer( MMRect( x - borderSize / 2, y - borderSize / 2, radius * 2 + borderSize, radius * 2 + borderSize, scale: scaleFactor ) )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        
        renderEncoder.setRenderPipelineState( state! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws a Box
class MMDrawBox : MMDrawable
{
    let mmRenderer  : MMRenderer
    var state       : MTLRenderPipelineState!
    let rotatedState: MTLRenderPipelineState!

    required init( _ renderer : MMRenderer )
    {
        var function = renderer.defaultLibrary.makeFunction( name: "mmBoxDrawable" )
        state = renderer.createNewPipelineState( function! )
        
        function = renderer.defaultLibrary.makeFunction( name: "mmRotatedBoxDrawable" )
        rotatedState = renderer.createNewPipelineState( function! )
        
        mmRenderer = renderer
    }
    
    func draw( x: Float, y: Float, width: Float, height: Float, round: Float = 0, borderSize: Float = 0, fillColor: SIMD4<Float>, borderColor: SIMD4<Float> = SIMD4<Float>(repeating: 0), fragment: MMFragment? = nil )
    {
        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
        let settings: [Float] = [
            width * scaleFactor, height * scaleFactor,
            round, borderSize * scaleFactor,
            fillColor.x, fillColor.y, fillColor.z, fillColor.w,
            borderColor.x, borderColor.y, borderColor.z, borderColor.w
        ];
        
        let rect = MMRect(x - borderSize, y - borderSize, width + 2*borderSize, height + 2*borderSize, scale: scaleFactor )
        let renderEncoder = fragment == nil ? mmRenderer.renderEncoder! : fragment!.renderEncoder!
        let vertexBuffer = fragment == nil ? mmRenderer.createVertexBuffer( rect ) : fragment!.createVertexBuffer( rect )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        renderEncoder.setRenderPipelineState( state! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    func drawRotated( x: Float, y: Float, width: Float, height: Float, round: Float = 0, borderSize: Float = 0, fillColor: SIMD4<Float>, borderColor: SIMD4<Float> = SIMD4<Float>(repeating: 0), rotation: Float )
    {
        let border : Float = 20

        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
        let settings: [Float] = [
            width * scaleFactor, height * scaleFactor,
            round, borderSize * scaleFactor,
            fillColor.x, fillColor.y, fillColor.z, fillColor.w,
            borderColor.x, borderColor.y, borderColor.z, borderColor.w,
            rotation, 0, 0, 0
        ];
        
        let renderEncoder = mmRenderer.renderEncoder!
        
        let vertexBuffer = mmRenderer.createVertexBuffer( MMRect(x - borderSize - border / 2, y - borderSize, width + 2*borderSize, height + 2*borderSize, scale: scaleFactor ) )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        
        renderEncoder.setRenderPipelineState( rotatedState! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws a Box Pattern
class MMDrawBoxPattern : MMDrawable
{
    let mmRenderer : MMRenderer
    var state : MTLRenderPipelineState!
    
    required init( _ renderer : MMRenderer )
    {
        let function = renderer.defaultLibrary.makeFunction( name: "mmBoxPatternDrawable" )
        state = renderer.createNewPipelineState( function! )
        mmRenderer = renderer
    }
    
    func draw( x: Float, y: Float, width: Float, height: Float, round: Float = 0, borderSize: Float = 0, fillColor: SIMD4<Float>, borderColor: SIMD4<Float> = SIMD4<Float>(repeating: 0) )
    {
        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
        let settings: [Float] = [
            width * scaleFactor, height * scaleFactor,
            round, borderSize * scaleFactor,
            fillColor.x, fillColor.y, fillColor.z, fillColor.w,
            borderColor.x, borderColor.y, borderColor.z, borderColor.w
        ];
        
        let renderEncoder = mmRenderer.renderEncoder!
        
        let vertexBuffer = mmRenderer.createVertexBuffer( MMRect(x - borderSize, y - borderSize, width + 2*borderSize, height + 2*borderSize, scale: scaleFactor ) )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        
        renderEncoder.setRenderPipelineState( state! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws a line
class MMDrawLine : MMDrawable
{
    let mmRenderer : MMRenderer
    var state : MTLRenderPipelineState!
    
    required init( _ renderer : MMRenderer )
    {
        let function = renderer.defaultLibrary.makeFunction( name: "mmLineDrawable" )
        state = renderer.createNewPipelineState( function! )
        mmRenderer = renderer
    }
    
    func draw( sx: Float, sy: Float, ex: Float, ey: Float, radius: Float = 2, borderSize: Float = 0, fillColor: SIMD4<Float>, borderColor: SIMD4<Float> = SIMD4<Float>(repeating: 0) )
    {
        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
    
        let minX = min(sx, ex)
        let maxX = max(sx, ex)
        let minY = min(sy, ey)
        let maxY = max(sy, ey)
        
        let areaWidth : Float = maxX - minX + borderSize + radius * 2
        let areaHeight : Float = maxY - minY + borderSize + radius * 2
        
        let middleX : Float = (sx + ex) / 2
        let middleY : Float = (sy + ey) / 2
        
        let settings: [Float] = [
            areaWidth * scaleFactor, areaHeight * scaleFactor,
            (sx - middleX) * scaleFactor, (middleY - sy) * scaleFactor,
            (ex - middleX) * scaleFactor, (middleY - ey) * scaleFactor,
            radius * scaleFactor, borderSize * scaleFactor,
            fillColor.x, fillColor.y, fillColor.z, fillColor.w,
            borderColor.x, borderColor.y, borderColor.z, borderColor.w
        ];

        let renderEncoder = mmRenderer.renderEncoder!

        let vertexBuffer = mmRenderer.createVertexBuffer( MMRect( minX - borderSize / 2, minY - borderSize / 2, areaWidth, areaHeight, scale: scaleFactor ) )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        
        renderEncoder.setRenderPipelineState( state! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws a Spline
class MMDrawSpline : MMDrawable
{
    let mmRenderer : MMRenderer
    var state : MTLRenderPipelineState!
    
    required init( _ renderer : MMRenderer )
    {
        let function = renderer.defaultLibrary.makeFunction( name: "mmSplineDrawable" )
        state = renderer.createNewPipelineState( function! )
        mmRenderer = renderer
    }
    
    func draw( sx: Float, sy: Float, cx: Float, cy: Float, ex: Float, ey: Float, radius: Float = 2, borderSize: Float = 0, fillColor: SIMD4<Float>, borderColor: SIMD4<Float> = SIMD4<Float>(repeating: 0) )
    {
        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
        
        let minX = min(sx, ex)
        let maxX = max(sx, ex)
        let minY = min(sy, ey)
        let maxY = max(sy, ey)
        
        let areaWidth : Float = maxX - minX + borderSize + radius * 2 + 100 * scaleFactor
        let areaHeight : Float = maxY - minY + borderSize + radius * 2 + 100 * scaleFactor
        
        let middleX : Float = (sx + ex) / 2 + 50 * scaleFactor
        let middleY : Float = (sy + ey) / 2 + 50 * scaleFactor
        
        let settings: [Float] = [
            areaWidth * scaleFactor, areaHeight * scaleFactor,
            (sx - middleX) * scaleFactor, (middleY - sy) * scaleFactor,
            (cx - middleX) * scaleFactor, (middleY - cy) * scaleFactor,
            (ex - middleX) * scaleFactor, (middleY - ey) * scaleFactor,
            radius * scaleFactor, borderSize * scaleFactor,
            0, 0,
            fillColor.x, fillColor.y, fillColor.z, fillColor.w,
            borderColor.x, borderColor.y, borderColor.z, borderColor.w
        ];
        
        let renderEncoder = mmRenderer.renderEncoder!
        
        let vertexBuffer = mmRenderer.createVertexBuffer( MMRect( minX - borderSize / 2, minY - borderSize / 2, areaWidth, areaHeight, scale: scaleFactor ) )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        
        renderEncoder.setRenderPipelineState( state! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws a box gradient
class MMDrawBoxGradient : MMDrawable
{
    let mmRenderer : MMRenderer
    var state : MTLRenderPipelineState!
    
    required init( _ renderer : MMRenderer )
    {
        let function = renderer.defaultLibrary.makeFunction( name: "mmBoxGradientDrawable" )
        state = renderer.createNewPipelineState( function! )
        mmRenderer = renderer
    }
    
    func draw( x: Float, y: Float, width: Float, height: Float, round: Float, borderSize: Float, uv1: vector_float2, uv2: vector_float2, gradientColor1: vector_float4, gradientColor2: vector_float4, borderColor: vector_float4 )
    {
        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
        let settings: [Float] = [
            width * scaleFactor, height * scaleFactor,
            round, borderSize * scaleFactor,
            uv1.x, uv1.y,
            uv2.x, uv2.y,
            gradientColor1.x, gradientColor1.y, gradientColor1.z, 1,
            gradientColor2.x, gradientColor2.y, gradientColor2.z, 1,
            borderColor.x, borderColor.y, borderColor.z, borderColor.w
        ];
        
        let renderEncoder = mmRenderer.renderEncoder!
        
        let vertexBuffer = mmRenderer.createVertexBuffer( MMRect( x - borderSize / 2, y - borderSize / 2, width + borderSize, height + borderSize, scale: scaleFactor ) )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        
        renderEncoder.setRenderPipelineState( state! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws a box with three lines inside representing a menu
class MMDrawBoxedMenu : MMDrawable
{
    let mmRenderer : MMRenderer
    var state : MTLRenderPipelineState!
    
    required init( _ renderer : MMRenderer )
    {
        let function = renderer.defaultLibrary.makeFunction( name: "mmBoxedMenuDrawable" )
        state = renderer.createNewPipelineState( function! )
        mmRenderer = renderer
    }
    
    func draw( x: Float, y: Float, width: Float, height: Float, round: Float, borderSize: Float, fillColor: vector_float4, borderColor: vector_float4 )
    {
        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
        let settings: [Float] = [
            width * scaleFactor, height * scaleFactor,
            round, borderSize * scaleFactor,
            fillColor.x, fillColor.y, fillColor.z, fillColor.w,
            borderColor.x, borderColor.y, borderColor.z, borderColor.w
        ];
        
        let renderEncoder = mmRenderer.renderEncoder!
        
        let vertexBuffer = mmRenderer.createVertexBuffer( MMRect( x - borderSize / 2, y - borderSize / 2, width + borderSize, height + borderSize, scale: scaleFactor ) )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        
        renderEncoder.setRenderPipelineState( state! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws a box with three lines inside representing a menu
class MMDrawBoxedShape : MMDrawable
{
    let mmRenderer  : MMRenderer
    var state       : MTLRenderPipelineState!
    var minusState  : MTLRenderPipelineState!

    enum Shape {
        case Plus, Minus
    }
    
    required init( _ renderer : MMRenderer )
    {
        var function = renderer.defaultLibrary.makeFunction( name: "mmBoxedPlusDrawable" )
        state = renderer.createNewPipelineState( function! )
        function = renderer.defaultLibrary.makeFunction( name: "mmBoxedMinusDrawable" )
        minusState = renderer.createNewPipelineState( function! )
        mmRenderer = renderer
    }
    
    func draw( x: Float, y: Float, width: Float, height: Float, round: Float, borderSize: Float, fillColor: SIMD4<Float>, borderColor: SIMD4<Float>, shape: Shape )
    {
        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
        let settings: [Float] = [
            width * scaleFactor, height * scaleFactor,
            round, borderSize * scaleFactor,
            fillColor.x, fillColor.y, fillColor.z, fillColor.w,
            borderColor.x, borderColor.y, borderColor.z, borderColor.w
        ];
        
        let renderEncoder = mmRenderer.renderEncoder!
        
        let vertexBuffer = mmRenderer.createVertexBuffer( MMRect( x - borderSize / 2, y - borderSize / 2, width + borderSize, height + borderSize, scale: scaleFactor ) )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        
        if shape == .Plus {
            renderEncoder.setRenderPipelineState( state! )
        } else
        if shape == .Minus {
            renderEncoder.setRenderPipelineState( minusState! )
        }
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws a texture
class MMDrawTexture : MMDrawable
{
    let mmRenderer : MMRenderer
    var state : MTLRenderPipelineState!
    var statePrem : MTLRenderPipelineState!

    required init( _ renderer : MMRenderer )
    {
        let function = renderer.defaultLibrary.makeFunction( name: "mmTextureDrawable" )
        state = renderer.createNewPipelineState( function! )
        mmRenderer = renderer
    }
    
    func draw( _ texture: MTLTexture, x: Float, y: Float, zoom: Float = 1, fragment: MMFragment? = nil, prem: Bool = false, round: Float = 0, roundingRect: SIMD4<Float> = SIMD4<Float>(0,0,0,0))
    {
        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
        let width : Float = Float(texture.width)
        let height: Float = Float(texture.height)

        let settings: [Float] = [
            mmRenderer.width, mmRenderer.height,
            x, y,
            width * scaleFactor, height * scaleFactor,
            prem == true ? 1 : 0, round,
            roundingRect.x, roundingRect.y, roundingRect.z, roundingRect.w
        ];
        
        let renderEncoder = fragment == nil ? mmRenderer.renderEncoder! : fragment!.renderEncoder!

        let vertexBuffer = fragment == nil ?
            mmRenderer.createVertexBuffer( MMRect( x, y, width/zoom, height/zoom, scale: scaleFactor ) )
            : fragment!.createVertexBuffer( MMRect( x, y, width/zoom, height/zoom, scale: scaleFactor ) )

        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 1)
        
        renderEncoder.setRenderPipelineState(state!)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws custom code
class MMDrawCustomState : MMDrawable
{
    let mmRenderer : MMRenderer
    var state      : MTLRenderPipelineState!
    
    required init( _ renderer : MMRenderer )
    {
        mmRenderer = renderer
    }
    
    /// Create a state for the given custom code
    func createState(source: String, name: String) -> MTLRenderPipelineState?
    {
        var library : MTLLibrary
        do {
            let header = """

                            #include <metal_stdlib>
                            #include <simd/simd.h>
                            using namespace metal;

                            typedef struct
                            {
                                float2 size;
                                float  hover, fill;
                            } MM_CUSTOMSTATE_DATA;

                            float m4mFillMask(float dist)
                            {
                                return clamp(-dist, 0.0, 1.0);
                            }

                            float m4mBorderMask(float dist, float width)
                            {
                                return clamp(dist + width, 0.0, 1.0) - clamp(dist, 0.0, 1.0);
                            }

                            typedef struct
                            {
                                float4 clipSpacePosition [[position]];
                                float2 textureCoordinate;
                            } RasterizerData;

                        """
            library = try mmRenderer.mmView.device!.makeLibrary( source: header + source, options: nil )
        } catch
        {
            print( "MMDrawCustomState: Make Library Failed" )
            print( error )
            return nil
        }
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm;
        
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        let state : MTLRenderPipelineState?
        pipelineStateDescriptor.fragmentFunction = library.makeFunction( name: name )
        pipelineStateDescriptor.vertexFunction = mmRenderer.defaultLibrary.makeFunction( name: "m4mQuadVertexShader" )

        do {
            state = try mmRenderer.mmView.device!.makeRenderPipelineState( descriptor: pipelineStateDescriptor )
        } catch {
            print( "MMDrawCustomState makeRenderPipelineState failed" )
            return nil
        }

        return state
    }
    
    func draw( _ state: MTLRenderPipelineState, x: Float, y: Float, width: Float, height: Float, zoom: Float = 1 )
    {
        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
        
        let settings: [Float] = [
            width, height,
            0, 0
        ];
        
        let renderEncoder = mmRenderer.renderEncoder!
        
        let vertexBuffer = mmRenderer.createVertexBuffer( MMRect( x, y, width/zoom, height/zoom, scale: scaleFactor ) )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        
        renderEncoder.setRenderPipelineState( state )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Class for storing the MTLBuffers for a single char
class MMCharBuffer
{
    let vertexBuffer    : MTLBuffer
    let dataBuffer      : MTLBuffer
    
    init( vertexBuffer: MTLBuffer, dataBuffer: MTLBuffer )
    {
        self.vertexBuffer = vertexBuffer
        self.dataBuffer = dataBuffer
    }
}

/// Class for storing a textbuffer which consists of an array of MMCharBuffers and the text position
class MMTextBuffer
{
    var chars                   : [MMCharBuffer]
    var x, y                    : Float
    var viewWidth, viewHeight   : Float

    init(chars: [MMCharBuffer], x: Float, y: Float, viewWidth: Float, viewHeight: Float)
    {
        self.chars = chars
        self.x = x
        self.y = y
        self.viewWidth = viewWidth
        self.viewHeight = viewHeight
    }
}

/// Draws text
class MMDrawText : MMDrawable
{
    let mmRenderer : MMRenderer
    var state : MTLRenderPipelineState!
    
    required init( _ renderer : MMRenderer )
    {
        let function = renderer.defaultLibrary.makeFunction( name: "mmTextDrawable" )
        state = renderer.createNewPipelineState( function! )
        mmRenderer = renderer
    }
    
    @discardableResult func drawChar( _ font: MMFont, char: BMChar, x: Float, y: Float, color: SIMD4<Float>, scale: Float = 1.0, fragment: MMFragment? = nil) -> MMCharBuffer
    {
        let scaleFactor : Float = fragment == nil ? mmRenderer.mmView.scaleFactor : 2
        let adjScale : Float = scale / 2
        
        let textSettings: [Float] = [
            Float(font.atlas!.width) * scaleFactor, Float(font.atlas!.height) * scaleFactor,
            char.x * scaleFactor, char.y * scaleFactor,
            char.width * scaleFactor, char.height * scaleFactor,
            0,0,
            color.x, color.y, color.z, color.w,
        ];
                    
        let renderEncoder = fragment == nil ? mmRenderer.renderEncoder! : fragment!.renderEncoder!

        let vertexBuffer = fragment == nil ?
            mmRenderer.createVertexBuffer( MMRect( x, y, char.width * adjScale, char.height * adjScale, scale: scaleFactor) )
            : fragment!.createVertexBuffer( MMRect( x, y, char.width * adjScale, char.height * adjScale, scale: scaleFactor) )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let textData = mmRenderer.device.makeBuffer(bytes: textSettings, length: textSettings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(textData, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(font.atlas, index: 1)
        
        renderEncoder.setRenderPipelineState( state! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        return MMCharBuffer(vertexBuffer: vertexBuffer!, dataBuffer: textData)
    }
    
    @discardableResult func drawText( _ font: MMFont, text: String, x: Float, y: Float, scale: Float = 1.0, color: SIMD4<Float> = SIMD4<Float>(repeating: 1), textBuffer: MMTextBuffer? = nil, fragment: MMFragment? = nil ) -> MMTextBuffer?
    {
        let adjScale : Float = scale / 2

        if textBuffer != nil && textBuffer!.x == x && textBuffer!.y == y && textBuffer!.viewWidth == mmRenderer.width && textBuffer!.viewHeight == mmRenderer.height {
            let renderEncoder = mmRenderer.renderEncoder!
            renderEncoder.setRenderPipelineState( state! )
            renderEncoder.setFragmentTexture(font.atlas, index: 1)
            for c in textBuffer!.chars {
                renderEncoder.setVertexBuffer(c.vertexBuffer, offset: 0, index: 0)
                renderEncoder.setFragmentBuffer(c.dataBuffer, offset: 0, index: 0)
                
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            }
            return textBuffer
        } else {
            var posX = x
            var array : [MMCharBuffer] = []

            for c in text {
                let bmChar = font.getItemForChar( c )
                if bmChar != nil {
                    let char = drawChar( font, char: bmChar!, x: posX + bmChar!.xoffset * adjScale, y: y + bmChar!.yoffset * adjScale, color: color, scale: scale, fragment: fragment)
                    array.append(char)
                    //print( bmChar?.char, bmChar?.x, bmChar?.y, bmChar?.width, bmChar?.height)
                    posX += bmChar!.xadvance * adjScale;
                
                }
            }
        
            return MMTextBuffer(chars:array, x: x, y: y, viewWidth: mmRenderer.width, viewHeight: mmRenderer.height)
        }
    }
    
    @discardableResult func drawTextCentered( _ font: MMFont, text: String, x: Float, y: Float, width: Float, height: Float, scale: Float = 1.0, color: SIMD4<Float> = SIMD4<Float>(repeating: 1), textBuffer: MMTextBuffer? = nil, fragment: MMFragment? = nil ) -> MMTextBuffer?
    {
        let rect = font.getTextRect(text: text, scale: scale)

        let drawX = x + (width - rect.width) / 2
        let drawY = y + (height - rect.height) / 2
        return drawText(font, text: text, x: drawX, y: drawY, scale: scale, color: color, textBuffer: textBuffer)
    }
    
    @discardableResult func drawTextCenteredY( _ font: MMFont, text: String, x: Float, y: Float, width: Float, height: Float, scale: Float = 1.0, color: SIMD4<Float> = SIMD4<Float>(repeating: 1), textBuffer: MMTextBuffer? = nil, fragment: MMFragment? = nil ) -> MMTextBuffer?
    {
        let rect = font.getTextRect(text: text, scale: scale)
        
        let drawX = x
        let drawY = y + (height - rect.height) / 2
        return drawText(font, text: text, x: drawX, y: drawY, scale: scale, color: color, textBuffer: textBuffer)
    }
}

/// Draws a Color Wheel
class MMDrawColorWheel : MMDrawable
{
    let mmRenderer : MMRenderer
    var state : MTLRenderPipelineState!
    
    required init( _ renderer : MMRenderer )
    {
        let function = renderer.defaultLibrary.makeFunction( name: "mmColorWheelDrawable" )
        state = renderer.createNewPipelineState( function! )
        mmRenderer = renderer
    }
    
    func draw( x: Float, y: Float, width: Float, height: Float, color: SIMD4<Float> )
    {
        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
        let settings: [Float] = [
            width * scaleFactor, height * scaleFactor,
            0, 0,
            color.x, color.y, color.z, color.w
        ];
                
        let renderEncoder = mmRenderer.renderEncoder!
        
        let vertexBuffer = mmRenderer.createVertexBuffer( MMRect( x, y, width, height, scale: scaleFactor ) )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        
        renderEncoder.setRenderPipelineState( state! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws an arc
class MMDrawArc : MMDrawable
{
    let mmRenderer : MMRenderer
    var state : MTLRenderPipelineState!
    
    required init( _ renderer : MMRenderer )
    {
        let function = renderer.defaultLibrary.makeFunction( name: "mmArcDrawable" )
        state = renderer.createNewPipelineState( function! )
        mmRenderer = renderer
    }
    
    func draw( x: Float, y: Float, sca: Float, scb: Float, ra: Float, rb: Float, fillColor: SIMD4<Float>)
    {
        let scaleFactor : Float = mmRenderer.mmView.scaleFactor
        let settings: [Float] = [
            sca, scb,
            ra * scaleFactor, rb,
            fillColor.x, fillColor.y, fillColor.z, fillColor.w,
        ];
        
        let renderEncoder = mmRenderer.renderEncoder!
        
        let vertexBuffer = mmRenderer.createVertexBuffer( MMRect( x, y, ra * 2 + rb, ra * 2 + rb, scale: scaleFactor ) )
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let buffer = mmRenderer.device.makeBuffer(bytes: settings, length: settings.count * MemoryLayout<Float>.stride, options: [])!
        
        renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 0)
        
        renderEncoder.setRenderPipelineState( state! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}
