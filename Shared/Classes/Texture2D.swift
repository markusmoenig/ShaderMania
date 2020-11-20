//
//  Texture2D.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import MetalKit

class Texture2D                 : NSObject
{
    var texture                 : MTLTexture!
    
    var width                   : Float = 0
    var height                  : Float = 0
    
    var game                    : Game!

    ///
    init(_ game: Game)
    {
        self.game = game
        
        super.init()
        allocateTexture(width: Int(game.view.frame.width), height: Int(game.view.frame.height))
    }
    
    init(_ game: Game, width: Int, height: Int)
    {
        self.game = game
        
        super.init()
        allocateTexture(width: width, height: height)
    }
    
    init(_ game: Game, texture: MTLTexture)
    {
        self.game = game
        self.texture = texture
        
        width = Float(texture.width)
        height = Float(texture.height)
                        
        super.init()
    }
    
    deinit
    {
        print("release texture")
        if texture != nil {
            texture!.setPurgeableState(.empty)
            texture = nil
        }
    }

    func allocateTexture(width: Int, height: Int)
    {
        if texture != nil {
            texture!.setPurgeableState(.empty)
            texture = nil
        }
            
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        textureDescriptor.width = width == 0 ? 1 : width
        textureDescriptor.height = height == 0 ? 1 : height
        
        self.width = Float(width)
        self.height = Float(height)
        
        textureDescriptor.usage = MTLTextureUsage.unknown
        
        texture = game.device.makeTexture(descriptor: textureDescriptor)
    }
    
    /*
    class func main() -> Texture2D
    {
        let context = JSContext.current()
        let main = context?.objectForKeyedSubscript("_mT")?.toObject() as! Texture2D
        
        return main
    }*/
    
    /*
    class func create(_ object: [AnyHashable:Any]) -> JSPromise
    {
        let context = JSContext.current()
        let promise = JSPromise()

        DispatchQueue.main.async {
            let main = context?.objectForKeyedSubscript("_mT")?.toObject() as! Texture2D
            var texture : Texture2D? = nil
            let game = main.game!
            
            if let imageName = object["name"] as? String {
             
                if let asset = game.assetFolder.getAsset(imageName, .Image) {
                    let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : false]

                    if let mtlTexture = try? game.textureLoader.newTexture(data: asset.data[0], options: options) {
                        texture = Texture2D(game, texture: mtlTexture)
                        game.resources.append(texture!)
                        promise.success(value: texture)
                    } else {
                        promise.fail(error: "Image cannot be decoded")
                    }
                } else {
                    promise.fail(error: "Image not found")
                }
            } else {
                promise.fail(error: "Image name not specified")
            }
            
            if texture == nil {
                texture = Texture2D(main.game, width: 10, height: 10)
            }
        }
        
        return promise
    }*/
    
    func clear(_ clearColor: Float4? = nil)
    {
        let color : SIMD4<Float>; if let v = clearColor { color = v.toSIMD() } else { color = SIMD4<Float>(0,0,0,1) }

        let renderPassDescriptor = MTLRenderPassDescriptor()

        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(Double(color.x), Double(color.y), Double(color.z), Double(color.w))
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.endEncoding()
    }
    
