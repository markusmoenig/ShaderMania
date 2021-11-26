//
//  Renderer.swift
//  Framework
//
//  Created by Markus Moenig on 01.01.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation

import Metal
import MetalKit

class MMRenderer : NSObject, MTKViewDelegate {
    
    let device          : MTLDevice
    let commandQueue    : MTLCommandQueue
    
    var renderPipelineState : MTLRenderPipelineState!

    var outputTexture   : MTLTexture!
    
    var viewportSize    : vector_uint2
    
    let pipelineStateDescriptor : MTLRenderPipelineDescriptor
    var renderEncoder   : MTLRenderCommandEncoder!
    
    let defaultLibrary  : MTLLibrary
    
    let mmView          : MMView
    var vertexBuffer    : MTLBuffer?
    
    var width           : Float!
    var height          : Float!
    
    var cWidth          : Float!
    var cHeight         : Float!
    
    var clipRects       : [MMRect] = []
    
    var currentRenderEncoder: MTLRenderCommandEncoder?
    
    init?( _ view: MMView ) {
        mmView = view
        device = mmView.device!
        
        // --- Size
        viewportSize = vector_uint2( UInt32(mmView.bounds.width), UInt32(mmView.bounds.height) )
        width = Float( viewportSize.x ); height = Float( viewportSize.y );
        cWidth = Float( viewportSize.x ) / mmView.scaleFactor; cHeight = Float( viewportSize.y ) / mmView.scaleFactor

        defaultLibrary = device.makeDefaultLibrary()!
        mmView.colorPixelFormat = MTLPixelFormat.bgra8Unorm;//_srgb;

        let vertexFunction = defaultLibrary.makeFunction( name: "m4mQuadVertexShader" )
//        let fragmentFunction = defaultLibrary.makeFunction( name: "m4mQuadSamplingShader" )

        pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexFunction
//        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mmView.colorPixelFormat;
        
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    
        commandQueue = device.makeCommandQueue()!
        super.init()

        allocateTextures()
    }
    
    func createNewPipelineState( _ fragmentFunction: MTLFunction ) -> MTLRenderPipelineState?
    {
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        do {
            let renderPipelineState = try device.makeRenderPipelineState( descriptor: pipelineStateDescriptor )
            return renderPipelineState
        } catch {
            print( "createNewPipelineState failed" )
            return nil
        }
    }
    
    func encodeStart( view: MTKView, commandBuffer: MTLCommandBuffer ) -> MTLRenderCommandEncoder?
    {
        let renderPassDescriptor = view.currentRenderPassDescriptor
        
        renderPassDescriptor!.colorAttachments[0].loadAction = .clear
        renderPassDescriptor!.colorAttachments[0].clearColor = MTLClearColor( red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        if ( renderPassDescriptor != nil )
        {
            renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor! )
            renderEncoder?.label = "MyRenderEncoder";
            
            renderEncoder?.setViewport( MTLViewport( originX: 0.0, originY: 0.0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1.0, zfar: 1.0 ) )
            
            renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder?.setVertexBytes( &viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
            
//            renderEncoder?.setFragmentTexture(outputTexture, index: 0)
            
            return renderEncoder
        }
        
        return nil
    }
    
    func encodeRun( _ renderEncoder: MTLRenderCommandEncoder, pipelineState: MTLRenderPipelineState? )
    {
        renderEncoder.setRenderPipelineState( pipelineState! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    func encodeEnd( _ renderEncoder: MTLRenderCommandEncoder )
    {
        renderEncoder.endEncoding()
    }
    
    func setClipRect(_ rect: MMRect? = nil )
    {
        func applyClipRect(_ rect: MMRect)
        {
            let x : Int = Int(rect.x * mmView.scaleFactor)
            let y : Int = Int(rect.y * mmView.scaleFactor)
            
            var width : Int = Int(rect.width * mmView.scaleFactor)
            var height : Int = Int(rect.height * mmView.scaleFactor )
            
            if x + width < 0 {
                return;
            }
            
            if x > Int(self.width) {
                return;
            }
            
            if y + height < 0 {
                return
            }
            
            if y > Int(self.height) {
                return;
            }
            
            if x + width > Int(self.width) {
                width -= x + width - Int(self.width)
            }
            
            if y + height > Int(self.height) {
                height -= y + height - Int(self.height)
            }
            
            currentRenderEncoder?.setScissorRect( MTLScissorRect(x: x, y: y, width: width, height: height ) )
        }
        
        if rect != nil {
            
            let newRect = MMRect(rect!)

            if clipRects.count > 0 {
                newRect.intersect( clipRects[clipRects.count-1] )
            }
            
            applyClipRect(newRect)
            clipRects.append(newRect)
        } else {
            if clipRects.count > 0 {
                clipRects.removeLast()
            }
            
            if clipRects.count > 0 {
                //let last = clipRects.removeLast()
                applyClipRect( clipRects[clipRects.count-1] )
            } else {
                currentRenderEncoder?.setScissorRect( MTLScissorRect(x:0, y:0, width:Int(viewportSize.x), height:Int(viewportSize.y) ) )
            }
        }
    }
    
    func draw(in view: MTKView)
    {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = encodeStart( view: view, commandBuffer: commandBuffer )
        
        currentRenderEncoder = renderEncoder
        mmView.build()
        encodeEnd( renderEncoder! )
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
    
    func allocateTextures() {
        
        outputTexture = nil
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        textureDescriptor.width = Int(viewportSize.x)
        textureDescriptor.height = Int(viewportSize.y)
        textureDescriptor.usage = MTLTextureUsage.shaderRead;
        
        if textureDescriptor.width == 0 {
            textureDescriptor.width = 1
        }
        
        if textureDescriptor.height == 0 {
            textureDescriptor.height = 1
        }
        
        textureDescriptor.usage = MTLTextureUsage.unknown
        outputTexture = device.makeTexture( descriptor: textureDescriptor )
        
        // Setup the vertex buffer
        vertexBuffer = createVertexBuffer( MMRect( 0, 0, width, height ) )
    }
    
    /// Creates a vertex MTLBuffer for the given rectangle
    func createVertexBuffer(_ rect: MMRect ) -> MTLBuffer?
    {
        let left = -self.width / 2 + rect.x
        let right = left + rect.width//self.width / 2 - x
        
        let top = self.height / 2 - rect.y
        let bottom = top - rect.height

        let quadVertices: [Float] = [
            right, bottom, 1.0, 0.0,
            left, bottom, 0.0, 0.0,
            left, top, 0.0, 1.0,
            
            right, bottom, 1.0, 0.0,
            left, top, 0.0, 1.0,
            right, top, 1.0, 1.0,
        ]
        
        return device.makeBuffer(bytes: quadVertices, length: quadVertices.count * MemoryLayout<Float>.stride, options: [])!
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize.x = UInt32( size.width )
        viewportSize.y = UInt32( size.height )
        
        width = Float( size.width )
        height = Float( size.height )
        
        cWidth = width / mmView.scaleFactor
        cHeight = height / mmView.scaleFactor
                
        allocateTextures()
        
        /// Notify the regions
        if let region = mmView.leftRegion {
            region.resize(width: width, height: height)
        }
        if let region = mmView.topRegion {
            region.resize(width: width, height: height)
        }
        if let region = mmView.rightRegion {
            region.resize(width: width, height: height)
        }
        if let region = mmView.bottomRegion {
            region.resize(width: width, height: height)
        }
        if let region = mmView.editorRegion {
            region.resize(width: width, height: height)
        }
    }
}
