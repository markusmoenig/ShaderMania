//
//  MMListWidget.swift
//  Shape-Z
//
//  Created by Markus Moenig on 14/2/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

protocol MMTreeWidgetItem
{
    var name        : String {get set}
    var uuid        : UUID {get set}
    var color       : SIMD4<Float>?{get set}
    var children    : [MMTreeWidgetItem]?{get set}

    var folderOpen  : Bool{get set}
}

class MMTreeWidget : MMWidget
{
    enum HoverState {
        case None, HoverUp, HoverDown, Close
    }
    
    var hoverState      : HoverState = .None
    
    var fragment        : MMFragment?
    
    var width, height   : Float
    var spacing         : Float
    
    var unitSize        : Float
    var itemSize        : Float
    
    var hoverData       : [Float]
    var hoverBuffer     : MTLBuffer?
    var hoverIndex      : Int = -1
    
    var textureWidget   : MMTextureWidget
    var scrollArea      : MMScrollArea
    
    var selectedItems   : [UUID] = []
    var selectionChanged: ((_ item: [MMTreeWidgetItem])->())? = nil
    
    var skin            : MMSkinWidget
    
    var supportsUpDown  : Bool = false
    var supportsClose   : Bool = false
    
    var items           : [MMTreeWidgetItem] = []
    
    var selectionShade  : Float = 0.25
    
    var itemRound       : Float = 0
    
    override init(_ view: MMView)
    {
        scrollArea = MMScrollArea(view, orientation: .Vertical)
        skin = view.skin.Widget
        
        width = 0
        height = 0
        
        fragment = MMFragment(view)
        fragment!.allocateTexture(width: 10, height: 10)
        
        spacing = 0
        unitSize = 35
        itemSize = 35

        textureWidget = MMTextureWidget( view, texture: fragment!.texture )

        hoverData = [-1,0]
        hoverBuffer = fragment!.device.makeBuffer(bytes: hoverData, length: hoverData.count * MemoryLayout<Float>.stride, options: [])!
        
        super.init(view)
        zoom = 2
        textureWidget.zoom = zoom
    }
    
    /// Build the source
    func build(items: [MMTreeWidgetItem], fixedWidth: Float? = nil, supportsUpDown: Bool = false, supportsClose: Bool = false)
    {
        width = fixedWidth != nil ? fixedWidth! : rect.width
        height = 0
        if width == 0 {
            width = 1
        }
    
        // --- Calculate height
        func getChildHeight(_ item: MMTreeWidgetItem) {
            for item in item.children! {
                if item.folderOpen == false {
                    height += unitSize
                } else {
                    height += itemSize
                    getChildHeight(item)
                }
                height += spacing
            }
        }
        
        for item in items {
            if item.folderOpen == false {
                height += unitSize 
            } else {
                height += itemSize
                getChildHeight(item)
            }
            height += spacing
        }
        
        height *= zoom
        if height == 0 { height = 1 }
        
        // ---
        
        self.supportsUpDown = supportsUpDown
        self.supportsClose = supportsClose
        self.items = items
        
        if self.fragment!.width != self.width * zoom || self.fragment!.height != self.height {
            self.fragment!.allocateTexture(width: self.width * zoom, height: self.height)
        }
        self.textureWidget.setTexture(self.fragment!.texture)
        self.update()
    }
    