    func drawChecker()
    {
        var x : Float = 0
        var y : Float = 0
        let width : Float = self.width * game.scaleFactor
        let height : Float = self.height * game.scaleFactor
        let round : Float = 0
        let border : Float = 0
        let rotation : Float = 0
        let onion : Float = 0
        let fillColor : SIMD4<Float> = SIMD4<Float>(0.306, 0.310, 0.314, 1.000)
        let borderColor : SIMD4<Float> = SIMD4<Float>(0.216, 0.220, 0.224, 1.000)

        x /= game.scaleFactor
        y /= game.scaleFactor

        var data = BoxUniform()
        data.onion = onion / game.scaleFactor
        data.size = float2(width / game.scaleFactor, height / game.scaleFactor)
        data.round = round / game.scaleFactor
        data.borderSize = border / game.scaleFactor
        data.fillColor = fillColor
        data.borderColor = borderColor
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        data.pos.x = x
        data.pos.y = y
        data.rotation = rotation.degreesToRadians
        data.screenSize = float2(self.width / game.scaleFactor, self.height / game.scaleFactor)

        let rect = MMRect(0, 0, self.width / game.scaleFactor, self.height / game.scaleFactor, scale: game.scaleFactor)
        let vertexData = game.createVertexData(texture: self, rect: rect)
                                
        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

        renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
        renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawBackPattern))
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        renderEncoder.endEncoding()
    }
    
    func drawDisk(_ options: [String:Any])
    {
        var position : SIMD2<Float>; if let v = options["position"] as? Float2 { position = v.toSIMD() } else { position = SIMD2<Float>(0,0) }
        let radius : Float; if let v = options["radius"] as? Float { radius = v } else { radius = 100 }
        let border : Float; if let v = options["border"] as? Float { border = v } else { border = 0 }
        let onion : Float;  if let v = options["onion"] as? Float { onion = v } else { onion = 0 }
        let fillColor : SIMD4<Float>; if let v = options["color"] as? Float4 { fillColor = v.toSIMD() } else { fillColor = SIMD4<Float>(1,1,1,1) }
        let borderColor : SIMD4<Float>; if let v = options["bordercolor"] as? Float4 { borderColor = v.toSIMD() } else { borderColor = SIMD4<Float>(0,0,0,0) }
        
        position.y = -position.y
        position.x /= game.scaleFactor
        position.y /= game.scaleFactor
        
        var data = DiscUniform()
        data.borderSize = border / game.scaleFactor
        data.radius = radius / game.scaleFactor
        data.fillColor = fillColor
        data.borderColor = borderColor
        data.onion = onion / game.scaleFactor

        let rect = MMRect(position.x - data.borderSize / 2, position.y - data.borderSize / 2, data.radius * 2 + data.borderSize * 2, data.radius * 2 + data.borderSize * 2, scale: game.scaleFactor )
        let vertexData = game.createVertexData(texture: self, rect: rect)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                
        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
        
        renderEncoder.setFragmentBytes(&data, length: MemoryLayout<DiscUniform>.stride, index: 0)
        renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawDisc))
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
    }
    
    func drawBox(_ options: [String:Any])
    {
        var position : SIMD2<Float>; if let v = options["position"] as? Float2 { position = v.toSIMD() } else { position = SIMD2<Float>(0,0) }
        var size : SIMD2<Float>; if let v = options["size"] as? Float2 { size = v.toSIMD() } else { size = SIMD2<Float>(1,1) }
        let round : Float; if let v = options["round"] as? Float { round = v } else { round = 0 }
        let border : Float; if let v = options["border"] as? Float { border = v } else { border = 0 }
        let rotation : Float; if let v = options["rotation"] as? Float { rotation = v } else { rotation = 0 }
        let onion : Float;  if let v = options["onion"] as? Float { onion = v } else { onion = 0 }
        let fillColor : SIMD4<Float>; if let v = options["color"] as? Float4 { fillColor = v.toSIMD() } else { fillColor = SIMD4<Float>(1,1,1,1) }
        let borderColor : SIMD4<Float>; if let v = options["bordercolor"] as? Float4 { borderColor = v.toSIMD() } else { borderColor = SIMD4<Float>(0,0,0,0) }

        position.y = -position.y;
        position.x /= game.scaleFactor
        position.y /= game.scaleFactor

        var data = BoxUniform()
        data.onion = onion / game.scaleFactor
        data.size = float2(size.x / game.scaleFactor, size.y / game.scaleFactor)
        data.round = round / game.scaleFactor
        data.borderSize = border / game.scaleFactor
        data.fillColor = fillColor
        data.borderColor = borderColor
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        if rotation == 0 {
            let rect = MMRect(position.x, position.y, data.size.x, data.size.y, scale: game.scaleFactor)
            let vertexData = game.createVertexData(texture: self, rect: rect)
            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawBox))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        } else {
            data.pos.x = position.x
            data.pos.y = position.y
            data.rotation = rotation.degreesToRadians
            data.screenSize = float2(self.width / game.scaleFactor, self.height / game.scaleFactor)

            let rect = MMRect(0, 0, self.width / game.scaleFactor, self.height / game.scaleFactor, scale: game.scaleFactor)
            let vertexData = game.createVertexData(texture: self, rect: rect)
                                    
            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawBoxExt))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
        renderEncoder.endEncoding()
    }
    
    func drawTexture(_ options: [String:Any])
    {
        if let sourceTexture = options["texture"] as? Texture2D {
            
            var position : SIMD2<Float>; if let v = options["position"] as? Float2 { position = v.toSIMD() } else { position = SIMD2<Float>(0,0) }
            var width : Float; if let v = options["width"] as? Float { width = v } else { width = Float(sourceTexture.width) }
            var height : Float; if let v = options["height"] as? Float { height = v } else { height = Float(sourceTexture.height) }
            let alpha : Float; if let v = options["alpha"] as? Float { alpha = v } else { alpha = 1.0 }
            
            let subRect : Rect2D?; if let v = options["rect"] as? Rect2D { subRect = v } else { subRect = nil }

            position.y = -position.y;
            position.x /= game.scaleFactor
            position.y /= game.scaleFactor
            
            width /= game.scaleFactor
            height /= game.scaleFactor
            
            var data = TextureUniform()
            data.globalAlpha = alpha
            
            if let subRect = subRect {
                data.pos.x = subRect.x / sourceTexture.width
                data.pos.y = subRect.y / sourceTexture.height
                data.size.x = subRect.width / sourceTexture.width// / game.scaleFactor
                data.size.y = subRect.height / sourceTexture.height// / game.scaleFactor
            } else {
                data.pos.x = 0
                data.pos.y = 0
                data.size.x = 1
                data.size.y = 1
            }
                    
            let rect = MMRect( position.x, position.y, width, height, scale: game.scaleFactor )
            let vertexData = game.createVertexData(texture: self, rect: rect)
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
            renderPassDescriptor.colorAttachments[0].texture = texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            
            let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
            
            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<TextureUniform>.stride, index: 0)
            renderEncoder.setFragmentTexture(sourceTexture.texture, index: 1)

            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawTexture))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
        }
    }
    
    func drawShader(_ shader: Shader, _ rect: MMRect)
    {
        let vertexData = game.createVertexData(texture: self, rect: rect)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

        var metalData = MetalData()
        metalData.time = game._Time.x;
        renderEncoder.setFragmentBytes(&metalData, length: MemoryLayout<MetalData>.stride, index: 0)

        renderEncoder.setRenderPipelineState(shader.pipelineState)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
    }
    
    func drawShader(_ object: [AnyHashable:Any])
    {
        if let shader = object["shader"] as? Shader, shader.isValid {
            
            let subRect : Rect2D?; if let v = object["subRect"] as? Rect2D { subRect = v } else { subRect = nil }
            
            let rect : MMRect

            if let subRect = subRect {
                rect = MMRect(subRect.x, subRect.y, subRect.width, subRect.height, scale: 1)
            } else {
                rect = MMRect( 0, 0, self.width, self.height, scale: game.scaleFactor )
            }
            
            drawShader(shader, rect)
        }
    }
    
    /// Draws the given text
    func drawText(_ options: [String:Any])
    {
        var position : SIMD2<Float>; if let v = options["position"] as? Float2 { position = v.toSIMD() } else { position = SIMD2<Float>(0,0) }
        let size : Float; if let v = options["size"] as? Float { size = v } else { size = 30 }
        let text : String; if let v = options["text"] as? String { text = v } else { text = "" }
        let font : Font?; if let v = options["font"] as? Font { font = v } else { font = nil }
        let color : SIMD4<Float>; if let v = options["color"] as? Float4 { color = v.toSIMD() } else { color = SIMD4<Float>(1,1,1,1) }

        position.y = -position.y;
        let scaleFactor : Float = game.scaleFactor
        
        func drawChar(char: BMChar, x: Float, y: Float, adjScale: Float)
        {
            var data = TextUniform()
            
            data.atlasSize.x = Float(font!.atlas!.width) * scaleFactor
            data.atlasSize.y = Float(font!.atlas!.height) * scaleFactor
            data.fontPos.x = char.x * scaleFactor
            data.fontPos.y = char.y * scaleFactor
            data.fontSize.x = char.width * scaleFactor
            data.fontSize.y = char.height * scaleFactor
            data.color = color

            let rect = MMRect(x, y, char.width * adjScale, char.height * adjScale, scale: scaleFactor)
            let vertexData = game.createVertexData(texture: self, rect: rect)
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = texture
            renderPassDescriptor.colorAttachments[0].loadAction = .load
            
            let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<TextUniform>.stride, index: 0)
            renderEncoder.setFragmentTexture(font!.atlas, index: 1)

            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawTextChar))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
        }
        
        if let font = font {
         
            let scale : Float = (1.0 / font.bmFont!.common.lineHeight) * size
            let adjScale : Float = scale// / 2
            
            var posX = position.x / game.scaleFactor
            let posY = position.y / game.scaleFactor

            for c in text {
                let bmChar = font.getItemForChar( c )
                if bmChar != nil {
                    drawChar(char: bmChar!, x: posX + bmChar!.xoffset * adjScale, y: posY + bmChar!.yoffset * adjScale, adjScale: adjScale)
                    posX += bmChar!.xadvance * adjScale;
                }
            }
        }
    }
}
