//
//  MMScrollWidget.swift
//  Shape-Z
//
//  Created by Markus Moenig on 12.04.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

class MMScrollButtonItem
{
    var label       : MMLabel?

    init( _ view: MMView, text: String, skin: MMSkinScrollButton)
    {
        label = MMTextLabel(view, font: view.openSans, text: text, scale: skin.fontScale )
    }
}

class MMScrollButton : MMWidget
{
    enum HoverMode {
        case None, LeftArrow, RightArrow
    }
    
    enum Animating {
        case No, Left, Right
    }
    
    var skin        : MMSkinScrollButton
    var label       : MMLabel?
    var items       : [MMScrollButtonItem] = []
    var contentWidth: Float = 0
    var maxItemWidth: Float = 0
    
    var hoverMode   : HoverMode = .None
    var animating   : Animating = .No
    
    var index       : Int = 0
    var animatingTo : Int = 0
    var animOffset  : Float = 0
    
    var changed : ((Int)->())? = nil
    
    static let spacer : Float = 70
    static let halfSpacer : Float = 30

    init( _ view: MMView, skinToUse: MMSkinScrollButton? = nil, items: [String], index: Int = 0)
    {
        skin = skinToUse != nil ? skinToUse! : view.skin.ScrollButton
        self.index = index
        super.init(view)
        
        name = "MMScrollButton"
        rect.width = skin.width
        rect.height = skin.height

        validStates = [.Checked]
        setItems(items)
    }
    
    func setItems(_ items: [String], fixedWidth: Float? = nil)
    {
        self.items = []
        contentWidth = 0
        maxItemWidth = 0
        
        for text in items {
            let item = MMScrollButtonItem(mmView, text: text, skin: skin)
            
            contentWidth += item.label!.rect.width
            maxItemWidth = max(maxItemWidth, item.label!.rect.width)

            self.items.append(item)
        }
        
        contentWidth += Float((items.count - 1 ) * 10) // Add margin
        rect.width = maxItemWidth + MMScrollButton.spacer
        if fixedWidth != nil {
            rect.width = fixedWidth!
            maxItemWidth = rect.width - MMScrollButton.spacer
        }
    }
    
    override func _clicked(_ event:MMMouseEvent)
    {
        addState( .Checked )
        if super.clicked != nil {
            super.clicked!(event)
        }
    }
    
    override func mouseLeave(_ event:MMMouseEvent)
    {
        hoverMode = .None
        update()
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        if isDisabled {
            return
        }
        mouseMoved(event)
        startScrolling()
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
        #if os(iOS) || os(watchOS) || os(tvOS)
        hoverMode = .None
        update()
        #endif
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
        if isDisabled {
            return
        }
        let oldHoverMode = hoverMode
        hoverMode = .None
        
        if items.count > 1 {
            if rect.contains(event.x, event.y) && event.x <= rect.x + 25 {
                hoverMode = .LeftArrow
            }
            if rect.contains(event.x, event.y) && event.x >= rect.x + rect.width - 25 {
                hoverMode = .RightArrow
            }
        }
        if oldHoverMode != hoverMode {
            update()
        }
    }
    
    override func mouseScrolled(_ event: MMMouseEvent)
    {
        if items.count > 1 {
            if animating == .No {
                if event.deltaX! > 4 {
                    hoverMode = .RightArrow
                    startScrolling()
                } else
                if event.deltaX! < -4 {
                    hoverMode = .LeftArrow
                    startScrolling()
                }
            }
            hoverMode = .None
        }
    }
    
