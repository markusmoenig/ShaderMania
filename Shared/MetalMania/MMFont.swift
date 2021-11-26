//
//  MMFont.swift
//  Framework
//
//  Created by Markus Moenig on 07.01.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

struct BMChar: Decodable {
    let id : Int
    let index : Int
    let char : String
    let width : Float
    let height : Float
    let xoffset : Float
    let yoffset : Float
    let xadvance : Float
    let chnl : Int
    let x : Float
    let y : Float
    let page : Int
}

struct BMFont: Decodable {
    let pages: [String]
    let chars: [BMChar]
}

/// Button widget class which handles all buttons
class MMFont
{
    var mmView: MMView
    var atlas : MTLTexture?
    var bmFont : BMFont?

    init( _ view: MMView, name: String )
    {
        mmView = view
        atlas = mmView.loadTexture( name )
        
        let path = Bundle.main.path(forResource: name, ofType: "json")!
        let data = NSData(contentsOfFile: path)! as Data
        
        guard let font = try? JSONDecoder().decode(BMFont.self, from: data) else {
            print("Error: Could not decode JSON of \(name)")
            return
        }
        bmFont = font
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
    
    @discardableResult func getTextRect( text: String, scale: Float = 1.0, rectToUse: MMRect? = nil ) -> MMRect
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
