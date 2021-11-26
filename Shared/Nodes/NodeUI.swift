//
//  NodeUI.swift
//  Shape-Z
//
//  Created by Markus Moenig on 27.02.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation
import simd

class NodeUI
{
    enum Brand {
        case Separator, Selector, KeyDown, Number, Text, DropTarget
    }
    
    enum Role {
        case None, RootPicker, AnimationPicker, FloatVariablePicker, DirectionVariablePicker, LayerAreaPicker, FloatVariableTarget, DirectionVariableTarget, ObjectInstanceTarget, SceneAreaTarget, AnimationTarget, Float2VariableTarget, BehaviorTreeTarget, SceneTarget
    }
    
    var mmView      : MMView!
    
    var brand       : Brand
    var role        : Role = .None
    
    var node        : Node
    var variable    : String
    var title       : String
    
    var rect        : MMRect = MMRect()
    var titleLabel  : MMTextLabel? = nil
    
    var supportsTitleHover: Bool = false
    var titleHover  : Bool = false
    
    var isDisabled  : Bool = false
    
    var linkedTo    : NodeUI? = nil
    
    var dropTarget  : String? = nil
    
    // Start of the content area
    var contentY    : Float = 0

    // --- Statics
    
    static let fontName             : String = "Open Sans"
    static let titleFontScale       : Float = 0.34
    static let fontScale            : Float = 0.4
    static let titleMargin          : MMMargin = MMMargin(0, 5, 5, 5)
    static let titleSpacing         : Float = 5
    static let titleXOffset         : Float = 6
    static let itemSpacing          : Float = 6
    static let contentMargin        : Float = 8
    static let contentRound         : Float = 22

    static let titleTextColor       : SIMD4<Float> = SIMD4<Float>(0.6, 0.6, 0.6, 1.0)
    static let contentColor         : SIMD4<Float> = SIMD4<Float>(0.404, 0.408, 0.412, 1.000)
    static let contentColor2        : SIMD4<Float> = SIMD4<Float>(0.243, 0.247, 0.251, 1.000)
    static let contentTextColor     : SIMD4<Float> = SIMD4<Float>(0.749, 0.753, 0.757, 1.000)

    init(_ node : Node, brand: Brand, variable: String, title: String)
    {
        self.node = node
        self.brand = brand
        self.variable = variable
        self.title = title
    }
    
    func titleClicked()
    {
    }
    
    func internal_changed()
    {
    }
    
    func keyDown(_ event: MMKeyEvent)
    {
    }
    
    func keyUp(_ event: MMKeyEvent)
    {
    }
    
    func mouseDown(_ event: MMMouseEvent)
    {
    }
    
    func mouseUp(_ event: MMMouseEvent)
    {
    }
    
    func mouseMoved(_ event: MMMouseEvent)
    {
    }
    
    func mouseLeave()
    {
    }
    
    func calcSize(mmView: MMView)
    {
        self.mmView = mmView
        rect.width = 100
        rect.height = 20
    }
    
    // Update from properties
    func update()
    {
    }
    
    func draw(mmView: MMView, maxTitleSize: SIMD2<Float>, maxWidth: Float, scale: Float)
    {
        if titleLabel!.scale != NodeUI.titleFontScale * scale {
            titleLabel!.setText(title, scale: NodeUI.titleFontScale * scale)
        }
        
        titleLabel!.isDisabled = isDisabled
        titleLabel!.rect.x = rect.x + NodeUI.titleXOffset * scale
        titleLabel!.rect.y = rect.y
        titleLabel!.color = (titleHover && isDisabled == false) ? float4(1,1,1,1) : NodeUI.contentTextColor
        titleLabel!.draw()
        
        contentY = rect.y + titleLabel!.rect.height + NodeUI.titleSpacing * scale
    }
    
    /// Adjust color to disabled if necessary
    func adjustColor(_ color: float4) -> float4 {
        return isDisabled ? float4(color.x, color.y, color.z, mmView.skin.disabledAlpha) : color
    }
}

/// Separator Class
class NodeUISeparator : NodeUI
{
    var defaultValue: Float
    
    init(_ node: Node, variable: String, title: String, value: Float = 5)
    {
        self.defaultValue = value
        super.init(node, brand: .Separator, variable: variable, title: title)
    }
    
    override func calcSize(mmView: MMView) {
        self.mmView = mmView
        
        if titleLabel == nil {
            let scale : Float = node.nodeGraph != nil ? node.nodeGraph!.currentRoot!.camera!.zoom : 1
            titleLabel = MMTextLabel(mmView, font: mmView.openSans, text: "", scale: NodeUI.titleFontScale * scale, color: NodeUI.titleTextColor)
        }
        
        rect.width = 0
        rect.height = defaultValue
    }
}

class NodeUISelectorItem
{
    var label       : MMTextLabel?
    
    init( _ view: MMView, text: String)
    {
        label = MMTextLabel(view, font: view.openSans, text: text, scale: NodeUI.fontScale, color: NodeUI.contentTextColor )
    }
}

/// Drop down NodeUI class
class NodeUISelector : NodeUI
{
    enum HoverMode {
        case None, LeftArrow, RightArrow
    }
    
    enum Animating {
        case No, Left, Right
    }
    
    var items       : [String]
    var scrollItems : [NodeUISelectorItem]
    var index       : Float
    var defaultValue: Float
    
