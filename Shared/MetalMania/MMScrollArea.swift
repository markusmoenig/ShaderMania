//
//  MMScrollArea.swift
//  Framework
//
//  Created by Markus Moenig on 12/1/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

class MMScrollArea : MMWidget
{
    enum MMScrollAreaOrientation {
        case Horizontal, Vertical
    }
    
    var offsetX     : Float
    var offsetY     : Float
    var offsetZ     : Float
    
    var dispatched  : Bool
    var orientation : MMScrollAreaOrientation
    
    var widget      : MMWidget?

    init(_ view: MMView, orientation: MMScrollAreaOrientation, widget: MMWidget? = nil)
    {
        offsetX = 0
        offsetY = 0
        offsetZ = 0
        dispatched = false
        self.orientation = orientation
        self.widget = widget
        super.init(view)
        
        name = "MMScrollArea"
    }
    
    func build( widget: MMWidget, area: MMRect, xOffset: Float = 0, yOffset: Float = 0 )
    {
        mmView.renderer.setClipRect( area )
        if orientation == .Vertical {
            
            rect.copy( area )
            
            switch( orientation )
            {
                case .Vertical:
                
                    let wHeight = widget.rect.height / widget.zoom
                    widget.rect.x = area.x + xOffset
                                        
                    // --- Check bounds
                    
                    if offsetY < -(wHeight-area.height) {
                        offsetY = -(wHeight-area.height)
                    }
                    
                    if offsetY > 0 {
                        offsetY = 0
                    }
                    
                    widget.rect.y = area.y + offsetY
                
                case .Horizontal:
                    let wWidth = widget.rect.width / widget.zoom
                
                    widget.rect.y = area.y + yOffset
                    
                    // --- Check bounds
                    
                    if offsetX < -(wWidth-area.width) {
                        offsetX = -(wWidth-area.width)
                    }
                    
                    if offsetX > 0 {
                        offsetX = 0
                    }
                    
                    widget.rect.x = area.x + offsetX
            }
            widget.draw()
        }
        mmView.renderer.setClipRect()
    }
    
    override func mouseScrolled(_ event: MMMouseEvent)
    {
        offsetY += event.deltaY! * 4
        
        if !dispatched {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.mmView.unlockFramerate()
                self.dispatched = false
            }
            dispatched = true
        }
        
        if mmView.maxFramerateLocks == 0 {
            mmView.lockFramerate()
        }
    }
    
    override func draw(xOffset: Float = 0, yOffset: Float = 0)
    {
        if widget != nil {
            build(widget: widget!, area: rect, xOffset: xOffset)
        }
    }
}
