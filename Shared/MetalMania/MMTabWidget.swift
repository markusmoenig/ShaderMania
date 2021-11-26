//
//  MMLabel.swift
//  Framework
//
//  Created by Markus Moenig on 09.01.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

class MMTabItem
{
    var text        : String = ""

    var label       : MMTextLabel? = nil
    var widget      : MMWidget? = nil
    var rect        : MMRect = MMRect()
    
    init(text: String, widget: MMWidget)
    {
        self.text = text
        self.widget = widget
    }
}

class MMTabWidget: MMWidget
{
    var items       : [MMTabItem] = []
    var currentTab  : MMTabItem? = nil
    var hoverTab    : MMTabItem? = nil

//    override init( _ view: MMView )
//    {
//        super.init(view)
//    }
    
    func addTab(_ text: String, widget: MMWidget)
    {
        let item = MMTabItem(text: text, widget: widget)
        item.label = MMTextLabel(mmView, font: mmView.openSans, text: text, scale: 0.4 )//color: float4(0.506, 0.506, 0.506, 1.000))
        items.append(item)
        if currentTab == nil {
            currentTab = item
        }
    }
    
    override func mouseMoved(_ event: MMMouseEvent) {
        let oldHoverTab : MMTabItem? = hoverTab
        hoverTab = nil
        for item in items {
            if item.rect.contains(event.x, event.y) {
                hoverTab = item
                break
            }
        }
        
        if oldHoverTab !== hoverTab {
            mmView.update()
        }
    }
    
    override func mouseDown(_ event: MMMouseEvent) {
        mouseMoved(event)
        if hoverTab != nil {
            if currentTab != nil {
                mmView.deregisterWidget(currentTab!.widget!)
            }
            currentTab = hoverTab
            mmView.registerWidget(currentTab!.widget!)
        }
    }
    
    func draw(xOffset: Float = 0)
    {
        let headerHeight : Float = 25
        if items.count == 0 { return }
        
        let itemWidth = (rect.width - xOffset) / Float(items.count)
        
        mmView.drawBox.draw( x: rect.x, y: rect.y + 2, width: rect.width, height: headerHeight, round: 20, borderSize: 1.5, fillColor: SIMD4<Float>(0,0,0,0), borderColor: mmView.skin.Button.borderColor)
        
        var xOff : Float = 0
        for (index, item) in items.enumerated() {
            
            item.rect.x = rect.x + xOff + xOffset
            item.rect.y = rect.y + 2
            item.rect.width = itemWidth// + xOffset
            item.rect.height = headerHeight

            //let fColor : float4
            //let skin = mmView.skin.MenuWidget

            //if item === hoverTab {
                //fColor = skin.button.hoverColor
            //} else
            if item === currentTab || item === hoverTab {
                //fColor = skin.button.activeColor
                
                if index == 0 {
                    mmView.renderer.setClipRect(MMRect(max(rect.x + xOffset,0), rect.y + 2, max(item.rect.width + xOffset,0), item.rect.height))
                } else {
                    mmView.renderer.setClipRect(MMRect(max(item.rect.x,0), item.rect.y, item.rect.width, item.rect.height))
                }
                
                mmView.drawBox.draw( x: rect.x, y: rect.y + 2, width: rect.width, height: headerHeight, round: 20, borderSize: 0, fillColor: item === currentTab ? mmView.skin.Button.borderColor : mmView.skin.Button.hoverColor)
                
                mmView.renderer.setClipRect()
            } else {
                //fColor = float4(repeating:0)
            }
            
            //mmView.drawBox.draw( x: item.rect.x, y: rect.y, width: item.rect.width, height: item.rect.height, round: 8, borderSize: 1, fillColor : fColor, borderColor: float4( 0, 0, 0, 0 ) )
            
            item.label!.drawCentered(x: item.rect.x, y: item.rect.y - 1, width: item.rect.width, height: item.rect.height)
            
            xOff += itemWidth
        }
        
        if let item = currentTab {
            item.widget!.rect.x = rect.x
            item.widget!.rect.y = rect.y + headerHeight
            item.widget!.rect.width = rect.width
            item.widget!.rect.height = rect.height - headerHeight
            item.widget!.draw(xOffset: xOffset)
        }
        rect.height = headerHeight
    }
    
    /// Registers the current widget (if any)
    func registerWidget()
    {
        if currentTab != nil {
            mmView.registerWidget(currentTab!.widget!)
        }
    }
    
    /// Deregisters the current widget (if any)
    func deregisterWidget()
    {
        if currentTab != nil {
            mmView.deregisterWidget(currentTab!.widget!)
        }
    }
}