    let itemHeight  : Float = 26
    let spacer      : Float = 60
    
    var contentWidth: Float = 0
    var maxItemWidth: Float = 0
    
    var hoverMode   : HoverMode = .None
    var animating   : Animating = .No
    
    var animatingTo : Int = 0
    var animOffset  : Float = 0
    
    var scale       : Float = 0

    var contentLabel: MMTextLabel!
    
    init(_ node: Node, variable: String, title: String, items: [String], index: Float = 0)
    {
        self.items = items
        self.scrollItems = []
        self.index = index
        self.defaultValue = index
        
        if node.properties[variable] == nil {
            node.properties[variable] = index
        } else {
            self.index = node.properties[variable]!
        }
        
        super.init(node, brand: .Selector, variable: variable, title: title)
    }
    
    func setItems(_ items: [String], fixedWidth: Float? = nil)
    {
        contentWidth = 0
        maxItemWidth = 0
        
        self.scrollItems = []
        for text in items {
            let item = NodeUISelectorItem(mmView, text: text)
            
            contentWidth += item.label!.rect.width
            maxItemWidth = max(maxItemWidth, item.label!.rect.width)
            
            self.scrollItems.append(item)
        }
        
        contentWidth += Float((items.count - 1 ) * 10) // Add margin
    }
    
    override func calcSize(mmView: MMView) {
        self.mmView = mmView
        
        if titleLabel == nil {
            let scale : Float = node.nodeGraph != nil ? node.nodeGraph!.currentRoot!.camera!.zoom : 1
            titleLabel = MMTextLabel(mmView, font: mmView.openSans, text: title, scale: NodeUI.titleFontScale * scale, color: NodeUI.titleTextColor)
            contentLabel = MMTextLabel(mmView, font: mmView.openSans, text: "", scale: NodeUI.fontScale * scale, color: NodeUI.contentTextColor)
        }
        
        self.setItems(items)

        rect.width = maxItemWidth + spacer
        rect.height = titleLabel!.rect.height + NodeUI.titleSpacing + itemHeight + NodeUI.itemSpacing
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        if isDisabled {
            return
        }
        startScrolling()
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
        if isDisabled {
            return
        }
        let oldHoverMode = hoverMode
        hoverMode = .None
        
        if items.count > 1 {
            if rect.contains(event.x, event.y, scale) && event.x <= rect.x + 25 * scale && event.y > contentY {
                hoverMode = .LeftArrow
            }
            if rect.contains(event.x, event.y, scale) && event.x >= rect.x + (maxItemWidth + spacer - 19) * scale && event.y > contentY {
                hoverMode = .RightArrow
            }
        }
        if oldHoverMode != hoverMode {
            update()
        }
    }
    
    override func mouseLeave() {
        hoverMode = .None
        update()
    }
    
    override func update() {
        if let value = node.properties[variable] {
            index = value
        }
    }
    
    func getValue() -> Float
    {
        return node.properties[variable]!
    }
    
    func setValue(_ value: Float)
    {
        self.index = value
        node.properties[variable] = value
    }
    
    func startScrolling()
    {
        let index : Int = Int(self.index)
        if hoverMode == .RightArrow {
            animatingTo = index == items.count - 1 ? 0 : index + 1
            animating = .Right
            animOffset = 0
            
            let animTolabel = scrollItems[animatingTo].label!
            if  animTolabel.scale != NodeUI.fontScale * scale {
                animTolabel.setText(animTolabel.text, scale: NodeUI.fontScale * scale)
            }
            
            mmView.startAnimate( startValue: 0, endValue: maxItemWidth + spacer / 2 * scale - (maxItemWidth * scale - animTolabel.rect.width) / 2, duration: 300, cb: { (value,finished) in
                if finished {
                    self.animating = .No
                    #if os(iOS)
                    self.hoverMode = .None
                    #endif
                    self.index = Float(self.animatingTo)
                    self.internal_changed()

                    let oldValue = self.node.properties[self.variable]!
                    self.node.properties[self.variable] = self.index
                    self.node.variableChanged(variable: self.variable, oldValue: oldValue, newValue: self.index)
                }
                self.animOffset = value
                self.mmView.update()
            } )
        } else
        if hoverMode == .LeftArrow {
            animatingTo = index == 0 ? items.count - 1 : index - 1
            animating = .Left
            animOffset = 0
            
            let animTolabel = scrollItems[animatingTo].label!
            if  animTolabel.scale != NodeUI.fontScale * scale {
                animTolabel.setText(animTolabel.text, scale: NodeUI.fontScale * scale)
            }
            
            mmView.startAnimate( startValue: 0, endValue: maxItemWidth + spacer / 2 * scale + (maxItemWidth * scale - animTolabel.rect.width) / 2, duration: 300, cb: { (value,finished) in
                if finished {
                    self.animating = .No
                    #if os(iOS)
                    self.hoverMode = .None
                    #endif
                    self.index = Float(self.animatingTo)
                    self.internal_changed()

                    let oldValue = self.node.properties[self.variable]!
                    self.node.properties[self.variable] = self.index
                    self.node.variableChanged(variable: self.variable, oldValue: oldValue, newValue: self.index)
                }
                self.animOffset = value
                self.mmView.update()
            } )
        }
    }
    
