//
//  Project.swift
//  ShaderMania
//
//  Created by Markus Moenig on 19/11/20.
//

import MetalKit

class Project
{
    var black           : MTLTexture? = nil
    var temp            : MTLTexture? = nil

    var commandQueue    : MTLCommandQueue? = nil
    var commandBuffer   : MTLCommandBuffer? = nil
    
    var size            = SIMD2<Int>(0,0)
    var lastSize        = SIMD2<Int>(0,0)
    var time            = Float(0)
    var frame           = UInt32(0)

    var assetFolder     : AssetFolder? = nil
    
    var textureLoader   : MTKTextureLoader? = nil
    
    var resChanged      : Bool = false

    init()
    {
    }
    
    deinit
    {
        clear()
    }
    
    func clear() {
        if black != nil { black!.setPurgeableState(.empty); black = nil }
    }
    
    func collectShadersFor(assetFolder: AssetFolder, asset: Asset,_ collected: inout [Asset])
    {
        for (_, connectedToId) in asset.slots {
            
            if let conAsset = assetFolder.getAssetById(connectedToId) {
                collectShadersFor(assetFolder: assetFolder, asset: conAsset, &collected)
                if collected.contains(conAsset) == false {
                    collected.append(conAsset)
                }
            }
        }
        collected.append(asset)
    }
    
    func compileAssets(assetFolder: AssetFolder, forAsset: Asset, compiler: ShaderCompiler, finished: @escaping () -> ())
    {
        var collected : [Asset] = []
        collectShadersFor(assetFolder: assetFolder, asset: forAsset, &collected)
        
        var toCompile = 0
        
        for asset in collected {
            if asset.shader == nil && asset.type == .Shader {
                toCompile += 1
            }
        }
        
        for asset in collected {
            if asset.shader == nil && asset.type == .Shader {
                compiler.compile(asset: asset, cb: { (shader, errors) in
                    
                    asset.shader = shader
                    asset.errors = errors
                    toCompile -= 1

                    if toCompile == 0 {
                        DispatchQueue.main.async {
                            finished()
                        }
                    }
                })
            }
        }
    }
    
    @discardableResult func render(assetFolder: AssetFolder, device: MTLDevice, time: Float, frame: UInt32, viewSize: SIMD2<Int>, forAsset: Asset, preview: Bool = false) -> MTLTexture?
    {
        self.assetFolder = assetFolder
        self.time = time

        //if forAsset.type == .Image {
            //return forAsset.texture
        //}
        
        startDrawing(device)

        if black == nil {
            black = allocateTexture(device, width: 10, height: 10)
            clear(black!)
        }
        
        var collected : [Asset] = []
        collectShadersFor(assetFolder: assetFolder, asset: forAsset, &collected)

        size = viewSize
        
        if let customSize = assetFolder.customSize {
            size = customSize
        }
        
        if preview == false {
            if size != lastSize {
                resChanged = true
            }
        }

        checkTextures(collected: collected, preview: preview, device: device)
            
        for asset in collected {
            if asset.type == .Shader {
                drawShader(asset, preview, device)
            }
        }
        
        if preview {
            for asset in assetFolder.assets {
                if asset.type == .Shader && asset.previewTexture != nil && collected.contains(asset) == false {
                    clear(asset.previewTexture!, float4(0,0,0,0))
                }
            }
        }
        
        if preview == false {
            lastSize = size
        }
                
        if collected.count == 0 {
            return nil
        } else {
            return collected.last!.texture
        }
    }
    
    func drawShader(_ asset: Asset,_ preview: Bool, _ device: MTLDevice)
    {
        if asset.shader == nil {
            print("no shader for \(asset.name)")
            return
        }
        let rect = MMRect( 0, 0, Float(size.x), Float(size.y))
        
        let texture = preview == false ? asset.texture! : asset.previewTexture!
        
        let vertexData = createVertexData(texture: texture, rect: rect)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0,0,0,0)

        let renderEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        var viewportSize = vector_uint2( UInt32(texture.width), UInt32(texture.height))

        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

        var metalData = MetalData()
        metalData.time = time
        metalData.frame = frame
        renderEncoder.setFragmentBytes(&metalData, length: MemoryLayout<MetalData>.stride, index: 0)
        
        for index in 1..<5 {
            var hasBeenSet = false
            
            if let nodeId = asset.slots[index - 1] {
                if let node = assetFolder?.getAssetById(nodeId) {
                    let texture = preview == false ? node.texture : node.previewTexture
                    
                    if let texture = texture {
                        renderEncoder.setFragmentTexture(texture, index: index)
                        hasBeenSet = true
                    }
                }
            }
            
            if hasBeenSet == false {
                renderEncoder.setFragmentTexture(black, index: index)
            }
        }

        /// Update the parameter data for the shader
        if let shader = asset.shader {
            
            if shader.paramDataBuffer == nil {
                shader.paramDataBuffer = device.makeBuffer(bytes: asset.shaderData, length: asset.shaderData.count * MemoryLayout<SIMD4<Float>>.stride, options: [])!
            } else {
                shader.paramDataBuffer!.contents().copyMemory(from: asset.shaderData, byteCount: asset.shaderData.count * MemoryLayout<SIMD4<Float>>.stride)
            }
            
            renderEncoder.setFragmentBuffer(shader.paramDataBuffer, offset: 0, index: 5)
        }

