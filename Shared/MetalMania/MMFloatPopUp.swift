//
//  MMFloatPopUp.swift
//  Framework
//
//  Created by Markus Moenig on 04/10/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

class MMFloatPopUp : MMWidget
{
    var value       : Float
    var range       : float2!
    var mouseIsDown : Bool = false

    var changed     : ((_ value: Float, _ continuous: Bool)->())?

    init(_ view: MMView, range: float2 = float2(0,1), value: Float = 0)
    {
        self.range = range
        self.value = value
        super.init(view)
        
        name = "MMFloatPopUp"
        
        rect.width = 30
        rect.height = 28
    }
    
    func setState(_ state: MMWidgetStates)
    {
        if state == .Closed {
            rect.width = 30
            rect.height = 28
            removeState(.Opened)
        } else {
            rect.width = 230
            rect.height = 50
            addState(.Opened)
        }
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        mouseIsDown = true
        
        let perPixel = (range.y - range.x) / rect.width
        let oldValue = value
        
        value = range.x + perPixel * (event.x - rect.x)
        value = max( value, range.x)
        value = min( value, range.y)
        
        if changed != nil && oldValue != value {
            changed!(value, true)
        }
        
        mmView.lockFramerate()
        mmView.mouseTrackWidget = self
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
        if mouseIsDown {
            mouseIsDown = false
            
            let perPixel = (range.y - range.x) / rect.width
            
            value = range.x + perPixel * (event.x - rect.x)
            value = max( value, range.x)
            value = min( value, range.y)
            
            if changed != nil {
                changed!(value, false)
            }
        }
        
        mmView.unlockFramerate()
        mmView.mouseTrackWidget = nil
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
        if mouseIsDown {
            let perPixel = (range.y - range.x) / rect.width
            let oldValue = value

            value = range.x + perPixel * (event.x - rect.x)
            value = max( value, range.x)
            value = min( value, range.y)
            
            if changed != nil && oldValue != value {
                changed!(value, true)
            }
        }
    }
    
    override func draw(xOffset: Float = 0, yOffset: Float = 0)
    {
        let itemHeight = rect.height
        
        let skin = mmView.skin.MenuWidget
        
        mmView.drawBox.draw( x: rect.x, y: rect.y, width: rect.width, height: itemHeight, round: 0, borderSize: 1, fillColor : skin.color, borderColor: skin.borderColor )
        
        let offset = (rect.width / (range.y - range.x)) * (value - range.x)
        
        mmView.drawBox.draw( x: rect.x, y: rect.y, width: offset, height: itemHeight, round: 0, borderSize: 1, fillColor : float4( 0.4, 0.4, 0.4, 1), borderColor: skin.borderColor )
        
        if states.contains(.Opened) {
            mmView.drawText.drawTextCentered(mmView.openSans, text: String(format: "%.02f", value), x: rect.x, y: rect.y, width: rect.width, height: itemHeight, scale: 0.44, color: skin.textColor)
        }
    }
}

