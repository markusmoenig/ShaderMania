//
//  MMFloatWidget.swift
//  Framework
//
//  Created by Markus Moenig on 04/5/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

class MMSliderWidget : MMWidget
{
    var value       : Float
    var range       : float2!
    var mouseIsDown : Bool = false
    var int         : Bool = false

    var changed     : ((_ value: Float)->())?

    init(_ view: MMView, range: SIMD2<Float> = SIMD2<Float>(0,1), int: Bool = false, value: Float = 0)
    {
        self.range = range
        self.value = value
        self.int = int
        super.init(view)
        
        name = "MMFloatWidget"
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        mouseIsDown = true
        
        let perPixel = (range.y - range.x) / rect.width
        let oldValue = value
        
        value = range.x + perPixel * (event.x - rect.x)
        value = max( value, range.x)
        value = min( value, range.y)
        
        if int {
            value = floor(value)
        }
        
        if changed != nil && oldValue != value {
            changed!(value)
        }
        
        mmView.lockFramerate()
        mmView.mouseTrackWidget = self
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
        mouseIsDown = false
        mmView.unlockFramerate()
        mmView.mouseTrackWidget = nil
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
        if mouseIsDown {
            mouseIsDown = true
            
            let perPixel = (range.y - range.x) / rect.width
            let oldValue = value

            value = range.x + perPixel * (event.x - rect.x)
            value = max( value, range.x)
            value = min( value, range.y)
            
            if int {
                value = floor(value)
            }
            
            if changed != nil && oldValue != value {
                changed!(value)
            }
        }
    }
    
    override func draw(xOffset: Float = 0, yOffset: Float = 0)
    {
        //let skin = mmView.skin.MenuWidget
        
        mmView.drawBox.draw( x: rect.x, y: rect.y + rect.height / 2 - 1, width: rect.width, height: 2, round: 0, borderSize: 0, fillColor: float4(0.094, 0.098, 0.102, 1.000))
        
        if range != nil {
            let offset = (rect.width / (range!.y - range!.x)) * (value - range!.x)
            let radius = rect.height / 2.5
            mmView.drawSphere.draw( x: rect.x + offset - radius, y: rect.y + rect.height / 2 - radius, radius: radius, borderSize: 0, fillColor: float4(0.573, 0.576, 0.580, 1.000))
        }
    }
}

