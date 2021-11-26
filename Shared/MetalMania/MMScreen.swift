//
//  MMScreen.swift
//  Shape-Z
//
//  Created by Markus Moenig on 15.05.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit
/*
class MMScreen : MMWidget {
    
    // Mouse position in view coordinates
    var mousePos        : SIMD2<Float> = SIMD2<Float>(0,0)
    var mouseDownPos    : SIMD2<Float> = SIMD2<Float>(0,0)
    
    var mouseDown       : Bool = false
    
    override init(_ view: MMView)
    {
        super.init(view)
    }
    
    func tranformToCamera(_ pos: float2, _ camera: Camera) -> float2?
    {
        if !rect.contains(pos.x, pos.y) { return nil }
        
        var result = float2(pos.x - rect.x, pos.y - rect.y)
        
        result.x -= rect.width / 2 - camera.xPos
        result.y += camera.yPos
        result.y -= rect.width / 2 * rect.height / rect.width
        
        result *= 1/camera.zoom

        return result
    }
}
*/