    override func draw(mmView: MMView, maxTitleSize: SIMD2<Float>, maxWidth: Float, scale: Float)
    {
        super.draw(mmView: mmView, maxTitleSize: maxTitleSize, maxWidth: maxWidth, scale: scale)
        self.scale = scale
        
        mmView.drawBox.draw( x: rect.x, y: contentY, width: (maxItemWidth + spacer) * scale, height: itemHeight * scale, round: (NodeUI.contentRound + 4) * scale, borderSize: 1, fillColor : float4(0,0,0,0), borderColor: adjustColor(NodeUI.contentColor) )
        
        let middleY : Float = contentY + itemHeight / 2 * scale
        let arrowUp : Float = 7 * scale
        var left    : Float = rect.x + 10 * scale
        let oneScaled : Float = 1 * scale
        
        var color : float4 = hoverMode == .LeftArrow ? float4(1,1,1,1) : mmView.skin.ScrollButton.activeColor
        if isDisabled { color.w = 0.2 }
        mmView.drawLine.draw(sx: left, sy: middleY - oneScaled, ex: left + arrowUp, ey: middleY + arrowUp - oneScaled, radius: oneScaled, fillColor: color)
        mmView.drawLine.draw(sx: left, sy: middleY - oneScaled, ex: left + arrowUp, ey: middleY - arrowUp - oneScaled, radius: oneScaled, fillColor: color)

        left = rect.x + (maxItemWidth + spacer - 19) * scale
        color = hoverMode == .RightArrow ? float4(1,1,1,1) : mmView.skin.ScrollButton.activeColor
        if isDisabled { color.w = 0.2 }
        mmView.drawLine.draw(sx: left + arrowUp, sy: middleY - oneScaled, ex: left, ey: middleY + arrowUp - oneScaled, radius: oneScaled, fillColor: color)
        mmView.drawLine.draw(sx: left + arrowUp, sy: middleY - oneScaled, ex: left, ey: middleY - arrowUp - oneScaled, radius: oneScaled, fillColor: color)
        
        if items.count == 0 { return }
        
        let label = scrollItems[Int(index)].label!
        
        if  label.scale != NodeUI.fontScale * scale {
            label.setText(label.text, scale: NodeUI.fontScale * scale)
        }
        
        mmView.renderer.setClipRect(MMRect(rect.x + 20 * scale, rect.y, (maxItemWidth + 20) * scale, rect.height * scale))

        label.isDisabled = isDisabled
        label.rect.x = rect.x + spacer / 2 * scale + (maxItemWidth * scale - label.rect.width) / 2
        label.rect.y = contentY + 5 * scale

        if animating == .Right {
            label.rect.x -= animOffset
        } else
        if animating == .Left {
            label.rect.x += animOffset
        }
        label.draw()
        
        if animating == .Right {
            let animTolabel = scrollItems[animatingTo].label!
            animTolabel.rect.x = rect.x + spacer / 2 * scale + maxItemWidth + spacer / 2 * scale - animOffset
            animTolabel.rect.y = label.rect.y
            animTolabel.draw()
        } else
        if animating == .Left {
            let animTolabel = scrollItems[animatingTo].label!
            animTolabel.rect.x = rect.x + spacer / 2 * scale - (maxItemWidth + spacer / 2 * scale) + animOffset
            animTolabel.rect.y = label.rect.y
            animTolabel.draw()
        }
        mmView.renderer.setClipRect()
    }
}

/// Animation picker derived from NodeUISelector and with .AnimationPicker role
class NodeUIRootPicker : NodeUISelector
{
    var uiConnection        : UINodeConnection
    var uuids               : [UUID] = []
    
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        uiConnection = connection
        super.init(node, variable: variable, title: title, items: [])
        uiConnection.uiRootPicker = self
        role = .RootPicker
    }
    
    override func internal_changed()
    {
        uiConnection.connectedRoot = uuids[Int(index)]
        uiConnection.rootNode = uiConnection.nodeGraph?.getNodeForUUID(uiConnection.connectedRoot!)
        if let nodeGraph = uiConnection.nodeGraph {
            nodeGraph.updateNode(node)
        }
    }
}

/// Animation picker derived from NodeUISelector and with .AnimationPicker role
class NodeUIAnimationPicker : NodeUISelector
{
    var uiConnection        : UINodeConnection
    var uuids               : [UUID] = []
    
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        uiConnection = connection
        super.init(node, variable: variable, title: title, items: [])
        uiConnection.uiPicker = self
        role = .AnimationPicker
    }
    
    override func internal_changed()
    {
        uiConnection.connectedTo = uuids[Int(index)]
        uiConnection.target = nil
        /*
        if let object = uiConnection.masterNode as? Object {
            for seq in object.sequences {
                if seq.uuid == uiConnection.connectedTo {
                    uiConnection.target = seq
                    break;
                }
            }
        }*/
    }
}

/// Value Variable picker derived from NodeUISelector and with .ValueVariablePicker role
class NodeUIFloatVariablePicker : NodeUISelector
{
    var uiConnection        : UINodeConnection
    var uuids               : [UUID] = []
    
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        uiConnection = connection
        super.init(node, variable: variable, title: title, items: [])
        uiConnection.uiPicker = self
        role = .FloatVariablePicker
    }
    
    override func internal_changed()
    {
        uiConnection.connectedTo = uuids[Int(index)]
        uiConnection.target = uiConnection.nodeGraph?.getNodeForUUID(uiConnection.connectedTo!)
    }
}

