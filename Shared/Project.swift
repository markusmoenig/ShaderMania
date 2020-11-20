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
    
    var commandQueue    : MTLCommandQueue? = nil
    var commandBuffer   : MTLCommandBuffer? = nil
    
    var size            = SIMD2<Int>(0,0)
    var time            = Float(0)

    var assetFolder     : AssetFolder? = nil
    
    var textureCache    : [UUID:MTLTexture] = [:]
    var textureLoader   : MTKTextureLoader? = nil

    init()
    {
    }
    
    deinit
    {
        clear()
    }
    
    func clear() {
        if black != nil { black!.setPurgeableState(.empty); black = nil }
        if texture != nil { texture!.setPurgeableState(.empty); texture = nil }
        
        for (id, _) in textureCache {
            if textureCache[id] != nil {
                textureCache[id]!.setPurgeableState(.empty)
            }
        }
        textureCache = [:]
    }
    
    func render(assetFolder: AssetFolder, device: MTLDevice, time: Float, viewSize: SIMD2<Int>, breakAsset: Asset? = nil) -> MTLTexture?
    {
        self.assetFolder = assetFolder
        self.time = time

        startDrawing(device)

        if black == nil {
            texture = allocateTexture(device, width: 10, height: 10)
            clear(texture!)
        }

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
            checkTextures(device)
            
            // Do buffers
            for asset in assetFolder.assets {
                if asset.type == .Buffer {
                    if asset === breakAsset {
                        drawShader(asset, texture!, device)
                        return texture
                    } else {
                        if let outputId = asset.output {
                            if let texture = textureCache[outputId] {
                                drawShader(asset, texture, device)
                            }
                        }
                    }
                }
            }
            
            // Final Shader
            drawShader(final, texture!, device)
        }
        
        return texture
    }
    
    /// Checks if all textures are loaded and makes sure they have the right size
    func checkTextures(_ device: MTLDevice)
    {
        for asset in assetFolder!.assets {
            if asset.type == .Texture {
                if asset.data.count == 0 {
                    // Empty Texture
                    
                    if textureCache[asset.id] == nil || textureCache[asset.id]!.width != size.x || textureCache[asset.id]!.height != size.y {
                        if textureCache[asset.id] != nil {
                            textureCache[asset.id]!.setPurgeableState(.empty)
                            textureCache[asset.id] = nil
                        }
                        textureCache[asset.id] = allocateTexture(device, width: size.x, height: size.y)
                        clear(textureCache[asset.id]!)
                    }
                } else {
                    // Image Texture
                    
                    if textureLoader == nil {
                        textureLoader = MTKTextureLoader(device: device)
                    }
                    
                    if textureCache[asset.id] == nil {
                        let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                        if let texture  = try? textureLoader?.newTexture(data: asset.data[0], options: texOptions) {
                            textureCache[asset.id] = texture
                        }
                    }
                }
            }
        }
    }
    
    func drawShader(_ asset: Asset,_ texture: MTLTexture, _ device: MTLDevice)
    {
        if asset.shader == nil {
            print("no shader for \(asset.name)")
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
        
        for index in 1..<5 {
            var hasBeenSet = false
            
            if let textureId = asset.slots[0] {
                if let texture = textureCache[textureId] {
                    renderEncoder.setFragmentTexture(texture, index: index)
                    hasBeenSet = true
                }
            }
            
            if hasBeenSet == false {
                renderEncoder.setFragmentTexture(black, index: index)
            }
        }

        renderEncoder.setRenderPipelineState(asset.shader!.pipelineState)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
    }
    
    func startDrawing(_ device: MTLDevice)
    {
        if commandQueue == nil {
            commandQueue = device.makeCommandQueue()
        }
        commandBuffer = commandQueue!.makeCommandBuffer()
    }
    
    func stopDrawing(syncronize: Bool =  false, waitUntilCompleted: Bool = false)
    {
        #if os(OSX)
        if syncronize {
            let blitEncoder = commandBuffer!.makeBlitCommandEncoder()!
            blitEncoder.synchronize(texture: texture!, slice: 0, level: 0)
            blitEncoder.endEncoding()
        }
        #endif
        commandBuffer?.commit()
        if waitUntilCompleted {
            commandBuffer?.waitUntilCompleted()
        }
        commandQueue = nil
        commandBuffer = nil
    }
    
    func allocateTexture(_ device: MTLDevice, width: Int, height: Int) -> MTLTexture?
    {
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
