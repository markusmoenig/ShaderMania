//
//  MMFragment.swift
//  Framework
//
//  Created by Markus Moenig on 31.01.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

class MMFragment {
    
    let mmView                  : MMView

    let device                  : MTLDevice
    let defaultLibrary          : MTLLibrary?
    var commandQueue            : MTLCommandQueue?
    let pipelineStateDescriptor : MTLRenderPipelineDescriptor

    var viewportSize            : vector_uint2

    var texture                 : MTLTexture!
    var width, height           : Float
    
    var vertexBuffer            : MTLBuffer?
    
    var commandBuffer           : MTLCommandBuffer?
    var renderEncoder           : MTLRenderCommandEncoder?
    
    init( _ view: MMView )
    {
        mmView = view

        device = MTLCreateSystemDefaultDevice()!
        defaultLibrary = device.makeDefaultLibrary()
        commandQueue = device.makeCommandQueue()
        
        let vertexFunction = defaultLibrary!.makeFunction( name: "m4mQuadVertexShader" )

        pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexFunction
        //        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm;
        
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        viewportSize = vector_uint2( 0, 0 )
        
        width = 0
        height = 0
    }
    
    /// Creates a state from an optional library and the function name
    func createState( library: MTLLibrary? = nil, name: String ) -> MTLRenderPipelineState?
    {
        let function : MTLFunction?
            
        if library != nil {
            function = library!.makeFunction( name: name )
        } else {
            function = defaultLibrary!.makeFunction( name: name )
        }
        
        var renderPipelineState : MTLRenderPipelineState?
        
        do {
            //renderPipelineState = try device.makeComputePipelineState( function: function! )
            pipelineStateDescriptor.fragmentFunction = function
            renderPipelineState = try device.makeRenderPipelineState( descriptor: pipelineStateDescriptor )
        } catch {
            print( "computePipelineState failed" )
            return nil
        }
        
        return renderPipelineState
    }
    
    /// --- Creates a library from the given source
    func createLibraryFromSource( source: String ) -> MTLLibrary?
    {
        var library : MTLLibrary
        do {
            let header = """

                            #include <metal_stdlib>
                            #include <simd/simd.h>
                            using namespace metal;

                            typedef struct
                            {
                                float4 clipSpacePosition [[position]];
                                float2 textureCoordinate;
                            } RasterizerData;

                        """
            library = try device.makeLibrary( source: header + source, options: nil )
        } catch
        {
            print( "Make Library Failed" )
            print( error )
            return nil
        }
        return library;
    }
    
    /// Allocate the output texture, optionally can be used to create an arbitray texture by setting output to false
    @discardableResult func allocateTexture( width: Float, height: Float, output: Bool? = true ) -> MTLTexture?
    {
        if output! {
            self.texture = nil
        }
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        textureDescriptor.width = Int(width)
        textureDescriptor.height = Int(height)
        
        textureDescriptor.usage = MTLTextureUsage.unknown;

        let texture = device.makeTexture( descriptor: textureDescriptor )
        if output! {
            self.texture = texture
        }
        
        viewportSize.x = UInt32( width )
        viewportSize.y = UInt32( height )
        
        self.width = width
        self.height = height
        
        // Setup the vertex buffer
        vertexBuffer = createVertexBuffer( MMRect( 0, 0, width, height ) )
        
        return texture
    }

    /// Run the given state
    func encoderStart(outTexture: MTLTexture? = nil) -> Bool
    {
        let tex = outTexture == nil ? texture : outTexture

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = tex
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor( red: 0, green: 0, blue: 0, alpha: 0)
        
        commandBuffer = commandQueue!.makeCommandBuffer()!
        if let renderEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
        
            renderEncoder.setViewport( MTLViewport( originX: 0.0, originY: 0.0, width: Double(tex!.width), height: Double(tex!.height), znear: -1.0, zfar: 1.0 ) )
        
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes( &viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
        
            self.renderEncoder = renderEncoder
            return true
        }
        
        return false
    }
    
    /// Encode the given state
    func encodeRun(_ state: MTLRenderPipelineState?, inBuffer: MTLBuffer? = nil, inTexture: MTLTexture? = nil )
    {
        renderEncoder!.setRenderPipelineState( state! )
        
        if inBuffer != nil {
            renderEncoder!.setFragmentBuffer(inBuffer, offset: 0, index: 2)
        }
        
        if inTexture != nil {
            renderEncoder!.setFragmentTexture(inTexture, index: 1)
        }
        
        renderEncoder!.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    /// End encoding
    func encodeEnd()
    {
        renderEncoder!.endEncoding()
        commandBuffer!.commit()
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
    
    @discardableResult func applyClipRect(_ rect: MMRect ) -> Bool
    {
        let x : Int = Int(rect.x)// * mmView.scaleFactor)
        let y : Int = Int(rect.y)// * mmView.scaleFactor)
        
        var width : Int = Int(rect.width)// * mmView.scaleFactor)
        var height : Int = Int(rect.height)// * mmView.scaleFactor )
        
        if x + width < 0 {
            return false
        }
        
        if x > Int(self.width) {
            return false
        }
        
        if y + height < 0 {
            return false
        }
        
        if y > Int(self.height) {
            return false
        }
                
        if x + width > Int(self.width) {
            width -= x + width - Int(self.width)
        }
        
        if y + height > Int(self.height) {
            height -= y + height - Int(self.height)
        }
                
        renderEncoder!.setScissorRect( MTLScissorRect(x: x, y: y, width: width, height: height ) )
        return true
    }
}
