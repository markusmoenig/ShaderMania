//
//  Project.swift
//  ShaderMania
//
//  Created by Markus Moenig on 19/11/20.
//

import MetalKit

class Project : Codable, Equatable
{
    enum State {
        case Idle, Playing, Paused
    }
    
    var state           : State = .Idle
    
    var model           : Model!
    
    var uuid            : UUID = UUID()
    
    var scenes          : [SceneNode] = []
    var assets          : [AssetData] = []
    
    var black           : MTLTexture? = nil
    var temp            : MTLTexture? = nil

    var commandQueue    : MTLCommandQueue? = nil
    var commandBuffer   : MTLCommandBuffer? = nil
    
    var size            = SIMD2<Int>(0,0)
    var lastSize        = SIMD2<Int>(0,0)
    
    var time            = Float(0)
    var frame           = UInt32(0)
    var targetFPS       = Float(60)

    var renderTree      : Node? = nil
    
    var textureLoader   : MTKTextureLoader? = nil
    
    var resChanged      : Bool = false
    
    private enum CodingKeys: String, CodingKey {
        case uuid
        case scenes
        case assets
    }

    init() {
        
        let scene = SceneNode()
        scenes.append(scene)
    }
    
    deinit
    {
        clear()
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(UUID.self, forKey: .uuid)
        scenes = try container.decode([SceneNode].self, forKey: .scenes)
        if let a = try container.decodeIfPresent([AssetData].self, forKey: .assets) {
            assets = a
        }
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(scenes, forKey: .scenes)
        try container.encode(assets, forKey: .assets)
    }
    
    /// Start playback
    func play() {
        
        if state == .Idle {
            model.nodeView.lockFramerate(true)
        }
        
        state = .Playing
        time = 0
        frame = 0
    }
    
    /// Stop playback
    func stop() {
        state = .Idle
        model.nodeView.unlockFramerate(true)
    }
    
    /// The main update function for rendering
    func update() {
                
        if let tree = model.selectedTree {
            render(tree: tree, viewSize: SIMD2<Int>(model.nodeGraph.previewSize))
        }
        
        if state == .Playing {
            time += 1 / targetFPS
            frame += 1
        }
    }
    
    /// Render the given tree
    @discardableResult func render(tree: Node, viewSize: SIMD2<Int>, preview: Bool = false) -> MTLTexture?
    {
        self.renderTree = tree
        
        let device = model.device!
        
        startDrawing(device)

        if black == nil {
            black = allocateTexture(device, width: 10, height: 10)
            clear(black!)
        }
        
        var collected : [Node] = []
        collectShadersForTree(tree: tree, collection: &collected)

        size = viewSize
        
        //if let customSize = assetFolder.customSize {
        //    size = customSize
        //}
        
        if preview == false {
            if size != lastSize {
                resChanged = true
            }
        }

        checkTextures(collected: collected, preview: preview, device: device)
            
        for node in collected {
            if node.brand == .Shader {
                drawShader(node, preview, device)
            }
        }
        
        /*
        if preview {
            for asset in assetFolder.assets {
                if asset.type == .Shader && asset.previewTexture != nil && collected.contains(asset) == false {
                    clear(asset.previewTexture!, float4(0,0,0,0))
                }
            }
        }*/
        
        if preview == false {
            lastSize = size
        }
        
        stopDrawing()
        
        if collected.count == 0 {
            return nil
        } else {
            tree.texture = collected.last!.texture
            return collected.last!.texture
        }
    }
    
    func drawShader(_ node: Node,_ preview: Bool, _ device: MTLDevice)
    {
        if node.shader == nil {
            print("no shader for \(node.name)")
            return
        }
        
        let rect = MMRect( 0, 0, Float(size.x), Float(size.y))
        
        let texture = preview == false ? node.texture! : node.previewTexture!
        
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
        
        /*
        for index in 1..<5 {
            var hasBeenSet = false
            
            /*
            if let nodeId = asset.slots[index - 1] {
                if let node = assetFolder?.getAssetById(nodeId) {
                    let texture = preview == false ? node.texture : node.previewTexture
                    
                    if let texture = texture {
                        renderEncoder.setFragmentTexture(texture, index: index)
                        hasBeenSet = true
                    }
                }
            }*/
            
            if hasBeenSet == false {
                renderEncoder.setFragmentTexture(black, index: index)
            }
        }*/

