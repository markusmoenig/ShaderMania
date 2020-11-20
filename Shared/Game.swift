//
//  Game.swift
//  ShaderMania
//
//  Created by Markus Moenig on 25/8/20.
//

import MetalKit
import Combine
import AVFoundation

public class Game       : ObservableObject
{
    enum State {
        case Idle, Running, Paused
    }
    
    var state           : State = .Idle
    
    var view            : DMTKView!
    var device          : MTLDevice!

    var texture         : Texture2D? = nil
    var metalStates     : MetalStates!
    
    var viewportSize    : vector_uint2
    var scaleFactor     : Float
    
    var assetFolder     : AssetFolder!
    
    var screenWidth     : Float = 0
    var screenHeight    : Float = 0

    var gameCmdQueue    : MTLCommandQueue? = nil
    var gameCmdBuffer   : MTLCommandBuffer? = nil
    var gameScissorRect : MTLScissorRect? = nil
    
    var scriptEditor    : ScriptEditor? = nil

    var shaderCompiler  : ShaderCompiler!

    var textureLoader   : MTKTextureLoader!
        
    var resources       : [AnyObject] = []
    var availableFonts  : [String] = ["OpenSans", "Square", "SourceCodePro"]
    var fonts           : [Font] = []
    
    var _Time           = Float1(0)
    var _Aspect          = Float2(1,1)
    var targetFPS       : Float = 60
    
    var gameAsset       : Asset? = nil

    // Preview Size, UI only
    var previewFactor   : CGFloat = 4
    var previewOpacity  : Double = 0.5
    
    var contextText     : String = ""
    var contextKey      : String = ""
    let contextTextChanged = PassthroughSubject<String, Never>()
    
    let timeChanged     = PassthroughSubject<Float, Never>()

    let createPreview   = PassthroughSubject<Void, Never>()

    var helpText        : String = ""
    let helpTextChanged = PassthroughSubject<Void, Never>()

    var assetError      = CompileError()
    let gameError       = PassthroughSubject<Void, Never>()
    
    var localAudioPlayers: [String:AVAudioPlayer] = [:]
    var globalAudioPlayers: [String:AVAudioPlayer] = [:]
    
    var showingDebugInfo: Bool = false
    
    var frameworkId     : String? = nil
    
    var project         : Project? = nil

    public init(_ frameworkId: String? = nil)
    {
        self.frameworkId = frameworkId
        
        viewportSize = vector_uint2( 0, 0 )
        
        #if os(OSX)
        scaleFactor = Float(NSScreen.main!.backingScaleFactor)
        #else
        scaleFactor = Float(UIScreen.main.scale)
        #endif
                
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
        view.game = self
        
        metalStates = MetalStates(self)
        textureLoader = MTKTextureLoader(device: device)
        
        /*
        for fontName in availableFonts {
            let font = Font(name: fontName, game: self)
            fonts.append(font)
        }*/
        
        view.platformInit()
        checkTexture()
        
        assetFolder.assetCompileAll()
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
        
        _Aspect.x = 1
        _Aspect.y = 1

        state = .Running
        view.enableSetNeedsDisplay = false
        view.isPaused = false
            
        _Time.x = 0
        targetFPS = 60
    }
    
    func stop()
    {
        clearLocalAudio()
        clearGlobalAudio()
        
        if let scriptEditor = scriptEditor {
            scriptEditor.setReadOnly(false)
        }
        
        gameAsset = nil
                
        if let scriptEditor = scriptEditor, assetError.error == nil {
            scriptEditor.clearAnnotations()
        }
        
        state = .Idle
        view.isPaused = true
        
        _Time.x = 0
        //timeChanged.send(_Time.x)
    }
    
    @discardableResult func checkTexture() -> Bool
    {
        if texture == nil || texture!.texture.width != Int(view.frame.width) || texture!.texture.height != Int(view.frame.height) {
            
            if texture == nil {
                texture = Texture2D(self)
            } else {
                texture?.allocateTexture(width: Int(view.frame.width), height: Int(view.frame.height))
            }
            
            viewportSize.x = UInt32(texture!.width)
            viewportSize.y = UInt32(texture!.height)
            
            screenWidth = Float(texture!.width)
            screenHeight = Float(texture!.height)
            
            gameScissorRect = MTLScissorRect(x: 0, y: 0, width: texture!.texture.width, height: texture!.texture.height)
                        
            //if let map = currentMap?.map {
            //    map.setup(game: self)
            //}
            return true
        }
        return false
    }
    