        renderEncoder.setRenderPipelineState(asset.shader!.pipelineState)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
    }
    
    /// Checks if all textures are loaded and makes sure they have the right size
    func checkTextures(collected: [Asset], preview: Bool = true, device: MTLDevice)
    {
        for asset in collected {
            
            if asset.type == .Shader {
                if preview == false {
                    if asset.texture == nil || asset.texture!.width != size.x || asset.texture!.height != size.y {
                        if asset.texture != nil {
                            asset.texture!.setPurgeableState(.empty)
                            asset.texture = nil
                        }
                        asset.texture = allocateTexture(device, width: size.x, height: size.y)
                        clear(asset.texture!)
                    }
                } else {
                    if asset.previewTexture == nil {
                        asset.previewTexture = allocateTexture(device, width: size.x, height: size.y)
                        clear(asset.previewTexture!, float4(0,0,0,0))
                    }
                }
            } else
            if asset.type == .Image {
                // Image Texture
                
                if textureLoader == nil {
                    textureLoader = MTKTextureLoader(device: device)
                }
                
                if preview == false && asset.texture == nil {
                    let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                    if let texture  = try? textureLoader?.newTexture(data: asset.data[0], options: texOptions) {
                        asset.texture = texture
                    }
                } else
                if preview == true && asset.previewTexture == nil {
                    let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                    if let texture  = try? textureLoader?.newTexture(data: asset.data[0], options: texOptions) {
                        asset.previewTexture = texture
                    }
                }
            }
        }
    }
    
    /// Create the image texture for the asset
    func createImageTexture(_ asset: Asset, preview: Bool, device: MTLDevice)
    {
        if textureLoader == nil {
            textureLoader = MTKTextureLoader(device: device)
        }
        
        if preview == true && asset.previewTexture == nil {
        
            let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
            if let texture  = try? textureLoader?.newTexture(data: asset.data[0], options: texOptions) {
                asset.previewTexture = texture
            }
        } else
        if preview == false && asset.texture == nil {
            if preview == false {
                let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                if let texture  = try? textureLoader?.newTexture(data: asset.data[0], options: texOptions) {
                    asset.texture = texture
                }
            }
        }
    }
    
    func startDrawing(_ device: MTLDevice)
    {
        if commandQueue == nil {
            commandQueue = device.makeCommandQueue()
        }
        commandBuffer = commandQueue!.makeCommandBuffer()
        resChanged = false
    }
    
    func stopDrawing(syncTexture: MTLTexture? = nil, waitUntilCompleted: Bool = true)
    {
        #if os(OSX)
        if let texture = syncTexture {
            let blitEncoder = commandBuffer!.makeBlitCommandEncoder()!
            blitEncoder.synchronize(texture: texture, slice: 0, level: 0)
            blitEncoder.endEncoding()
        }
        #endif
        commandBuffer?.commit()
        if waitUntilCompleted {
            commandBuffer?.waitUntilCompleted()
        }
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
    
    func makeCGIImage(_ device: MTLDevice,_ state: MTLComputePipelineState,_ texture: MTLTexture) -> MTLTexture?
    {
        if temp != nil { temp!.setPurgeableState(.empty); temp = nil }

        temp = allocateTexture(device, width: texture.width, height: texture.height)
        runComputeState(device, state, outTexture: temp!, inTexture: texture, syncronize: true)
        return temp
    }
    
    /// Run the given state
    func runComputeState(_ device: MTLDevice,_ state: MTLComputePipelineState?, outTexture: MTLTexture, inBuffer: MTLBuffer? = nil, inTexture: MTLTexture? = nil, inTextures: [MTLTexture] = [], outTextures: [MTLTexture] = [], inBuffers: [MTLBuffer] = [], syncronize: Bool = false, finishedCB: ((Double)->())? = nil )
    {
        // Compute the threads and thread groups for the given state and texture
        func calculateThreadGroups(_ state: MTLComputePipelineState, _ encoder: MTLComputeCommandEncoder,_ width: Int,_ height: Int, limitThreads: Bool = false)
        {
            let w = limitThreads ? 1 : state.threadExecutionWidth
            let h = limitThreads ? 1 : state.maxTotalThreadsPerThreadgroup / w
            let threadsPerThreadgroup = MTLSizeMake(w, h, 1)

            let threadgroupsPerGrid = MTLSize(width: (width + w - 1) / w, height: (height + h - 1) / h, depth: 1)
            encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        }
        
        startDrawing(device)
        
        let computeEncoder = commandBuffer?.makeComputeCommandEncoder()!
        
        computeEncoder?.setComputePipelineState( state! )
        
        computeEncoder?.setTexture( outTexture, index: 0 )
        
        if let buffer = inBuffer {
            computeEncoder?.setBuffer(buffer, offset: 0, index: 1)
        }
        
        var texStartIndex : Int = 2
        
        if let texture = inTexture {
            computeEncoder?.setTexture(texture, index: 2)
            texStartIndex = 3
        }
        
        for (index,texture) in inTextures.enumerated() {
            computeEncoder?.setTexture(texture, index: texStartIndex + index)
        }
        
        texStartIndex += inTextures.count

        for (index,texture) in outTextures.enumerated() {
            computeEncoder?.setTexture(texture, index: texStartIndex + index)
        }
        
        texStartIndex += outTextures.count

        for (index,buffer) in inBuffers.enumerated() {
            computeEncoder?.setBuffer(buffer, offset: 0, index: texStartIndex + index)
        }
        
        calculateThreadGroups(state!, computeEncoder!, outTexture.width, outTexture.height)
        computeEncoder?.endEncoding()

        stopDrawing(syncTexture: outTexture, waitUntilCompleted: true)
        
        /*
        if let finished = finishedCB {
            commandBuffer?.addCompletedHandler { cb in
                let executionDuration = cb.gpuEndTime - cb.gpuStartTime
                //print(executionDuration)
                finished(executionDuration)
            }
        } */
    }
}
