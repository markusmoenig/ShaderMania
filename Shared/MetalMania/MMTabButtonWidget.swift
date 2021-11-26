//
//  MMLabel.swift
//  Framework
//
//  Created by Markus Moenig on 09.01.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

class MMTabButtonItem
{
    var text        : String = ""

    var label       : MMTextLabel? = nil
    var rect        : MMRect = MMRect()
    
    init(text: String)
    {
        self.text = text
    }
}

class MMTabButtonWidget: MMWidget
{
    var items       : [MMTabButtonItem] = []
    var currentTab  : MMTabButtonItem? = nil
    var hoverTab    : MMTabButtonItem? = nil
    
    var hoverIndex  : Int = 0
    var index       : Int = 0

    var skin        : MMSkinButton
    var itemWidth   : Float = 0

    init( _ view: MMView, skinToUse: MMSkinButton? = nil)
    {
        skin = skinToUse != nil ? skinToUse! : view.skin.ToolBarButton
        super.init(view)
        
        rect.height = skin.height
    }
    
    func addTab(_ text: String)
    {
        let item = MMTabButtonItem(text: text)
        item.label = MMTextLabel(mmView, font: mmView.openSans, text: text, scale: skin.fontScale)
        items.append(item)
        if currentTab == nil {
            currentTab = item
        }
        calcWidth()
    }
    
    func calcWidth()
    {
        itemWidth = 0
        rect.width = 0

        for item in items {
            if item.label!.rect.width + 20 > itemWidth {
                itemWidth = item.label!.rect.width + 20
            }
        }
        
        rect.width += Float(items.count) * itemWidth
    }
    
    override func mouseMoved(_ event: MMMouseEvent) {
        let oldHoverTab : MMTabButtonItem? = hoverTab
        hoverTab = nil
        for (index, item) in items.enumerated() {
            if item.rect.contains(event.x, event.y) {
                hoverTab = item
                hoverIndex = index
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
            currentTab = hoverTab
            index = hoverIndex
            if super.clicked != nil {
                super.clicked!(event)
            }
        }
    }
    
    func draw(xOffset: Float = 0)
    {
        if items.count == 0 { return }
                
        mmView.drawBox.draw( x: rect.x, y: rect.y, width: rect.width, height: rect.height, round: skin.round, borderSize: 1.5, fillColor: SIMD4<Float>(0,0,0,0), borderColor: skin.borderColor)
        
        var xOff : Float = 0
        for (index, item) in items.enumerated() {
            
            item.rect.x = rect.x + xOff + xOffset
            item.rect.y = rect.y
            item.rect.width = itemWidth
            item.rect.height = rect.height

            if item === currentTab || item === hoverTab {
                
                if index == 0 {
                    mmView.renderer.setClipRect(MMRect(rect.x, rect.y, item.rect.width, item.rect.height))
                } else {
                    mmView.renderer.setClipRect(MMRect(item.rect.x, item.rect.y, item.rect.width + 16, item.rect.height))
                }
                
                mmView.drawBox.draw( x: rect.x, y: rect.y, width: rect.width, height: rect.height, round: skin.round, borderSize: 0, fillColor: item === currentTab ? mmView.skin.Button.borderColor : mmView.skin.Button.hoverColor)
                
                mmView.renderer.setClipRect()
            }
            
            item.label!.drawCentered(x: item.rect.x, y: item.rect.y - 1, width: item.rect.width, height: item.rect.height)
            
            xOff += itemWidth
        }
    }
}