    public func draw()
    {
        guard let drawable = view.currentDrawable else {
            return
        }
                
        if state == .Idle {
            if let asset = assetFolder.current {
                checkTexture()
                if asset.type == .Texture {
                    createPreview(asset, false)
            
                    startDrawing()
                    let renderPassDescriptor = view.currentRenderPassDescriptor
                    renderPassDescriptor?.colorAttachments[0].loadAction = .load
                    let renderEncoder = gameCmdBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
                    
                    drawTexture(texture!.texture!, renderEncoder: renderEncoder!)
                    renderEncoder?.endEncoding()
                    
                    gameCmdBuffer?.present(drawable)
                    stopDrawing()

                    return
                }
            }
        } else {
            _Time.x += 1.0 / targetFPS
            //timeChanged.send(_Time.x)
        }
                
        if let texture = project?.render(assetFolder: assetFolder, device: device, time: _Time.x, viewSize: SIMD2<Int>(Int(view.frame.width), Int(view.frame.height)), breakAsset: state == .Idle ? assetFolder.current : nil) {
            
            let renderPassDescriptor = view.currentRenderPassDescriptor
            renderPassDescriptor?.colorAttachments[0].loadAction = .load
            let renderEncoder = project!.commandBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
            
            drawTexture(texture, renderEncoder: renderEncoder!)
            renderEncoder?.endEncoding()
            
            project!.commandBuffer!.present(drawable)
        }
        project?.stopDrawing()
    }
    
    func startDrawing()
    {
        if gameCmdQueue == nil {
            gameCmdQueue = view.device!.makeCommandQueue()
        }
        gameCmdBuffer = gameCmdQueue!.makeCommandBuffer()
    }
    
    func stopDrawing(deleteQueue: Bool = false)
    {
        gameCmdBuffer?.commit()

        if deleteQueue {
            self.gameCmdQueue = nil
        }
        self.gameCmdBuffer = nil
    }
    
    /// Create a preview for the current asset
    func createPreview(_ asset: Asset, _ update: Bool = true)
    {
        if state == .Idle {
            clearLocalAudio()
            if asset.type == .Buffer || asset.type == .Shader {
                updateOnce()
            } else
            if asset.type == .Shader {
                if let shader = asset.shader {
                    startDrawing()
                    
                    let rect = MMRect( 0, 0, self.texture!.width, self.texture!.height, scale: 1 )
                    texture?.clear()
                    texture?.drawShader(shader, rect)
                    
                    stopDrawing()
                    updateOnce()
                }
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
                
                    let data = asset.data[asset.dataIndex]
                    
                    let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                    if let texture  = try? textureLoader.newTexture(data: data, options: texOptions) {
                        let texture2D = Texture2D(self, texture: texture)
                        
                        self.startDrawing()
                        var options : [String:Any] = [:]
                        options["texture"] = texture2D
                        
                        let width : Float = texture2D.width * Float(asset.dataScale)
                        let height : Float = texture2D.height * Float(asset.dataScale)

                        options["width"] = width
                        options["height"] = height

                        self.texture?.clear()
                        self.texture?.drawTexture(options)
                        self.stopDrawing()
                        if update {
                            self.updateOnce()
                        }
                                                                        
                        if let scriptEditor = self.scriptEditor {
                            let text = """

                            Displaying image group \(asset.name) index \(asset.dataIndex) of \(asset.data.count)
                            
                            Image resolution \(Int(texture2D.width))x\(Int(texture2D.height))

                            Preview resolution \(Int(width))x\(Int(height))

                            Scale \(String(format: "%.02f", asset.dataScale))

                            """
                            scriptEditor.setAssetValue(asset, value: text)
                        }
                    }
                }
            } else if asset.type == .Texture {
                
                if asset.data.count == 0 {
                    if let scriptEditor = self.scriptEditor {
                        let text = """

                        This texture will be automatically set to the output resolution.

                        """
                        scriptEditor.setAssetValue(asset, value: text)
                        
                        self.startDrawing()
                        self.texture?.clear()
                        self.stopDrawing()

                        if update {
                            self.updateOnce()
                        }
                    }
                } else {
                    let data = asset.data[0]
                    
                    let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                    if let texture  = try? textureLoader.newTexture(data: data, options: texOptions) {
                        let texture2D = Texture2D(self, texture: texture)
                        
                        self.startDrawing()
                        var options : [String:Any] = [:]
                        options["texture"] = texture2D
                        
                        let width : Float = texture2D.width * Float(asset.dataScale)
                        let height : Float = texture2D.height * Float(asset.dataScale)

                        options["width"] = width
                        options["height"] = height

                        self.texture?.clear()
                        self.texture?.drawTexture(options)
                        self.stopDrawing()
                        if update {
                            self.updateOnce()
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
}