/// Direction Variable picker derived from NodeUISelector and with .DirectionVariablePicker role
class NodeUIDirectionVariablePicker : NodeUISelector
{
    var uiConnection        : UINodeConnection
    var uuids               : [UUID] = []
    
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        uiConnection = connection
        super.init(node, variable: variable, title: title, items: [])
        uiConnection.uiPicker = self
        role = .DirectionVariablePicker
    }
    
    override func internal_changed()
    {
        uiConnection.connectedTo = uuids[Int(index)]
        uiConnection.target = uiConnection.nodeGraph?.getNodeForUUID(uiConnection.connectedTo!)
    }
}

/// Layer area picker derived from NodeUISelector and with .LayerAreaPicker role
class NodeUILayerAreaPicker : NodeUISelector
{
    var uiConnection        : UINodeConnection
    var uuids               : [UUID] = []
    
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        uiConnection = connection
        super.init(node, variable: variable, title: title, items: [])
        uiConnection.uiPicker = self
        role = .LayerAreaPicker
    }
    
    override func internal_changed()
    {
        uiConnection.connectedTo = uuids[Int(index)]
        uiConnection.target = uiConnection.nodeGraph?.getNodeForUUID(uiConnection.connectedTo!)
    }
}

/// NodeUI Drop Target
class NodeUIDropTarget : NodeUI
{
    enum HoverState {
        case None, Valid, Invalid
    }
    
    var hoverState  : HoverState = .None
    var uiConnection: UINodeConnection!

    var itemHeight  : Float = 26
    var minItemWidth: Float = 85

    var targetID    : String
    
    var contentLabel: MMTextLabel!
    
    var supportsAll : Bool = false
    
    init(_ node: Node, variable: String, title: String, targetID: String)
    {
        self.targetID = targetID
        super.init(node, brand: .DropTarget, variable: variable, title: title)
    }
    
    override func calcSize(mmView: MMView) {
        self.mmView = mmView
        
        if titleLabel == nil {
            let scale : Float = node.nodeGraph != nil ? node.nodeGraph!.currentRoot!.camera!.zoom : 1
            titleLabel = MMTextLabel(mmView, font: mmView.openSans, text: title, scale: NodeUI.titleFontScale * scale, color: NodeUI.titleTextColor)
        }
        
        var text = ""
        if let name = uiConnection.targetName {
            text = name
        }
        
        if role == .ObjectInstanceTarget && text.isEmpty && uiConnection.connectedTo == nil {
            text = "All"
        }
        
        contentLabel = MMTextLabel(mmView, font: mmView.openSans, text: text, scale: NodeUI.fontScale, color: NodeUI.contentTextColor)
        minItemWidth = max( contentLabel.rect.width + 30, 85 )
        
        rect.width = minItemWidth
        rect.height = titleLabel!.rect.height + NodeUI.titleSpacing + itemHeight + NodeUI.itemSpacing
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        //uiConnection.nodeGraph!.refList.switchTo(id: targetID, selected: uiConnection.connectedTo)
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
    }
    
    override func update() {
    }
    
    override func draw(mmView: MMView, maxTitleSize: SIMD2<Float>, maxWidth: Float, scale: Float)
    {
        super.draw(mmView: mmView, maxTitleSize: maxTitleSize, maxWidth: maxWidth, scale: scale)
        
        let x = rect.x
        let width = minItemWidth * scale
        
        if hoverState == .Valid && isDisabled == false {
            mmView.drawBox.draw( x: x, y: contentY, width: width, height: itemHeight * scale, round: (NodeUI.contentRound + 4) * scale, borderSize: 1, fillColor : float4(repeating: 0), borderColor: mmView.skin.Node.successColor)
        } else
        if (hoverState == .Invalid || contentLabel!.text == "") && isDisabled == false {
            mmView.drawBox.draw( x: x, y: contentY, width: width, height: itemHeight * scale, round: (NodeUI.contentRound + 4) * scale, borderSize: 1, fillColor : float4(repeating: 0), borderColor: mmView.skin.Node.failureColor)
        } else {
            mmView.drawBox.draw( x: x, y: contentY, width: width, height: itemHeight * scale, round: (NodeUI.contentRound + 4) * scale, borderSize: 1, fillColor : float4(repeating: 0), borderColor: float4(NodeUI.contentColor.x, NodeUI.contentColor.y, NodeUI.contentColor.z, mmView.skin.disabledAlpha))
        }
        
        if contentLabel.scale != NodeUI.fontScale * scale {
            contentLabel.setText(contentLabel.text, scale: NodeUI.fontScale * scale)
        }
        
        contentLabel.isDisabled = isDisabled
        contentLabel.drawCentered(x: x, y: contentY, width: width, height: itemHeight * scale)
    }
}

/// Float Variable Target derived from NodeUIDropTarget and with "Float Variable" drop ID
class NodeUIFloatVariableTarget : NodeUIDropTarget
{
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        super.init(node, variable: variable, title: title, targetID: "Float Variable")
        uiConnection = connection
        uiConnection.uiTarget = self
        role = .FloatVariableTarget
    }
}

/// Direction Variable Target derived from NodeUIDropTarget and with "Value Variable" drop ID
class NodeUIDirectionVariableTarget : NodeUIDropTarget
{
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        super.init(node, variable: variable, title: title, targetID: "Direction Variable")
        uiConnection = connection
        uiConnection.uiTarget = self
        role = .DirectionVariableTarget
    }
}