    func startScrolling()
    {
        if hoverMode == .RightArrow {
            animatingTo = index == items.count - 1 ? 0 : index + 1
            animating = .Right
            animOffset = 0
            mmView.startAnimate( startValue: 0, endValue: maxItemWidth + 20 - (maxItemWidth - items[animatingTo].label!.rect.width) / 2, duration: 300, cb: { (value,finished) in
                if finished {
                    self.animating = .No
                    self.index = self.animatingTo
                    if self.changed != nil {
                        self.changed!(self.index)
                    }
                }
                self.animOffset = value
            } )
        } else
        if hoverMode == .LeftArrow {
            animatingTo = index == 0 ? items.count - 1 : index - 1
            animating = .Left
            animOffset = 0
            mmView.startAnimate( startValue: 0, endValue: maxItemWidth + 20 + (maxItemWidth - items[animatingTo].label!.rect.width) / 2, duration: 300, cb: { (value,finished) in
                if finished {
                    self.animating = .No
                    self.index = self.animatingTo
                    if self.changed != nil {
                        self.changed!(self.index)
                    }
                }
                self.animOffset = value
            } )
        }
    }
    
    override func draw(xOffset: Float = 0, yOffset: Float = 0)
    {
        mmView.drawBox.draw( x: rect.x, y: rect.y, width: rect.width + 2, height: rect.height, round: skin.round, borderSize: skin.borderSize, fillColor : skin.color, borderColor: skin.borderColor )
        
        // Left Arrow
        
        let middleY =  rect.y + rect.height / 2
        let oneThird = rect.height / 4
        let oneHalf = rect.height / 2
        
        var color = hoverMode == .LeftArrow ? skin.hoverColor : skin.activeColor

        mmView.drawLine.draw(sx: rect.x + 2 + skin.margin.left, sy: middleY - 1, ex: rect.x + 2 + oneHalf, ey: rect.y + oneThird - 1, radius: 1.5, fillColor: color)
        
        mmView.drawLine.draw(sx: rect.x + 2 + skin.margin.left, sy: middleY - 1, ex: rect.x + 2 + oneHalf, ey: rect.y + rect.height - oneThird - 1, radius: 1.5, fillColor: color)
        
        // Right Arrow
        
        let right = rect.x + rect.width
        color = hoverMode == .RightArrow ? skin.hoverColor : skin.activeColor

        mmView.drawLine.draw(sx: right - skin.margin.right - 2, sy: middleY - 1, ex: right - oneHalf - 2, ey: rect.y + oneThird - 1, radius: 1.5, fillColor: color)
       
        mmView.drawLine.draw(sx: right - skin.margin.right - 2, sy: middleY - 1, ex: right - oneHalf - 2, ey: rect.y + rect.height - oneThird - 1, radius: 1.5, fillColor: color)
        
        if items.count == 0 { return }
        
        let item = items[index]
        var label = item.label
        
        mmView.renderer.setClipRect(MMRect(rect.x + MMScrollButton.halfSpacer, rect.y, rect.width-MMScrollButton.halfSpacer*2, rect.height))

        label!.rect.x = rect.x + skin.margin.left + MMScrollButton.halfSpacer + (maxItemWidth - label!.rect.width) / 2
        label!.rect.y = rect.y + 9
        
        if animating == .Right {
            label!.rect.x -= animOffset
        } else
        if animating == .Left {
            label!.rect.x += animOffset
        }
        
        if label!.isDisabled != isDisabled {
            label!.isDisabled = isDisabled
        }
        label!.draw()
        
        if animating == .Right {
            let animTolabel = items[animatingTo].label
            
            animTolabel!.rect.x = rect.x + skin.margin.left + MMScrollButton.halfSpacer + maxItemWidth + 20 - animOffset
            animTolabel!.rect.y = label!.rect.y
            animTolabel!.draw()
        } else
        if animating == .Left {
            let animTolabel = items[animatingTo].label
            
            animTolabel!.rect.x = rect.x + skin.margin.left + MMScrollButton.halfSpacer - (maxItemWidth + 20) + animOffset
            animTolabel!.rect.y = label!.rect.y
            animTolabel!.draw()
        }
        
        mmView.renderer.setClipRect()
    }
}