    override func update()
    {
        memcpy(hoverBuffer!.contents(), hoverData, hoverData.count * MemoryLayout<Float>.stride)

        if fragment!.encoderStart() {
                        
            let left        : Float = 6 * zoom
            var top         : Float = 0
            var indent      : Float = 0
            let indentSize  : Float = 10
            let fontScale   : Float = 0.22
            
            //var fontRect = MMRect()
            
            func drawItem(_ item: MMTreeWidgetItem) {
                
                if selectedItems.contains(item.uuid) {
                    mmView.drawBox.draw( x: 0, y: top, width: width, height: unitSize, round: 4, borderSize: 0, fillColor: shadeColor(item.color!, selectionShade), fragment: fragment!)
                } else {
                    mmView.drawBox.draw( x: 0, y: top, width: width, height: unitSize, round: 4, borderSize: 0, fillColor: item.color!, fragment: fragment!)
                }

                //fontRect = mmView.openSans.getTextRect(text: text, scale: fontScale, rectToUse: fontRect)
                
                
                if item.children != nil {
                    let text : String = item.folderOpen == false ? "+" : "-"
                    mmView.drawText.drawText(mmView.openSans, text: text, x: left, y: top + 4 * zoom, scale: fontScale * zoom, fragment: fragment)
                    mmView.drawText.drawText(mmView.openSans, text: item.name, x: left + indent + 15, y: top + 4 * zoom, scale: fontScale * zoom, fragment: fragment)
                } else {
                    mmView.drawText.drawText(mmView.openSans, text: item.name, x: left + indent, y: top + 4 * zoom, scale: fontScale * zoom, fragment: fragment)
                }
                
                top += (unitSize / 2) * zoom
            }
            
            func drawChildren(_ item: MMTreeWidgetItem) {
                indent += indentSize
                for item in item.children! {
                    drawItem(item)
                    if item.folderOpen == true {
                        drawChildren(item)
                    }
                    height += spacing
                }
                indent -= indentSize
            }
            
            for item in items {
                drawItem(item)
                if item.folderOpen == true {
                    drawChildren(item)
                }
            }
            
            fragment!.encodeEnd()
        }
    }
    
    override func draw(xOffset: Float = 0, yOffset: Float = 0)
    {
        scrollArea.rect.copy(rect)
        scrollArea.build(widget:textureWidget, area: rect, xOffset: xOffset)
    }
    
    // Draws a round border around the widget
    func drawRoundedBorder(backColor: SIMD4<Float>, borderColor: SIMD4<Float>)
    {
        let cb : Float = 2
        // Erase Edges
        mmView.drawBox.draw( x: rect.x - cb + 1, y: rect.y - cb, width: rect.width + 2*cb - 2, height: rect.height + 2*cb, round: 30, borderSize: 4, fillColor: float4(0,0,0,0), borderColor: backColor)
        
        mmView.drawBox.draw( x: rect.x - cb + 1, y: rect.y - cb, width: rect.width + 2*cb - 2, height: rect.height + 2*cb, round: 0, borderSize: 4, fillColor: float4(0,0,0,0), borderColor: backColor)
        
        // Box Border
        mmView.drawBox.draw( x: rect.x, y: rect.y - 1, width: rect.width, height: rect.height + 2, round: 30, borderSize: 1, fillColor: float4(0,0,0,0), borderColor: borderColor)
    }
    
    /// Select the item at the given relative mouse position
    @discardableResult func selectAt(_ x: Float,_ y: Float, items: [MMTreeWidgetItem], multiSelect: Bool = false) -> Bool
    {

        var changed : Bool = false
        
        if var item = itemAt(x, y, items: items) {
            
            //print( item.name )
            
            if !multiSelect {
                
                if item.children != nil {
                    item.folderOpen = !item.folderOpen
                    selectedItems = []
                } else {
                    selectedItems = [item.uuid]
                    
                    if selectionChanged != nil {
                        selectionChanged!( [item] )
                    }
                }
                
            } //else if !currentObject!.selectedShapes.contains( currentObject!.shapes[selectedIndex].uuid ) {
                //currentObject!.selectedShapes.append( currentObject!.shapes[selectedIndex].uuid )
            //}
            changed = true
        }
        
        return changed
    }
    