/// Float2 Variable Target derived from NodeUIDropTarget and with "Float2 Variable" drop ID
class NodeUIFloat2VariableTarget : NodeUIDropTarget
{
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        super.init(node, variable: variable, title: title, targetID: "Float2 Variable")
        uiConnection = connection
        uiConnection.uiTarget = self
        role = .Float2VariableTarget
    }
}

/// Object Instance Target derived from NodeUIDropTarget and with "Object Instance" drop ID
class NodeUIObjectInstanceTarget : NodeUIDropTarget
{
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        super.init(node, variable: variable, title: title, targetID: "Object Instance")
        uiConnection = connection
        uiConnection.uiTarget = self
        role = .ObjectInstanceTarget
        supportsAll = true
    }
}

/// Scene Target derived from NodeUIDropTarget and with "Scene" drop ID
class NodeUISceneTarget : NodeUIDropTarget
{
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        super.init(node, variable: variable, title: title, targetID: "Scene")
        uiConnection = connection
        uiConnection.uiTarget = self
        role = .SceneTarget
    }
}

/// Scene Area Target derived from NodeUIDropTarget and with "Scene Area" drop ID
class NodeUISceneAreaTarget : NodeUIDropTarget
{
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        super.init(node, variable: variable, title: title, targetID: "Scene Area")
        uiConnection = connection
        uiConnection.uiTarget = self
        role = .SceneAreaTarget
    }
}

/// Animation Target derived from NodeUIDropTarget and with "Animation" drop ID
class NodeUIAnimationTarget : NodeUIDropTarget
{
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        super.init(node, variable: variable, title: title, targetID: "Animation")
        uiConnection = connection
        uiConnection.uiTarget = self
        role = .AnimationTarget
    }
}

/// Behavior Tree Target derived from NodeUIDropTarget and with "Behavior Tree" drop ID
class NodeUIBehaviorTreeTarget : NodeUIDropTarget
{
    init(_ node: Node, variable: String, title: String, connection: UINodeConnection)
    {
        super.init(node, variable: variable, title: title, targetID: "Behavior Tree")
        uiConnection = connection
        uiConnection.uiTarget = self
        role = .BehaviorTreeTarget
    }
}

/// Key down NodeUI class
class NodeUIKeyDown : NodeUI
{
    var keyCode     : Float = -1
    var keyText     : String = ""
    var keyCodes    : [UInt16:String] = [
        53: "Escape",

        50: "Back Quote",
        18: "1",
        19: "2",
        20: "3",
        21: "4",
        23: "5",
        22: "6",
        26: "7",
        28: "8",
        25: "9",
        29: "0",
        27: "-",
        24: "=",
        51: "Delete",

        48: "Tab",
        12: "Q",
        13: "W",
        14: "E",
        15: "R",
        17: "T",
        16: "Y",
        32: "U",
        34: "I",
        31: "O",
        35: "P",
        33: "[",
        30: "]",
        42: "\\",
        
//        57: "Caps Lock",
        0: "A",
        1: "S",
        2: "D",
        3: "F",
        5: "G",
        4: "H",
        38: "J",
        40: "K",
        37: "L",
        41: ";",
        39: ",",
        36: "Return",
        
        57: "Shift",
        6: "Z",
        7: "X",
        8: "C",
        9: "V",
        11: "B",
        45: "N",
        46: "M",
        43: "Comma",
        47: "Period",
        44: "/",
        60: "Shift",
        
        63: "fn",
        59: "Control",
        58: "Option",
        55: "Command",
        49: "Space",
//        55: "R. Command",
        61: "R. Option",
        
        123: "Arrow Left",
        126: "Arrow Up",
        124: "Arrow Right",
        125: "Arrow Down",
    ]
    
    var contentLabel: MMTextLabel!

    init(_ node: Node, variable: String, title: String)
    {
        if node.properties[variable] == nil {
            node.properties[variable] = keyCode
        } else {
            keyCode = node.properties[variable]!
            let code = UInt16(exactly:keyCode)
            if code != nil {
                let desc = keyCodes[code!]
                if desc != nil {
                    keyText = desc!
                }
            }
        }
        
        super.init(node, brand: .KeyDown, variable: variable, title: title)
    }
    
    override func calcSize(mmView: MMView) {
        self.mmView = mmView
        
        if titleLabel == nil {
            let scale : Float = node.nodeGraph != nil ? node.nodeGraph!.currentRoot!.camera!.zoom : 1
            titleLabel = MMTextLabel(mmView, font: mmView.openSans, text: title, scale: NodeUI.titleFontScale * scale, color: NodeUI.titleTextColor)
            contentLabel = MMTextLabel(mmView, font: mmView.openSans, text: "", scale: NodeUI.fontScale * scale)
        }

        rect.width = 120
        rect.height = titleLabel!.rect.height + NodeUI.titleSpacing + 14 + NodeUI.contentMargin + NodeUI.itemSpacing
    }
    
    override func keyDown(_ event: MMKeyEvent)
    {
//        if event.characters != nil {
//            keyText = event.characters!.uppercased()
//        }
        keyCode = Float(event.keyCode)
        
        let desc = keyCodes[event.keyCode]
        if desc != nil {
            keyText = desc!
        }
        
        let oldValue = node.properties[variable]!
        node.properties[variable] = keyCode
        
        if oldValue != keyCode {
            node.variableChanged(variable: variable, oldValue: oldValue, newValue: keyCode)
            mmView.update()
        }
    }
    
