//
//  Font.swift
//  Denrim
//
//  Created by Markus Moenig on 4/9/20.
//

import MetalKit

struct BMChar       : Decodable {
    let id          : Int
    let index       : Int
    let char        : String
    let width       : Float
    let height      : Float
    let xoffset     : Float
    let yoffset     : Float
    let xadvance    : Float
    let chnl        : Int
    let x           : Float
    let y           : Float
    let page        : Int
}

struct BMCommon     : Decodable {
    let lineHeight  : Float
}

struct BMFont       : Decodable {
    let pages       : [String]
    let chars       : [BMChar]
    let common      : BMCommon
}

class Font
{
    var uuid        = UUID()
    
    var name        : String
    var game        : Game
    
    var atlas       : MTLTexture?
    var bmFont      : BMFont?

    init(name: String, game: Game)
    {
        self.name = name
        self.game = game
                
        atlas = loadTexture( name )
        
        let path = Bundle.main.path(forResource: name, ofType: "json")!
        let data = NSData(contentsOfFile: path)! as Data
        
        guard let font = try? JSONDecoder().decode(BMFont.self, from: data) else {
            print("Error: Could not decode JSON of \(name)")
            return
        }
        bmFont = font
    }
    
    deinit {
        if let texture = atlas {
            texture.setPurgeableState(.empty)
            atlas = nil
            bmFont = nil
        }
    }
    
    /*
    func createTextBuffer(_ object: [AnyHashable:Any]) -> TextBuffer
    {
        /*
        //var x : Float; if let v = object["x"] as? Float { x = v } else { x = 0 }
        //var y : Float; if let v = object["y"] as? Float { y = v } else { y = 0 }
        let size : Float; if let v = object["size"] as? Float { size = v } else { size = 1 }
        let text : String; if let v = object["text"] as? String { text = v } else { text = "" }

        var array : [CharBuffer] = []
        
        //if textBuffer != nil {
        //    print("No buffer for", text, textBuffer, textBuffer!.x, x, textBuffer!.y, y)
        //}

        for c in text {
            let bmChar = getItemForChar( c )
            if bmChar != nil {
                //let char = drawChar( font, char: bmChar!, x: posX + bmChar!.xoffset * adjScale, y: y + bmChar!.yoffset * adjScale, color: color, scale: scale, fragment: fragment)
                array.append(char)
                //print( bmChar?.char, bmChar?.x, bmChar?.y, bmChar?.width, bmChar?.height)
                posX += bmChar!.xadvance * adjScale;
            
            }
        }
        */
    
        return TextBuffer(chars:array, x: x, y: y, viewWidth: mmRenderer.width, viewHeight: mmRenderer.height)
    }*/
    
    func loadTexture(_ name: String, mipmaps: Bool = false, sRGB: Bool = false ) -> MTLTexture?
    {
        let path = Bundle.main.path(forResource: name, ofType: "tiff")!
        let data = NSData(contentsOfFile: path)! as Data
        
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : mipmaps, .SRGB : sRGB]
        
        return try? game.textureLoader.newTexture(data: data, options: options)
    }
    
    func getLineHeight(_ fontScale: Float) -> Float
    {
        return (bmFont!.common.lineHeight * fontScale) / 2
    }
    
    func getItemForChar(_ char: Character ) -> BMChar?
    {
        let array = bmFont!.chars
        
        for item in array {
            if Character( item.char ) == char {
                return item
            }
        }
        return nil
    }
    
    @discardableResult func getTextRect(text: String, scale: Float = 1.0, rectToUse: MMRect? = nil) -> MMRect
    {
        var rect : MMRect
        if rectToUse == nil {
            rect = MMRect()
        } else {
            rect = rectToUse!
        }
        
        rect.width = 0
        rect.height = 0
        
        for c in text {
            let bmChar = getItemForChar( c )
            if bmChar != nil {
                rect.width += bmChar!.xadvance * scale / 2;
                rect.height = max( rect.height, (bmChar!.height /*- bmChar!.yoffset*/) * scale / 2)
            }
        }
        
        return rect;
    }
}
