//
//  Core.swift
//  ShaderMania
//
//  Created by Markus Moenig on 25/8/20.
//

import MetalKit
import Combine
import AVFoundation

public class Core       : ObservableObject
{
    enum State {
        case Idle, Running, Paused
    }
    
    var state           : State = .Idle
    
    var view            : DMTKView!
    var device          : MTLDevice!

    // MetalMania based Node system
    var nodeView        : MMView!
    var nodeGraph       : NodeGraph!
    var nodeRegion      : MMRegion!

    //var texture         : Texture2D? = nil
    var metalStates     : MetalStates!
    
    var file            : File? = nil

    var viewportSize    : vector_uint2
    var scaleFactor     : Float
    
    var assetFolder     : AssetFolder!
    
    var screenWidth     : Float = 0
    var screenHeight    : Float = 0

    var coreCmdQueue    : MTLCommandQueue? = nil
    var coreCmdBuffer   : MTLCommandBuffer? = nil
    var coreScissorRect : MTLScissorRect? = nil
    
    var scriptEditor    : ScriptEditor? = nil

    var shaderCompiler  : ShaderCompiler!

    var textureLoader   : MTKTextureLoader!
        
    var resources       : [AnyObject] = []
    var availableFonts  : [String] = ["OpenSans", "Square", "SourceCodePro"]
    //var fonts           : [Font] = []
    
    //var _Time           = Float1(0)
    //var _Aspect         = Float2(1,1)
    var _Frame          = UInt32(0)
    var targetFPS       : Float = 60
    
    var coreAsset       : Asset? = nil

    // Preview Size, UI only
    var previewFactor   : CGFloat = 4
    var previewOpacity  : Double = 0.5
    
    let updateUI        = PassthroughSubject<Void, Never>()
    var didSend         = false
    
    let timeChanged     = PassthroughSubject<Float, Never>()

    let createPreview   = PassthroughSubject<Void, Never>()

    var helpText        : String = ""
    let helpTextChanged = PassthroughSubject<Void, Never>()

    let contentChanged  = PassthroughSubject<Void, Never>()
    let selectionChanged = PassthroughSubject<Asset?, Never>()

    let libraryChanged  = PassthroughSubject<LibraryShaderList?, Never>()

    var assetError      = CompileError()
    let coreError       = PassthroughSubject<Void, Never>()
    
    var localAudioPlayers: [String:AVAudioPlayer] = [:]
    var globalAudioPlayers: [String:AVAudioPlayer] = [:]
    
    var showingHelp     : Bool = false
    
    var frameworkId     : String? = nil
    
    var project         : Project? = nil
    
    //var nodesWidget     : NodesWidget!
    var library         : Library!
    
    public init(_ frameworkId: String? = nil)
    {
        self.frameworkId = frameworkId
        
        viewportSize = vector_uint2( 0, 0 )
        
        #if os(OSX)
        scaleFactor = Float(NSScreen.main!.backingScaleFactor)
        #else
        scaleFactor = Float(UIScreen.main.scale)
        #endif
                
        file = File()

        assetFolder = AssetFolder()
        
        assetFolder.setup(self)

        shaderCompiler = ShaderCompiler(self)
        
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print(error.localizedDescription)
        }
        #endif
        