    override func update() {
        keyCode = node.properties[variable]!
    }
    
    override func draw(mmView: MMView, maxTitleSize: SIMD2<Float>, maxWidth: Float, scale: Float)
    {
        super.draw(mmView: mmView, maxTitleSize: maxTitleSize, maxWidth: maxWidth, scale: scale)
        
        let x = rect.x
        let width = 120 * scale
        let itemHeight = (14 + NodeUI.contentMargin) * scale
        
        mmView.drawBox.draw( x: x, y: contentY, width: width, height: itemHeight, round: NodeUI.contentRound * scale, borderSize: 0, fillColor: adjustColor(NodeUI.contentColor) )
        
        // Draw Text
        if contentLabel.text != keyText || contentLabel.scale != NodeUI.fontScale * scale {
            contentLabel.setText(keyText, scale: NodeUI.fontScale * scale)
        }
        contentLabel.color = adjustColor(NodeUI.contentTextColor)
        contentLabel.drawCentered(x: x, y: contentY, width: width, height: itemHeight)
    }
}

/// Number class
class NodeUINumber : NodeUI
{
    var value       : Float
    var range       : SIMD2<Float>?
    var defaultValue: Float
    var mouseIsDown : Bool = false
    var x           : Float = 0
    var width       : Float = 0
    var int         : Bool = false
    var undoValue   : Float = 0
    
    var contentLabel: MMTextLabel!
    var contentText : String = ""
    var contentValue: Float? = nil
    
    init(_ node: Node, variable: String, title: String, range: SIMD2<Float>? = SIMD2<Float>(0,1), int: Bool = false, value: Float = 0)
    {
        self.value = value
        self.defaultValue = value
        self.range = range
        self.int = int

        if node.properties[variable] == nil {
            node.properties[variable] = value
        } else {
            self.value = node.properties[variable]!
        }
        
        super.init(node, brand: .Number, variable: variable, title: title)
        supportsTitleHover = true
    }
    
    override func calcSize(mmView: MMView) {
        self.mmView = mmView
        
        if titleLabel == nil {
            let scale : Float = node.nodeGraph != nil ? node.nodeGraph!.currentRoot!.camera!.zoom : 1
            titleLabel = MMTextLabel(mmView, font: mmView.openSans, text: title, scale: NodeUI.titleFontScale * scale, color: NodeUI.titleTextColor)
            contentLabel = MMTextLabel(mmView, font: mmView.openSans, text: "", scale: NodeUI.fontScale * scale, color: NodeUI.contentTextColor)
        }

        rect.width = 160
        rect.height = titleLabel!.rect.height + NodeUI.titleSpacing + 14 + NodeUI.contentMargin + NodeUI.itemSpacing
    }
    
    override func titleClicked()
    {
        if isDisabled {
            return
        }
        getNumberDialog(view: mmView, title: title, message: "Enter new value", defaultValue: value, cb: { (value) -> Void in
            if self.range != nil {
                let oldValue = self.value
                self.value = max( value, self.range!.x)
                self.value = min( self.value, self.range!.y)
                self.node.variableChanged(variable: self.variable, oldValue: oldValue, newValue: self.value, continuous: false)
            } else {
                self.node.variableChanged(variable: self.variable, oldValue: self.value, newValue: value, continuous: false)
                self.value = value
            }
            self.node.properties[self.variable] = self.value
            self.titleHover = false
            self.updateLinked()
            self.mmView.update()
        } )
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        if isDisabled {
            return
        }

        if mouseIsDown == false {
            undoValue = value
        }
        mouseIsDown = true

        if range != nil {
            let oldValue = value
            let perPixel = (range!.y - range!.x) / width

            value = range!.x + perPixel * (event.x - x)
            value = max( value, range!.x)
            value = min( value, range!.y)
            
            if int {
                value = floor(value)
            }
            
            if oldValue != value {
                node.variableChanged(variable: variable, oldValue: oldValue, newValue: value, continuous: true)
                updateLinked()
                mmView.update()
            }
        }
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
        if isDisabled {
            return
        }
        //let oldValue = node.properties[variable]!
        node.properties[variable] = value
        
        // Disabled the check to allow an continuous event to come through for undo / redo
        //if oldValue != value {
            node.variableChanged(variable: variable, oldValue: undoValue, newValue: value)
            updateLinked()
            mmView.update()
        //}
        mouseIsDown = false
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
        if mouseIsDown {
            mouseDown(event)
        }
    }
    
    override func mouseLeave() {
    }
    
    func updateLinked()
    {
        if let linked = linkedTo as? NodeUIAngle {
            linked.setValue(value)
        }
    }
    
    override func update() {
        value = node.properties[variable]!
    }
    
    func getValue() -> Float
    {
        return node.properties[variable]!
    }
    
    func setValue(_ value: Float)
    {
        self.value = value
        node.properties[variable] = value
        updateLinked()
    }
    