        /// Update the parameter data for the shader
        if let shader = node.shader {
            
            for (index, uiItem) in node.uiItems.enumerated() {
                if uiItem.brand == .Number {
                    if let number = uiItem as? NodeUINumber {
                        node.shaderData[index].x = number.value
                    } else
                    if let color = uiItem as? NodeUIColor {
                        node.shaderData[index].x = color.value.x
                        node.shaderData[index].y = color.value.y
                        node.shaderData[index].z = color.value.y
                        node.shaderData[index].w = 1
                    }
                }
            }
            
            if shader.paramDataBuffer == nil {
                shader.paramDataBuffer = device.makeBuffer(bytes: node.shaderData, length: node.shaderData.count * MemoryLayout<SIMD4<Float>>.stride, options: [])!
            } else {
                shader.paramDataBuffer!.contents().copyMemory(from: node.shaderData, byteCount: node.shaderData.count * MemoryLayout<SIMD4<Float>>.stride)
            }
            
            renderEncoder.setFragmentBuffer(shader.paramDataBuffer, offset: 0, index: 5)
        }

        renderEncoder.setRenderPipelineState(node.shader!.pipelineState)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
    }
    
    
    func clear() {
        if black != nil { black!.setPurgeableState(.volatile); black = nil }
    }
    
    /// Collects all shaders in the given tree
    func collectShadersForTree(tree: Node, collection: inout [Node])
    {
        func addConnectedNodes(_ node: Node) {
            for t in node.terminals {
                for c in t .connections {
                    if let connectedNode = c.toTerminal?.node {
                        if connectedNode.brand == .Shader || connectedNode.brand == .LuaScript {
                            if collection.contains(connectedNode) == false {
                                collection.append(connectedNode)
                                addConnectedNodes(connectedNode)
                            }
                        }
                    }
                }
            }
        }
        
        for node in tree.children! {
            if node.brand == .ShaderTree || node.brand == .LuaScript {
                addConnectedNodes(node)
            }
        }
    }
    
    /// Compiles the given shader tree
    func compileTree(tree: Node, shaderCompiler: ShaderCompiler, luaCompiler: LuaCompiler, finished: @escaping () -> ())
    {
        var collected : [Node] = []
        collectShadersForTree(tree: tree, collection: &collected)
        
        var toCompile = collected.count
        
        // Compilation has finished ?
        func checkForEnd() {
            if toCompile == 0 {
                DispatchQueue.main.async {
                    for node in collected {
                        node.setupUI(mmView: self.model.nodeView)
                    }
                    finished()
                }
            }
        }
        
        for node in collected {
            
            if node.brand == .Shader {
                shaderCompiler.compile(node: node, cb: { (shader, errors) in
                        
                    node.shader = shader
                    node.errors = errors
                        
                    toCompile -= 1
                    checkForEnd()
                })
            } else
            if node.brand == .LuaScript {
                luaCompiler.compile(node: node, cb: { (vm, errors) in

                    node.vm = nil
                    node.vm = vm
                                        
                    toCompile -= 1
                    checkForEnd()
                })
            }
        }
    }
    
    /// Checks if all textures are loaded and makes sure they have the right size
    func checkTextures(collected: [Node], preview: Bool = true, device: MTLDevice)
    {
        for node in collected {
            
            if node.brand == .Shader {
                if preview == false {
                    if node.texture == nil || node.texture!.width != size.x || node.texture!.height != size.y {
                        if node.texture != nil {
                            //node.texture!.setPurgeableState(.volatile)
                            node.texture = nil
                        }
                        node.texture = allocateTexture(device, width: size.x, height: size.y)
                        clear(node.texture!)
                    }
                } else {
                    if node.previewTexture == nil {
                        node.previewTexture = allocateTexture(device, width: size.x, height: size.y)
                        clear(node.previewTexture!, float4(0,0,0,0))
                    }
                }
            } /*else
            if node.type == .Image {
                // Image Texture
                
                if textureLoader == nil {
                    textureLoader = MTKTextureLoader(device: device)
                }
                
                if preview == false && node.texture == nil {
                    let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                    if let texture  = try? textureLoader?.newTexture(data: node.data[0], options: texOptions) {
                        node.texture = texture
                    }
                } else
                if preview == true && asset.previewTexture == nil {
                    let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                    if let texture  = try? textureLoader?.newTexture(data: node.data[0], options: texOptions) {
                        node.previewTexture = texture
                    }
                }
            }*/
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
    
    func stopDrawing(syncTexture: MTLTexture? = nil, waitUntilCompleted: Bool = false)
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
        if temp != nil { temp!.setPurgeableState(.volatile); temp = nil }

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
    
    static func ==(lhs:Project, rhs:Project) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
