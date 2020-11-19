//
//  Project.swift
//  ShaderMania
//
//  Created by Markus Moenig on 19/11/20.
//

import Foundation

import MetalKit

class Project
{
    var texture         : MTLTexture? = nil
    
    var black           : MTLTexture? = nil
    
    var slot0           : MTLTexture? = nil
    var slot1           : MTLTexture? = nil
    var slot2           : MTLTexture? = nil
    var slot3           : MTLTexture? = nil
    
    var commandQueue    : MTLCommandQueue? = nil
    var commandBuffer   : MTLCommandBuffer? = nil
    
    var size            = SIMD2<Int>(0,0)
    var time            = Float(0)

    var assetFolder     : AssetFolder? = nil
    
    init()
    {
    }
    
    func render(assetFolder: AssetFolder, device: MTLDevice, time: Float, viewSize: SIMD2<Int>) -> MTLTexture?
    {
        self.assetFolder = assetFolder
        self.time = time

        if commandQueue == nil {
            commandQueue = device.makeCommandQueue()
        }
        commandBuffer = commandQueue!.makeCommandBuffer()
        
        if let final = assetFolder.getAsset("Final", .Shader) {
            
            size = viewSize

            // Make sure texture is of size size
            if texture == nil || texture!.width != size.x || texture!.height != size.y {
                if texture != nil {
                    texture!.setPurgeableState(.empty)
                    texture = nil
                }
                texture = allocateTexture(device, width: size.x, height: size.y)
                clear(texture!)
            }
            
            drawShader(final, texture!)
        }
        
        commandBuffer?.commit()
        //self.commandQueue = nil
        //self.commandBuffer = nil
        
        return texture
    }
    
    func drawShader(_ asset: Asset,_ texture: MTLTexture)
    {
        if asset.shader == nil {
            return
        }
        let rect = MMRect( 0, 0, Float(size.x), Float(size.y), scale: 1 )
        
        let vertexData = createVertexData(texture: texture, rect: rect)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let renderEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        var viewportSize = vector_uint2( UInt32(texture.width), UInt32(texture.height))

        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

        var metalData = MetalData()
        metalData.time = time
        renderEncoder.setFragmentBytes(&metalData, length: MemoryLayout<MetalData>.stride, index: 0)

        renderEncoder.setRenderPipelineState(asset.shader!.pipelineState)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
    }
    
    func allocateTexture(_ device: MTLDevice, width: Int, height: Int) -> MTLTexture?
    {
        /*
        if texture != nil {
            texture!.setPurgeableState(.empty)
            texture = nil
        }*/
            
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        textureDescriptor.width = width == 0 ? 1 : width
        textureDescriptor.height = height == 0 ? 1 : height
        
        textureDescriptor.usage = MTLTextureUsage.unknown
        return device.makeTexture(descriptor: textureDescriptor)
    }
    
    /// Creates vertex data for the given rectangle
    func createVertexData(texture: MTLTexture, rect: MMRect) -> [Float]
    {
        let left: Float  = -Float(texture.width) / 2.0 + rect.x
        let right: Float = left + rect.width//self.width / 2 - x
        
        let top: Float = Float(texture.height) / 2.0 - rect.y
        let bottom: Float = top - rect.height

        let quadVertices: [Float] = [
            right, bottom, 1.0, 0.0,
            left, bottom, 0.0, 0.0,
            left, top, 0.0, 1.0,
            
            right, bottom, 1.0, 0.0,
            left, top, 0.0, 1.0,
            right, top, 1.0, 1.0,
        ]
        
        return quadVertices
    }
    
    func clear(_ texture: MTLTexture, _ color: float4 = SIMD4<Float>(0,0,0,1))
    {
        let renderPassDescriptor = MTLRenderPassDescriptor()

        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(Double(color.x), Double(color.y), Double(color.z), Double(color.w))
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        let renderEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.endEncoding()
    }
}
