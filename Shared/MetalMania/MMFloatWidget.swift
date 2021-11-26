//
//  MMFloatWidget.swift
//  Framework
//
//  Created by Markus Moenig on 04/5/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

/*
class MMFloatWidget : MMWidget
{
    var value       : Float
    var range       : float2!
    var mouseIsDown : Bool = false
    var int         : Bool = false

    var changed     : ((_ value: Float)->())?

    init(_ view: MMView, range: float2 = float2(0,1), int: Bool = false, value: Float = 0)
    {
        self.range = range
        self.value = value
        self.int = int
        super.init(view)
        
        name = "MMSliderWidget"
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
        let itemHeight = rect.height
        
        let skin = mmView.skin.MenuWidget
        
        mmView.drawBox.draw( x: rect.x, y: rect.y, width: rect.width, height: itemHeight, round: itemHeight, borderSize: 0, fillColor : skin.color, borderColor: NodeUI.contentColor)
        
        //let offset = (rect.width / (range.y - range.x)) * (value - range.x)
        
        //mmView.drawBox.draw( x: rect.x, y: rect.y, width: offset, height: itemHeight, round: 0, borderSize: 1, fillColor : float4( 0.4, 0.4, 0.4, 1), borderColor: skin.borderColor )
        
        if range != nil {
            let offset = (rect.width / (range!.y - range!.x)) * (value - range!.x)
            if offset > 0 {
                mmView.renderer.setClipRect(MMRect(rect.x, rect.y, offset, itemHeight))
                mmView.drawBox.draw( x: rect.x, y: rect.y, width: rect.width, height: itemHeight, round: itemHeight, borderSize: 0, fillColor : NodeUI.contentColor2)
                mmView.renderer.setClipRect()
            }
        }
        
        mmView.drawText.drawTextCentered(mmView.openSans, text: int ? String(Int(value)) : String(format: "%.02f", value), x: rect.x, y: rect.y, width: rect.width, height: itemHeight, scale: 0.44, color: skin.textColor)
    }
}
 
 */

