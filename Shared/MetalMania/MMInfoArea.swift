//
//  MMInfoArea.swift
//  Shape-Z
//
//  Created by Markus Moenig on 27/7/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation

class MMInfoAreaItem {
    
    var mmView      : MMView
    var title       : String
    var variable    : String
    var value       : Float
    var rect        : MMRect
    var scale       : Float
    var range       : SIMD2<Float>
    var int         : Bool
    
    var titleLabel  : MMTextLabel
    var valueLabel  : MMTextLabel
    
    var cb          : ((Float, Float) -> ())?
    
    init(_ mmView: MMView,_ title: String,_ variable: String,_ value: Float, scale: Float = 0.3, int: Bool = false, range: SIMD2<Float> = SIMD2<Float>(-100000, 100000), cb: ((Float, Float) -> ())? = nil)
    {
        self.mmView = mmView
        self.title = title
        self.variable = variable
        self.value = value
        self.scale = scale
        self.cb = cb
        self.range = range
        self.int = int
        
        rect = MMRect()
        
        titleLabel = MMTextLabel(mmView, font: mmView.openSans, text: title, scale: scale )
        valueLabel = MMTextLabel(mmView, font: mmView.openSans, text: int ? String(Int(value)) : String(format: "%.02f", value), scale: scale )
    }
    
    func setValue(_ value: Float)
    {
        self.value = value
        if !int {
            valueLabel.setText(String(format: "%.02f", value))
        } else {
            valueLabel.setText(String(Int(value)))
        }
    }
}

class MMInfoArea : MMWidget {
    
    var items           : [MMInfoAreaItem] = []
    var hoverItem       : MMInfoAreaItem? = nil
    var closeItem       : MMInfoAreaItem? = nil
    var scale           : Float
    var closeable       : Bool
    
    var closeCB         : ((String, Float) -> ())?
    
    init(_ mmView: MMView, scale: Float = 0.3, closeable: Bool = false)
    {
        self.scale = scale
        self.closeable = closeable
        super.init(mmView)
    }
    
    func reset()
    {
        items = []
        hoverItem = nil
    }
    
    func sort()
    {
        items = items.sorted(by: { $0.variable.lowercased() < $1.variable.lowercased() })
    }
    
    func addItem(_ title: String,_ variable: String,_ value: Float, int: Bool = false, range: SIMD2<Float> = SIMD2<Float>(-100000, 100000), cb: ((Float, Float) -> ())? = nil) -> MMInfoAreaItem
    {
        let item = MMInfoAreaItem(mmView, title, variable, value, scale: scale, int: int, range: range, cb: cb)
        items.append(item)
        computeSize()
        return item
    }
    
    func updateItem(_ variable: String,_ value: Float)
    {
        for item in items {
            if item.variable == variable {
                item.setValue(value)
            }
        }
        computeSize()
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
        let oldHoverItem : MMInfoAreaItem? = hoverItem
        let oldCloseItem : MMInfoAreaItem? = closeItem
        hoverItem = nil
        closeItem = nil
        
        for item in items {
            if item.rect.contains(event.x, event.y) {
                hoverItem = item
                if closeable {
                    if event.x > item.rect.right() - 28 && event.x < item.rect.right() - 8 {
                        closeItem = item
                    }
                }
                break
            }
        }
        
        if oldHoverItem !== hoverItem || oldCloseItem !== closeItem {
            mmView.update()
        }
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        _ = mouseMoved(event)
        if let item = closeItem {
            if let cb = closeCB {
                cb(item.variable, item.value)
            }
        } else
        if let item = hoverItem {
            
            getNumberDialog(view: mmView, title: item.title, message: "Enter new value", defaultValue: item.value, cb: { (value) -> Void in
                if let cb = item.cb {
                    if value >= item.range.x && value <= item.range.y {
                        cb(item.value, value)
                        item.setValue(value)
                        self.computeSize()
                        self.mmView.update()
                    }
                }
            } )
        }
    }
    
    override func mouseLeave(_ event: MMMouseEvent) {
        hoverItem = nil
    }
    
    func computeSize()
    {
        var width   : Float = 0
        var height  : Float = 0
        
        for item in items {
            width += item.titleLabel.rect.width + 5
            width += item.valueLabel.rect.width + 20
            if closeable {
                width += 15
            }
            
            height = max(item.valueLabel.rect.height, height)
        }
        rect.width = width + 5
        rect.height = height + 5
    }
    
    func draw()
    {
        if items.isEmpty { return }
        
        var x : Float = rect.x + 5
        
        for item in items {
            
            let color : SIMD4<Float>
            if item === hoverItem {
                color = SIMD4<Float>(1,1,1,1)
            } else {
                color = SIMD4<Float>(0.761, 0.761, 0.761, 1.000)
            }
            
            item.titleLabel.rect.x = x
            item.titleLabel.rect.y = rect.y
            item.titleLabel.color = color
            item.titleLabel.draw()
            
            item.rect.x = x - 4
            item.rect.y = item.titleLabel.rect.y - 0.5
            item.rect.height = rect.height
            
            x += item.titleLabel.rect.width + 5
            
            item.valueLabel.rect.x = x
            item.valueLabel.rect.y = item.titleLabel.rect.y
            item.valueLabel.color = color
            item.valueLabel.draw()
            
            if closeable {
                let xStart = x + item.valueLabel.rect.width + 4
                let color = item === closeItem ? SIMD4<Float>(1,1,1,1) : SIMD4<Float>(0.4,0.4,0.4,1)
                
                mmView.drawSphere.draw(x: xStart - 2, y: rect.y - 1, radius: 8, borderSize: 1, fillColor: SIMD4<Float>(0.110, 0.110, 0.110, 1.000), borderColor: color)
                mmView.drawLine.draw(sx: xStart, sy: rect.y + 1, ex: xStart + 10, ey: rect.y + rect.height - 5, radius: 1, fillColor: color)
                mmView.drawLine.draw(sx: xStart, sy: rect.y + rect.height - 5, ex: xStart + 10, ey: rect.y + 1, radius: 1, fillColor: color)
                
                x += 15
            }
            
            x += item.valueLabel.rect.width + 20
            item.rect.width = x - item.rect.x - 6
        }
    }
}
