//
//  NodeList.swift
//  Shape-Z
//
//  Created by Markus Moenig on 16/2/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

class NodeListItem : MMTreeWidgetItem
{
    enum DisplayType : Int {
        case All, Object, Scene, Game, ObjectOverview, SceneOverview
    }
    
    var name         : String = ""
    var uuid         : UUID = UUID()
    var color        : float4? = nil
    var children     : [MMTreeWidgetItem]? = nil
    var displayType  : DisplayType = .All
    var folderOpen   : Bool = false
    
    var createNode   : (() -> Node)? = nil
    
    init(_ name: String)
    {
        self.name = name
    }
}

struct NodeListDrag : MMDragSource
{
    var id              : String = ""
    var sourceWidget    : MMWidget? = nil
    var previewWidget   : MMWidget? = nil
    var pWidgetOffset   : float2? = float2()
    var node            : Node? = nil
    var name            : String = ""
}

class NodeList : MMWidget
{
    var app                 : App
    
    var listWidget          : MMTreeWidget
    
    var items               : [NodeListItem] = []
    var filteredItems       : [NodeListItem] = []
    
    var mouseIsDown         : Bool = false
    var dragSource          : NodeListDrag?
    
    init(_ view: MMView, app: App)
    {
        self.app = app
        
        listWidget = MMTreeWidget(view)
        listWidget.skin.selectionColor = float4(0.5,0.5,0.5,1)
        listWidget.itemRound = 0
        
        super.init(view)

        var item : NodeListItem
        var parent : NodeListItem

        // --- Object
        item = NodeListItem("Object")
        item.createNode = {
            return Object()
        }
        addNodeItem(item, type: .Function, displayType: .ObjectOverview)
        
        // --- Scene
        item = NodeListItem("Scene")
        item.createNode = {
            return Scene()
        }
        addNodeItem(item, type: .Function, displayType: .SceneOverview)
        
        parent = addNodeItem(NodeListItem("Object Properties"), type: .Property, displayType: .Object)
        // -------------------------------
        /*
        // --- Object Profile
        item = NodeListItem("3D Profile")
        item.createNode = {
            return ObjectProfile()
        }
        addNodeItem(item, type: .Property, displayType: .Object)*/
        // --- Object Physics
        item = NodeListItem("Instance Props")
        item.createNode = {
            return ObjectInstanceProps()
        }
        addSubNodeItem(parent, item)
        // --- Object Physics
        item = NodeListItem("Physical Props")
        item.createNode = {
            return ObjectPhysics()
        }
        addSubNodeItem(parent, item)
        // --- Object Collisions
        item = NodeListItem("Collision Props")
        item.createNode = {
            return ObjectCollision()
        }
        addSubNodeItem(parent, item)
        // --- Object Render
        item = NodeListItem("Render Props")
        item.createNode = {
            return ObjectRender()
        }
        addSubNodeItem(parent, item)
        // --- Object Glow
        item = NodeListItem("Glow Effect")
        item.createNode = {
            return ObjectGlow()
        }
        addSubNodeItem(parent, item)

        parent = addNodeItem(NodeListItem("Scene Properties"), type: .Property, displayType: .Scene)

        // --- Scene Area
        item = NodeListItem("Area")
        item.createNode = {
            return SceneArea()
        }
        addSubNodeItem(parent, item)
        // --- Scene Device Orientation
        item = NodeListItem("Device Orientation")
        item.createNode = {
            return SceneDeviceOrientation()
        }
        addSubNodeItem(parent, item)
        // --- Scene Gravity
        item = NodeListItem("Gravity")
        item.createNode = {
            return SceneGravity()
        }
        addSubNodeItem(parent, item)
        // --- Scene Light
        item = NodeListItem("Light")
        item.createNode = {
            return SceneLight()
        }
        addSubNodeItem(parent, item)
        
        parent = addNodeItem(NodeListItem("Game Properties"), type: .Property, displayType: .Game)

        // --- Game Platform OSX
        item = NodeListItem("Platform: OSX")
        item.createNode = {
            return GamePlatformOSX()
        }
        addSubNodeItem(parent, item)

        // --- Game Platform IOS
        item = NodeListItem("Platform: iOS")
        item.createNode = {
            return GamePlatformIPAD()
        }
        addSubNodeItem(parent, item)
        // --- Game Platform TVOS
        item = NodeListItem("Platform: tvOS")
        item.createNode = {
            return GamePlatformTVOS()
        }
        addSubNodeItem(parent, item)

        // Variables
        parent = addNodeItem(NodeListItem("Variables"), type: .Property, displayType: .All)

        // --- Variable Value
        item = NodeListItem("Variable: Float")
        item.createNode = {
            return FloatVariable()
        }
        addSubNodeItem(parent, item)

        // --- Float2 Value
        item = NodeListItem("Variable: Float2")
        item.createNode = {
            return Float2Variable()
        }
        addSubNodeItem(parent, item)

        // --- Float3 Value
        item = NodeListItem("Variable: Float3")
        item.createNode = {
            return Float3Variable()
        }
        addSubNodeItem(parent, item)

        // --- Variable Value
        item = NodeListItem("Variable: Direction")
        item.createNode = {
            return DirectionVariable()
        }
        addSubNodeItem(parent, item)

        // Object Functions
        parent = addNodeItem(NodeListItem("Object Functions"), type: .Function, displayType: .Object)
        
        // --- Object Animation
        item = NodeListItem("Play Animation")
        item.createNode = {
            return ObjectAnimation()
        }
        addSubNodeItem(parent, item)
        // --- Object Animation
        item = NodeListItem("Get Animation State")
        item.createNode = {
            return ObjectAnimationState()
        }
        addSubNodeItem(parent, item)
        // --- Object Apply Force
        item = NodeListItem("Apply Force")
        item.createNode = {
            return ObjectApplyForce()
        }
        addSubNodeItem(parent, item)
        // --- Object Apply Directional Force
        item = NodeListItem("Apply Dir. Force")
        item.createNode = {
            return ObjectApplyDirectionalForce()
        }
        addSubNodeItem(parent, item)
        // --- Instance Collision Any
        item = NodeListItem("Collision (Any)")
        item.createNode = {
            return ObjectCollisionAny()
        }
        addSubNodeItem(parent, item)
        // --- Instance Collision With
        item = NodeListItem("Collision With")
        item.createNode = {
            return ObjectCollisionWith()
        }
        addSubNodeItem(parent, item)
        // --- Instance Distance To
        item = NodeListItem("Distance To")
        item.createNode = {
            return ObjectDistanceTo()
        }
        addSubNodeItem(parent, item)
        // --- Object Reset
        item = NodeListItem("Reset Instance")
        item.createNode = {
            return ResetObject()
        }
        addSubNodeItem(parent, item)
        // --- Object Touch Layer Area
        item = NodeListItem("Touches Area ?")
        item.createNode = {
            return ObjectTouchSceneArea()
        }
        addSubNodeItem(parent, item)

        // Scene Functions
        parent = addNodeItem(NodeListItem("Scene Functions"), type: .Function, displayType: .Scene)
        
        // --- Scene Finished
        item = NodeListItem("Finished")
        item.createNode = {
            return SceneFinished()
        }
        addSubNodeItem(parent, item)

        // Game Functions
        parent = addNodeItem(NodeListItem("Game Functions"), type: .Function, displayType: .Game)
        
        // --- Game Play Scene
        item = NodeListItem("Play Scene")
        item.createNode = {
            return GamePlayScene()
        }
        addSubNodeItem(parent, item)

        // Behavior Trees
        parent = addNodeItem(NodeListItem("Behavior Trees"), type: .Behavior, displayType: .All)
        
        // --- Behavior: Behavior Tree
        item = NodeListItem("Behavior Tree")
        item.createNode = {
            return BehaviorTree()
        }
        addSubNodeItem(parent, item)
        // --- Behavior: Execute Behavior Tree
        item = NodeListItem("Execute Tree")
        item.createNode = {
            return ExecuteBehaviorTree()
        }
        addSubNodeItem(parent, item)
        // --- Behavior: Inverter
        item = NodeListItem("Inverter")
        item.createNode = {
            return Inverter()
        }
        addSubNodeItem(parent, item)
        // --- Behavior: Sequence
        item = NodeListItem("Sequence")
        item.createNode = {
            return Sequence()
        }
        addSubNodeItem(parent, item)
        // --- Behavior: Selector
        item = NodeListItem("Selector")
        item.createNode = {
            return Selector()
        }
        addSubNodeItem(parent, item)
        // --- Behavior: Succeeder
        item = NodeListItem("Succeeder")
        item.createNode = {
            return Succeeder()
        }
        addSubNodeItem(parent, item)
        // --- Behavior: Repeater
        item = NodeListItem("Repeater")
        item.createNode = {
            return Repeater()
        }
        addSubNodeItem(parent, item)
        // --- Leaf: Click in Scene Area
        item = NodeListItem("Click in Area")
        item.createNode = {
            return ClickInSceneArea()
        }
        addSubNodeItem(parent, item)
        // --- Leaf: Key Down
        item = NodeListItem("OSX: Key Down")
        item.createNode = {
            return KeyDown()
        }
        addSubNodeItem(parent, item)
        // --- Leaf: Accelerometer
        item = NodeListItem("iOS: Accelerometer")
        item.createNode = {
            return Accelerometer()
        }
        addSubNodeItem(parent, item)

        // Arithmetic
        parent = addNodeItem(NodeListItem("Arithmetic"), type: .Arithmetic, displayType: .All)
        
        // --- Arithmetic
        item = NodeListItem("Add(Float2, Float2)")
        item.createNode = {
            return AddFloat2Variables()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Sub(Float2, Float2)")
        item.createNode = {
            return SubtractFloat2Variables()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Mult(Const, Float2)")
        item.createNode = {
            return MultiplyConstFloat2Variable()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Copy(Float2, Float2)")
        item.createNode = {
            return CopyFloat2Variables()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Reflect(Float2, Float2)")
        item.createNode = {
            return ReflectFloat2Variables()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Test(Float2)")
        item.createNode = {
            return TestFloat2Variable()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Limit(Float2)")
        item.createNode = {
            return LimitFloat2Range()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Animate(Float)")
        item.createNode = {
            return AnimateFloatVariable()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Add(Const, Float)")
        item.createNode = {
            return AddConstFloatVariable()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Sub(Const, Float)")
        item.createNode = {
            return SubtractConstFloatVariable()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Reset(Float)")
        item.createNode = {
            return ResetFloatVariable()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Copy(Const, Float)")
        item.createNode = {
            return SetFloatVariable()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Copy(Float, Float)")
        item.createNode = {
            return CopyFloatVariables()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Test(Float)")
        item.createNode = {
            return TestFloatVariable()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Random(Direction)")
        item.createNode = {
            return RandomDirection()
        }
        addSubNodeItem(parent, item)

        item = NodeListItem("Stop Variable Anims")
        item.createNode = {
            return StopVariableAnimations()
        }
        addSubNodeItem(parent, item)

        // ---
        switchTo(.Object)
    }
    
    /// Adds a given node list item and assigns the brand and display type of the node
    @discardableResult func addNodeItem(_ item: NodeListItem, type: Node.Brand, displayType: NodeListItem.DisplayType) -> NodeListItem
    {
        if type == .Behavior {
            item.color = mmView.skin.Node.behaviorColor
        } else
        if type == .Property {
            item.color = mmView.skin.Node.propertyColor
        } else
        if type == .Function {
            item.color = mmView.skin.Node.functionColor
        } else
        if type == .Arithmetic {
            item.color = mmView.skin.Node.arithmeticColor
        }
        item.displayType = displayType
        items.append(item)
        return item
    }
    
    func addSubNodeItem(_ item: NodeListItem,_ subItem: NodeListItem)
    {
        subItem.color = item.color
        if item.children == nil {
            item.children = []
        }
        item.children!.append(subItem)
    }
    
    /// Switches the type of the displayed node list items
    func switchTo(_ displayType: NodeListItem.DisplayType)
    {
        filteredItems = []
        for item in items {
            if (item.displayType == .All && displayType.rawValue < 4 ) || item.displayType == displayType {
                filteredItems.append(item)
            }
        }
        listWidget.build(items: filteredItems, fixedWidth: 200)
    }
    
    override func draw(xOffset: Float = 0, yOffset: Float = 0)
    {
        mmView.drawBox.draw( x: rect.x, y: rect.y, width: rect.width, height: rect.height, round: 0, borderSize: 1,  fillColor : float4( 0.145, 0.145, 0.145, 1), borderColor: float4( 0, 0, 0, 1 ) )

        listWidget.rect.x = rect.x
        listWidget.rect.y = rect.y
        listWidget.rect.width = rect.width
        listWidget.rect.height = rect.height
        
        listWidget.draw(xOffset: app.leftRegion!.rect.width - 200)
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        let changed = listWidget.selectAt(event.x - rect.x, (event.y - rect.y), items: filteredItems)
        if changed {
            listWidget.build(items: filteredItems, fixedWidth: 200)
        }
        mouseIsDown = true
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
        if mouseIsDown && dragSource == nil {
            dragSource = createDragSource(event.x - rect.x, event.y - rect.y)
            if dragSource != nil {
                dragSource?.sourceWidget = self
                mmView.dragStarted(source: dragSource!)
            }
        }
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
        mouseIsDown = false
    }
    
    override func dragTerminated() {
        dragSource = nil
        mmView.unlockFramerate()
        mouseIsDown = false
    }
    
    /// Create a drag item
    func createDragSource(_ x: Float,_ y: Float) -> NodeListDrag?
    {
        if let listItem = listWidget.getCurrentItem(), listItem.children == nil {
            if let item = listItem as? NodeListItem, item.createNode != nil {
                var drag = NodeListDrag()
                
                drag.id = "NodeItem"
                drag.name = item.name
                drag.pWidgetOffset!.x = x
                drag.pWidgetOffset!.y = y.truncatingRemainder(dividingBy: listWidget.unitSize)
                
                drag.node = item.createNode!()
                
                let texture = listWidget.createShapeThumbnail(item: listItem)
                drag.previewWidget = MMTextureWidget(mmView, texture: texture)
                drag.previewWidget!.zoom = 2
                
                return drag
            }
        }
        return nil
    }
    
    override func mouseScrolled(_ event: MMMouseEvent)
    {
        listWidget.mouseScrolled(event)
    }
}
