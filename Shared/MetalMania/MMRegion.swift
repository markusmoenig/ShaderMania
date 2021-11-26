//
//  MMRegion.swift
//  Framework
//
//  Created by Markus Moenig on 04.01.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation

class MMRegion
{
    enum MMRegionType
    {
        case Left, Top, Right, Bottom, Editor
    }
    
    var rect        : MMRect
    let mmView      : MMView
    
    let type        : MMRegionType

    init( _ view: MMView, type: MMRegionType )
    {
        mmView = view
        rect = MMRect()
        
        self.type = type
    }
    
    func build()
    {
    }
    
    func layoutH(startX: Float, startY: Float, spacing: Float, widgets: MMWidget... )
    {
        var x : Float = startX
        for widget in widgets {
            widget.rect.x = x
            widget.rect.y = startY
            x += widget.rect.width + spacing
        }        
    }
    
    func layoutHFromRight(startX: Float, startY: Float, spacing: Float, widgets: MMWidget... )
    {
        var x : Float = startX
        for widget in widgets.reversed() {
            widget.rect.y = startY
            x -= widget.rect.width
            widget.rect.x = x
            x -= spacing
        }
    }
    
    func layoutV(startX: Float, startY: Float, spacing: Float, widgets: MMWidget... )
    {
        var y : Float = startY
        for widget in widgets {
            widget.rect.x = startX
            widget.rect.y = y
            y += widget.rect.height + spacing
        }
    }
    
    func registerWidgets(widgets: MMWidget... )
    {
        for widget in widgets {
            mmView.registerWidget(widget)
        }
    }
    
    func resize(width: Float, height: Float)
    {
    }
}