    override func draw(mmView: MMView, maxTitleSize: SIMD2<Float>, maxWidth: Float, scale: Float)
    {
        super.draw(mmView: mmView, maxTitleSize: maxTitleSize, maxWidth: maxWidth, scale: scale)
        
        x = rect.x
        width = 160 * scale
        let itemHeight = round((14 + NodeUI.contentMargin) * scale)
        
        mmView.drawBox.draw( x: x, y: contentY, width: width, height: itemHeight, round: NodeUI.contentRound * scale, borderSize: 0, fillColor : adjustColor(NodeUI.contentColor) )
        
        if range != nil {
            let offset = (width / (range!.y - range!.x)) * (value - range!.x)
            if offset > 0 {
                mmView.renderer.setClipRect(MMRect(x, contentY, offset, itemHeight))
                mmView.drawBox.draw( x: x, y: contentY, width: width, height: itemHeight, round: NodeUI.contentRound * scale, borderSize: 0, fillColor : adjustColor(NodeUI.contentColor2))
                mmView.renderer.setClipRect()
            }
        }
        
        // --- Draw Text
        if contentValue != value {
            contentText = int ? String(Int(value)) : String(format: "%.02f", value)
            contentValue = value
        }
        if contentLabel.text != contentText || contentLabel.scale != NodeUI.fontScale * scale {
            contentLabel.setText(contentText, scale: NodeUI.fontScale * scale)
        }

        contentLabel!.isDisabled = isDisabled
        contentLabel.color = NodeUI.contentTextColor
        contentLabel.drawCentered(x: x, y: contentY, width: width, height: itemHeight)
    }
}

/// Angle class
class NodeUIAngle : NodeUI
{
    var value       : Float
    var defaultValue: Float
    var mouseIsDown : Bool = false
    var x           : Float = 0
    var width       : Float = 0
    
    init(_ node: Node, variable: String, title: String, value: Float = 0)
    {
        self.value = value
        self.defaultValue = value
        
        if node.properties[variable] == nil {
            node.properties[variable] = value
        } else {
            self.value = node.properties[variable]!
        }
        
        super.init(node, brand: .Number, variable: variable, title: title)
    }
    
    override func calcSize(mmView: MMView) {
        self.mmView = mmView
        
        if titleLabel == nil {
            let scale : Float = node.nodeGraph != nil ? node.nodeGraph!.currentRoot!.camera!.zoom : 1
            titleLabel = MMTextLabel(mmView, font: mmView.openSans, text: title, scale: NodeUI.titleFontScale * scale, color: NodeUI.titleTextColor)
        }
        
        rect.width = 40
        rect.height = titleLabel!.rect.height + NodeUI.titleSpacing + 42 + NodeUI.itemSpacing
    }

    override func mouseDown(_ event: MMMouseEvent)
    {
        mouseIsDown = true
        
        /*
        if oldValue != value {
            node.variableChanged(variable: variable, oldValue: oldValue, newValue: value, continuous: true)
            mmView.update()*/
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
        /*
        let oldValue = node.properties[variable]!
        node.properties[variable] = value
        
        if oldValue != value {
            node.variableChanged(variable: variable, oldValue: oldValue, newValue: value)
            mmView.update()
        }
        */
        mouseIsDown = false
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
    }
    
    override func mouseLeave() {
    }
    
    override func update() {
        value = node.properties[variable]!
    }
    
    func getValue() -> Float
    {
        return node.properties[variable]!
    }
    
    func setValue(_ value: Float)
    {
        self.value = value
        node.properties[variable] = value
    }
    
    override func draw(mmView: MMView, maxTitleSize: SIMD2<Float>, maxWidth: Float, scale: Float)
    {
        super.draw(mmView: mmView, maxTitleSize: maxTitleSize, maxWidth: maxWidth, scale: scale)

        x = rect.x
        width = 40 * scale
        
        let itemHeight =  rect.height * scale
        
        let length : Float = 17
        
        let x0: Float = x + length * scale
        let y0: Float = rect.y + itemHeight / 2 + 2
        
        for i:Float in stride(from: 0, to: 360, by: 20) {
            
            let cosValue : Float = cos(i * Float.pi / 180)
            let sinValue : Float = sin(i * Float.pi / 180)
            
            let x1: Float = x0 + cosValue * (length-5) * scale
            let y1: Float = y0 + sinValue * (length-5) * scale
            let x2: Float = x0 + cosValue * length * scale
            let y2: Float = y0 + sinValue * length * scale
            
            mmView.drawLine.draw(sx: x1, sy: y1, ex: x2, ey: y2, radius: 1, fillColor: NodeUI.contentColor)
        }
        
        let x1: Float = x0 + cos(value * Float.pi / 180) * length * scale
        let y1: Float = y0 + sin(value * Float.pi / 180) * length * scale
        
        mmView.drawLine.draw(sx: x0, sy: y0, ex: x1, ey: y1, radius: 1, fillColor: float4(repeating: 1))
    }
}

/// Text class
class NodeUIText : NodeUI
{
    var value       : String
    var oldValue    : String
    var defaultValue: String
    var mouseIsDown : Bool = false
    var x           : Float = 0
    var width       : Float = 0
    
    init(_ node: Node, variable: String, title: String, value: String = "")
    {
        self.value = value
        self.defaultValue = value
        self.oldValue = value
        
        super.init(node, brand: .Text, variable: variable, title: title)
        supportsTitleHover = true
    }
    
    override func calcSize(mmView: MMView) {
        self.mmView = mmView
        
        if titleLabel == nil {
            let scale : Float = node.nodeGraph != nil ? node.nodeGraph!.currentRoot!.camera!.zoom : 1
            titleLabel = MMTextLabel(mmView, font: mmView.openSans, text: title, scale: NodeUI.titleFontScale * scale, color: NodeUI.titleTextColor)
        }
        
        rect.width = 160
        rect.height = titleLabel!.rect.height + NodeUI.titleSpacing + 14 + NodeUI.contentMargin + NodeUI.itemSpacing
    }
    