        project = Project()
        library = Library(self)
    }
    
    public func setupView(_ view: DMTKView)
    {
        self.view = view
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            device = metalDevice
            if frameworkId != nil {
                view.device = device
            }
        } else {
            print("Cannot initialize Metal!")
        }
        view.core = self
        
        metalStates = MetalStates(self)
        textureLoader = MTKTextureLoader(device: device)
        
        /*
        for fontName in availableFonts {
            let font = Font(name: fontName, core: self)
            fonts.append(font)
        }*/
        
        view.platformInit()
        checkTexture()
                
        library.requestShaders()
    }
    
    public func setupNodesView(_ view: MMView)
    {
        /*
        view.startup()
        view.platformInit()

        nodeView = view
        
        nodeGraph = NodeGraph()
        nodeGraph.setup(self)
        
        nodeRegion = EditorRegion(view, core: self )
        
        view.editorRegion = nodeRegion
        */
        //view.core = self
        //nodesWidget = NodesWidget(self)
    }
    
    public func load(_ data: Data)
    {
        if let folder = try? JSONDecoder().decode(AssetFolder.self, from: data) {
            assetFolder = folder
        }
    }
    
    public func start()
    {
        clearLocalAudio()
        clearGlobalAudio()
        
        view.reset()
        
        assetError.error = nil
        state = .Running
        
        //_Aspect.x = 1
        //_Aspect.y = 1

        state = .Running
        view.enableSetNeedsDisplay = false
        view.isPaused = false
            
        //_Time.x = 0
        targetFPS = 60
        _Frame = 0
        
        //if let scriptEditor = scriptEditor {
        //    scriptEditor.setSilentMode(true)
        //}
    }
    
    func stop()
    {
        clearLocalAudio()
        clearGlobalAudio()
        
        //if let scriptEditor = scriptEditor {
        //    scriptEditor.setSilentMode(false)
        //}
        
        coreAsset = nil
                
        if let scriptEditor = scriptEditor, assetError.error == nil {
            scriptEditor.clearAnnotations()
        }
        
        state = .Idle
        view.isPaused = true
        
        //_Time.x = 0
        _Frame = 0
        //timeChanged.send(_Time.x)
    }
    
    @discardableResult func checkTexture() -> Bool
    {
        /*
        if texture == nil || texture!.texture.width != Int(view.frame.width) || texture!.texture.height != Int(view.frame.height) {
            
            /*
            if texture == nil {
                texture = Texture2D(self)
            } else {
                texture?.allocateTexture(width: Int(view.frame.width), height: Int(view.frame.height))
            }*/
            
            viewportSize.x = UInt32(texture!.width)
            viewportSize.y = UInt32(texture!.height)
            
            screenWidth = Float(texture!.width)
            screenHeight = Float(texture!.height)
            
            coreScissorRect = MTLScissorRect(x: 0, y: 0, width: texture!.texture.width, height: texture!.texture.height)
                        
            //if let map = currentMap?.map {
            //    map.setup(core: self)
            //}
            return true
        }*/
        return false
    }
    
    public func draw()
    {
        guard let drawable = view.currentDrawable else {
            return
        }
        /*
        if state == .Idle {
            if let asset = assetFolder.current {
                if asset.type == .Texture {
                    startDrawing()
                    
                    if checkTexture() {
                        createPreview(asset, false)
                    }
            
                    let renderPassDescriptor = view.currentRenderPassDescriptor
                    renderPassDescriptor?.colorAttachments[0].loadAction = .load
                    let renderEncoder = coreCmdBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
                    
                    drawTexture(texture!.texture!, renderEncoder: renderEncoder!)
                    renderEncoder?.endEncoding()
                    
                    coreCmdBuffer?.present(drawable)
                    stopDrawing()

                    return
                }
            }
        } else {
            //_Time.x += 1.0 / targetFPS
            //timeChanged.send(_Time.x)
        }
            
        if let asset = nodesWidget.currentNode {
            
            if let texture = project?.render(assetFolder: assetFolder, device: device, time: _Time.x, frame: _Frame, viewSize: SIMD2<Int>(Int(view.frame.width), Int(view.frame.height)), forAsset: asset) {
                
                project?.stopDrawing()
                startDrawing()

                let renderPassDescriptor = view.currentRenderPassDescriptor
                renderPassDescriptor?.colorAttachments[0].loadAction = .clear
                renderPassDescriptor?.colorAttachments[0].clearColor = MTLClearColorMake(0,0,0,0)

                let renderEncoder = coreCmdBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
                
                drawTexture(texture, renderEncoder: renderEncoder!)
                renderEncoder?.endEncoding()
                
                coreCmdBuffer?.present(drawable)

                stopDrawing()

                if project!.resChanged {
                    if didSend == false {
                        didSend = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.updateUI.send()
                            self.didSend = false
                        }
                    }
                }
            }
        }
        
        if state == .Running {
            _Time.x += 1.0 / targetFPS
            _Frame += 1
        }
         */
    }
    
    func updateNodePreview()
    {
        /*
        if let asset = nodesWidget.currentNode {
            if asset.type == .Shader {
                project?.startDrawing(device)
                project?.render(assetFolder: assetFolder, device: device, time: _Time.x, frame: _Frame, viewSize: SIMD2<Int>(80, 80), forAsset: asset, preview: true)
                project?.stopDrawing()
            } else
            if asset.type == .Image {
                if asset.previewTexture == nil {
                    project?.createImageTexture(asset, preview: true, device: device)
                }
            }
        }*/
    }
    
    func startDrawing()
    {
        if coreCmdQueue == nil {
            coreCmdQueue = view.device!.makeCommandQueue()
        }
        coreCmdBuffer = coreCmdQueue!.makeCommandBuffer()
    }
    
    func stopDrawing(deleteQueue: Bool = false)
    {
        coreCmdBuffer?.commit()

        if deleteQueue {
            self.coreCmdQueue = nil
        }
        self.coreCmdBuffer = nil
    }
    
    /// Create a preview for the current asset
    func createPreview(_ asset: Asset,_ update: Bool = true)
    {
        /*
        if state == .Idle {
            //clearLocalAudio()
            if asset.type == .Shader {
                updateOnce()
            } else
            if asset.type == .Audio {
                do {
                    let player = try AVAudioPlayer(data: asset.data[0])
                    localAudioPlayers[asset.name] = player
                    player.play()
                } catch let error {
                    print(error.localizedDescription)
                }
            } else if asset.type == .Image {
                if asset.dataIndex < asset.data.count {
                                    
                    if asset.texture == nil {
                        project?.createImageTexture(asset, preview: false, device: device)
                    }
                    if let texture = asset.texture {
                        let texture2D = Texture2D(self, texture: texture)
                        
                        self.startDrawing()
                        var options : [String:Any] = [:]
                        options["texture"] = texture2D
                        
                        //let width : Float = texture2D.width * Float(asset.dataScale)
                        //let height : Float = texture2D.height * Float(asset.dataScale)

                        options["width"] = view.frame.width
                        options["height"] = view.frame.height

                        self.texture?.clear()
                        self.texture?.drawTexture(options)
                        self.stopDrawing()
                        if update {
                            self.updateOnce()
                        }
                                                                        
                        if let scriptEditor = self.scriptEditor {
                            let text = """

                            Displaying image \"\(asset.name)\"
                            
                            Image resolution \(Int(texture2D.width))x\(Int(texture2D.height))

                            """
                            scriptEditor.setAssetValue(asset, value: text)
                        }
                    }
                }
            } else if asset.type == .Texture {
                checkTexture()
                if asset.data.count == 0 {
                    if let scriptEditor = self.scriptEditor {
                        let text = """

                        This texture will be automatically set to the output resolution.

                        """
                        scriptEditor.setAssetValue(asset, value: text)
                        
                        if update {
                            startDrawing()
                        }
                        
                        self.texture?.clear()

                        if update {
                            stopDrawing()
                            updateOnce()
                        }
                    }
                } else {
                    let data = asset.data[0]
                    
                    let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                    if let texture  = try? textureLoader.newTexture(data: data, options: texOptions) {
                        let texture2D = Texture2D(self, texture: texture)
                        
                        if update {
                            startDrawing()
                        }
                        
                        var options : [String:Any] = [:]
                        options["texture"] = texture2D
                        
                        let width : Float = texture2D.width * Float(asset.dataScale)
                        let height : Float = texture2D.height * Float(asset.dataScale)

                        options["width"] = width
                        options["height"] = height

                        //self.texture?.clear()
                        self.texture?.drawTexture(options)
                        if update {
                            stopDrawing()
                            updateOnce()
                        }
                                                
                        if let scriptEditor = self.scriptEditor {
                            let text = """

                            Displaying image for texture \(asset.name)
                            
                            Image resolution \(Int(texture2D.width)) x \(Int(texture2D.height))

                            """
                            scriptEditor.setAssetValue(asset, value: text)
                        }
                    }
                }
            }
        }
         */
    }
    
    /// Clears all local audio
    func clearLocalAudio()
    {
        for (_, a) in localAudioPlayers {
            a.stop()
        }
        localAudioPlayers = [:]
    }
    
    /// Clears all global audio
    func clearGlobalAudio()
    {
        for (_, a) in globalAudioPlayers {
            a.stop()
        }
        globalAudioPlayers = [:]
    }
    
    /// Updates the display once
    func updateOnce()
    {
        self.view.enableSetNeedsDisplay = true
        #if os(OSX)
        let nsrect : NSRect = NSRect(x:0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.view.setNeedsDisplay(nsrect)
        #else
        self.view.setNeedsDisplay()
        #endif
    }
    
    func drawTexture(_ texture: MTLTexture, renderEncoder: MTLRenderCommandEncoder)
    {
        let width : Float = Float(texture.width)
        let height: Float = Float(texture.height)

        var settings = TextureUniform()
        settings.screenSize.x = Float(texture.width)//screenWidth
        settings.screenSize.y = Float(texture.height)//screenHeight
        settings.pos.x = 0
        settings.pos.y = 0
        settings.size.x = width * scaleFactor
        settings.size.y = height * scaleFactor
        settings.globalAlpha = 1
                
        let rect = MMRect( 0, 0, width, height, scale: scaleFactor )
        let vertexData = createVertexData(texture: texture, rect: rect)
        
        var viewportSize = vector_uint2( UInt32(texture.width), UInt32(texture.height))

        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
        
        renderEncoder.setFragmentBytes(&settings, length: MemoryLayout<TextureUniform>.stride, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 1)

        renderEncoder.setRenderPipelineState(metalStates.getState(state: .CopyTexture))
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    /*
    /// Creates vertex data for the given rectangle
    func createVertexData(texture: Texture2D, rect: MMRect) -> [Float]
    {
        let left: Float  = -texture.width / 2.0 + rect.x
        let right: Float = left + rect.width//self.width / 2 - x
        
        let top: Float = texture.height / 2.0 - rect.y
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
    }*/
    
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
}