    /// Returns the item at the given location
    @discardableResult func itemAt(_ x: Float,_ y: Float, items: [MMTreeWidgetItem]) -> MMTreeWidgetItem?
    {
        let offset      : Float = y - scrollArea.offsetY
        var bottom      : Float = 0
        var selected    : MMTreeWidgetItem? = nil
        
        func getChildHeight(_ item: MMTreeWidgetItem) {
            for item in item.children! {
                if item.folderOpen == false {
                    bottom += unitSize
                } else {
                    bottom += itemSize
                    getChildHeight(item)
                }
                bottom += spacing
                if selected == nil && bottom > offset {
                    selected = item
                }
            }
        }
        
        for item in items {
            if item.folderOpen == false {
                bottom += unitSize
                if selected == nil && bottom > offset {
                    selected = item
                }
            } else {
                bottom += itemSize
                if selected == nil && bottom > offset {
                    selected = item
                }
                getChildHeight(item)
            }
            height += spacing
        }
        
        return selected != nil ? selected : nil
    }
    
    /// Sets the hover index for the given mouse position
    @discardableResult func hoverAt(_ x: Float,_ y: Float) -> Bool
    {
        let index : Float = y / (unitSize+spacing)
        hoverIndex = Int(index)
        let oldIndex = hoverData[0]
        hoverData[0] = -1
        hoverState = .None

        if hoverIndex >= 0 && hoverIndex < items.count {
            if supportsUpDown {
                if x >= 172 && x <= 201 {
                    hoverData[0] = Float(hoverIndex*3)
                    hoverState = .HoverUp
                } else
                if x >= 207 && x <= 235 {
                    hoverData[0] = Float(hoverIndex*3+1)
                    hoverState = .HoverDown
                }
            }
            if supportsClose {
                if x >= 262 && x <= 291 {
                    hoverData[0] = Float(hoverIndex*3+2)
                    hoverState = .Close
                }
            }
        }
        
        return hoverData[0] != oldIndex
    }
    
    override func mouseScrolled(_ event: MMMouseEvent)
    {
        scrollArea.mouseScrolled(event)
    }
    
    func removeFromSelection(_ uuid: UUID)
    {
        selectedItems.removeAll(where: { $0 == uuid })
    }
    
    /// Creates a thumbnail for the given item
    func createShapeThumbnail(item: MMTreeWidgetItem) -> MTLTexture?
    {
        let width : Float = 200 * zoom
        let height : Float = unitSize * zoom
        
        let texture = fragment!.allocateTexture(width: width, height: height, output: true)
                
        if fragment!.encoderStart(outTexture: texture) {
                        
            let left : Float = 6 * zoom
            let top : Float = 0
            let fontScale : Float = 0.22
            
            var fontRect = MMRect()
            
            mmView.drawBox.draw( x: 0, y: top, width: width, height: unitSize, round: 4, borderSize: 0, fillColor: shadeColor(item.color!, selectionShade), fragment: fragment!)
            
            fontRect = mmView.openSans.getTextRect(text: item.name, scale: fontScale, rectToUse: fontRect)
            mmView.drawText.drawText(mmView.openSans, text: item.name, x: left, y: top + 4 * zoom, scale: fontScale * zoom, fragment: fragment)
 
            fragment!.encodeEnd()
        }
        
        return texture
    }
    
    /// Returns the item of the given uuid
    func itemOfUUID(_ uuid: UUID) -> MMTreeWidgetItem?
    {
        for item in items {
            if item.uuid == uuid {
                return item
            }
        }
        return nil
    }
    
    /// Return the current item (index 0 in selected items)
    func getCurrentItem() -> MMTreeWidgetItem?
    {
        var selected    : MMTreeWidgetItem? = nil
        
        if selectedItems.count == 0 {
            return nil
        }
        
        let uuid = selectedItems[0]
        
        func parseChildren(_ item: MMTreeWidgetItem) {
            for item in item.children! {
                if selected == nil && item.uuid == uuid {
                    selected = item
                }
                if item.folderOpen == true {
                    parseChildren(item)
                }
            }
        }
        
        for item in items {
            if selected == nil && item.uuid == uuid {
                selected = item
            }
            if item.folderOpen == true {
                parseChildren(item)
            }
        }
        
        return selected
    }
}