    override func titleClicked()
    {
        let old = value
        getStringDialog(view: mmView, title: title, message: "Enter new value", defaultValue: value, cb: { (value) -> Void in
            self.value = value
            self.oldValue = old
            self.titleHover = false
            self.updateLinked()
            self.mmView.update()
            self.node.variableChanged(variable: self.variable, oldValue: 0, newValue: 1, continuous: false)
        } )
        return
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        mouseIsDown = true
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
        mouseIsDown = false
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
    }
    
    override func mouseLeave() {
    }
    
    func updateLinked()
    {
    }
    
    override func update() {
        value = oldValue
    }
    
    override func draw(mmView: MMView, maxTitleSize: SIMD2<Float>, maxWidth: Float, scale: Float)
    {
        super.draw(mmView: mmView, maxTitleSize: maxTitleSize, maxWidth: maxWidth, scale: scale)
        
        x = rect.x
        width = 160 * scale
        
        let itemHeight = (14 + NodeUI.contentMargin) * scale

        mmView.drawBox.draw( x: x, y: contentY, width: width, height: itemHeight, round: NodeUI.contentRound * scale, borderSize: 0, fillColor : NodeUI.contentColor)
        
        mmView.drawText.drawTextCentered(mmView.openSans, text: value, x: x, y: contentY, width: width, height: itemHeight, scale: NodeUI.fontScale * scale, color: NodeUI.contentTextColor)
    }
}

/// Color class
class NodeUIColor : NodeUI
{
    var value       : SIMD3<Float>
    var defaultValue: SIMD3<Float>
    var mouseIsDown : Bool = false
    var x           : Float = 0
    var width       : Float = 0
    
    var prevSize    : SIMD2<Float> = SIMD2<Float>(80,80)
    
    var colorWidget : MMColorWidget? = nil
    
    init(_ node: Node, variable: String, title: String, value: SIMD3<Float> = SIMD3<Float>(0,0,0))
    {
        self.value = value
        self.defaultValue = value
    
        super.init(node, brand: .Number, variable: variable, title: title)

        if node.properties[variable + "_x"] == nil {
            setValue(value)
        } else {
            self.value = getValue()
        }
        supportsTitleHover = true
    }
    
    override func calcSize(mmView: MMView) {
        self.mmView = mmView
        
        if titleLabel == nil {
            let scale : Float = node.nodeGraph != nil ? node.nodeGraph!.currentRoot!.camera!.zoom : 1
            titleLabel = MMTextLabel(mmView, font: mmView.openSans, text: title, scale: NodeUI.titleFontScale * scale, color: NodeUI.titleTextColor)
        }
        
        rect.width = prevSize.x
        rect.height = prevSize.y + 15 + NodeUI.itemSpacing
        
        if colorWidget == nil {
            colorWidget = MMColorWidget(mmView, value: value)
            colorWidget?.changed = { (val, cont) in
                self.value = val

                if !cont {
                    let oldValue = self.getValue()
                    if oldValue != val {
                        self.setValue(val)

                        self.node.variableChanged(variable: self.variable, oldValue: oldValue, newValue: self.getValue())
                        mmView.update()
                    }
                }
            }
        }
    }
    
    override func titleClicked()
    {
        let old = value
        getStringDialog(view: mmView, title: title, message: "Enter new value", defaultValue: toHex(value), cb: { (string) -> Void in
            self.setValue(fromHex(hexString: string))
            self.titleHover = false
            self.mmView.update()
            self.node.variableChanged(variable: self.variable, oldValue: old, newValue: self.value, continuous: false)
        } )
        return
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        if isDisabled { return }
        mouseIsDown = true
        if let widget = colorWidget {
            widget.mouseDown(event)
        }
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
        if isDisabled { return }
        if let widget = colorWidget {
            widget.mouseUp(event)
        }
        mouseIsDown = false
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
        if isDisabled { return }
        if let widget = colorWidget {
            widget.mouseMoved(event)
        }
    }
    
    override func mouseLeave() {
    }
    
    override func update() {
        value = getValue()
    }
    
    func getValue() -> SIMD3<Float>
    {
        return SIMD3<Float>(node.properties[variable + "_x"]!, node.properties[variable + "_y"]!, node.properties[variable + "_z"]!)
    }
    
    func setValue(_ value: SIMD3<Float>)
    {
        self.value = value
        node.properties[variable + "_x"] = value.x
        node.properties[variable + "_y"] = value.y
        node.properties[variable + "_z"] = value.z
        if let widget = colorWidget {
            if widget.value != value {
                widget.setValue(color: value)
            }
        }
    }
    
    override func draw(mmView: MMView, maxTitleSize: SIMD2<Float>, maxWidth: Float, scale: Float)
    {
        super.draw(mmView: mmView, maxTitleSize: maxTitleSize, maxWidth: maxWidth, scale: scale)
        x = rect.x
        
        if let widget = colorWidget {
            widget.rect.x = x
            widget.rect.y = contentY
            widget.rect.width = prevSize.x * scale
            widget.rect.height = widget.rect.width
            widget.isDisabled = isDisabled
            
            widget.draw()
        }
    }
}
