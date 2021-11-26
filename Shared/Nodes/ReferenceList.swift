//
//  ReferenceList.swift
//  Shape-Z
//
//  Created by Markus Moenig on 8/7/2562 BE.
//  Copyright © 2562 Markus Moenig. All rights reserved.
//

import MetalKit

class ReferenceItem {
    
    var uuid                : UUID!
    var classUUID           : UUID!

    var name                : MMTextLabel
    var category            : MMTextLabel
    
    var previewObject       : Object? = nil
    var previewScene        : Scene? = nil

    init(_ mmView: MMView)
    {
        name = MMTextLabel(mmView, font: mmView.openSans, text: "")
        category = MMTextLabel(mmView, font: mmView.openSans, text: "")
    }
}

class ReferenceList {
    
    enum Mode {
        case Variables, ObjectInstances, Scenes, SceneAreas, Animations, BehaviorTrees
    }
    
    var currentMode         : Mode = .Variables
    
    var nodeGraph           : NodeGraph!

    var rect                : MMRect = MMRect()
    var offsetY             : Float = 0
    var itemHeight          : Float = 58

    var refs                : [ReferenceItem] = []
    
    var dispatched          : Bool = false
    
    var selectedUUID        : UUID? = nil
    var selectedItem        : ReferenceItem? = nil

    var dragSource          : ReferenceListDrag? = nil
    var mouseIsDown         : Bool = false

    let color               : float4 = float4(0.243, 0.247, 0.251, 1.000)
    let selColor            : float4 = float4(0.388, 0.392, 0.396, 1.000)

    var isActive  : Bool = false {
        willSet(newValue) {
            if newValue == true {
                nodeGraph.setNavigationState(on: false)
            }
        }
    }
    
    init(_ nodeGraph: NodeGraph)
    {
        self.nodeGraph = nodeGraph
    }
    
    func createVariableList()
    {
        currentMode = .Variables
        refs = []
        var selfOffset : Int = 0
        for node in nodeGraph.nodes
        {
            if node.type == "Float Variable" || node.type == "Direction Variable" || node.type == "Float2 Variable" {
                let belongsToMaster = nodeGraph.currentMaster != nil ? nodeGraph.currentMaster!.subset!.contains(node.uuid) : false
                if node.properties["access"]! == 1 && !belongsToMaster {
                    continue
                }
                
                let item = ReferenceItem(nodeGraph.mmView)
                
                let name : String = node.name + " (" + node.type + ")"
                
                let master = nodeGraph.getMasterForNode(node)!
                var category : String = master.type + ": " + master.name
                if belongsToMaster {
                    category += " - Self"
                }
                
                item.name.setText( name, scale: 0.4)
                item.category.setText(category, scale: 0.3)
                item.uuid = node.uuid
                item.classUUID = master.uuid

                if belongsToMaster {
                    refs.insert(item, at: selfOffset)
                    selfOffset += 1
                } else {
                    refs.append(item)
                }
            }
        }
    }
    
    func createBehaviorTreesList()
    {
        currentMode = .BehaviorTrees
        refs = []
        var selfOffset : Int = 0
        for node in nodeGraph.nodes
        {
            if node.type == "Behavior Tree" {
                let belongsToMaster = nodeGraph.currentMaster != nil ? nodeGraph.currentMaster!.subset!.contains(node.uuid) : false
                //if node.properties["access"]! == 1 && !belongsToMaster {
                //    continue
                //}
                
                let item = ReferenceItem(nodeGraph.mmView)
                
                let name : String = node.name
                
                let master = nodeGraph.getMasterForNode(node)!
                var category : String = master.type + ": " + master.name
                if belongsToMaster {
                    category += " - Self"
                }
                
                item.name.setText( name, scale: 0.4)
                item.category.setText(category, scale: 0.3)
                item.uuid = node.uuid
                item.classUUID = master.uuid
                
                if belongsToMaster {
                    refs.insert(item, at: selfOffset)
                    selfOffset += 1
                } else {
                    refs.append(item)
                }
            }
        }
    }
    
    func createSceneList()
    {
        currentMode = .Scenes
        refs = []
        for node in nodeGraph.nodes
        {
            if node.type == "Scene" {
                let item = ReferenceItem(nodeGraph.mmView)
                
                let name : String = node.name + " (" + node.type + ")"
                
                let master = nodeGraph.getMasterForNode(node)!
                let category : String = master.type + ": " + master.name
                
                item.name.setText( name, scale: 0.4)
                item.category.setText(category, scale: 0.3)
                item.uuid = node.uuid
                item.classUUID = master.uuid
                
                item.previewScene = nodeGraph.getNodeForUUID(master.uuid) as? Scene
                
                refs.append(item)
            }
        }
    }
    
    func createSceneAreaList()
    {
        currentMode = .SceneAreas
        refs = []
        for node in nodeGraph.nodes
        {
            if node.type == "Scene Area" {
                let item = ReferenceItem(nodeGraph.mmView)
                
                let name : String = node.name + " (" + node.type + ")"
                
                let master = nodeGraph.getMasterForNode(node)!
                let category : String = master.type + ": " + master.name
                
                item.name.setText( name, scale: 0.4)
                item.category.setText(category, scale: 0.3)
                item.uuid = node.uuid
                item.classUUID = master.uuid
                
                refs.append(item)
            }
        }
    }
    
    func createInstanceList()
    {
        currentMode = .ObjectInstances
        refs = []
        var selfOffset : Int = 0
        for node in nodeGraph.nodes
        {
            if let scene = node as? Scene {

                for inst in scene.objectInstances {
                    let belongsToMaster = nodeGraph.currentMaster != nil ? nodeGraph.currentMaster!.subset!.contains(node.uuid) : false
                    let item = ReferenceItem(nodeGraph.mmView)
                    
                    var name : String = inst.name
                    let category : String = scene.name
                    
                    if belongsToMaster {
                        name += " - Self"
                    }
                    
                    item.name.setText( name, scale: 0.4)
                    item.category.setText(category, scale: 0.3)
                    item.uuid = inst.uuid
                    item.classUUID = scene.uuid
                    
                    item.previewObject = nodeGraph.getNodeForUUID(inst.objectUUID) as? Object
                    
                    if belongsToMaster {
                        refs.insert(item, at: selfOffset)
                        selfOffset += 1
                    } else {
                        refs.append(item)
                    }
                }
            }
        }
    }
    
    func createAnimationList()
    {
        currentMode = .Animations
        refs = []
        for node in nodeGraph.nodes
        {
            if let scene = node as? Scene {
                
                for inst in scene.objectInstances {
                    
                    if let object = nodeGraph.getNodeForUUID(inst.objectUUID) as? Object {
                        for seq in object.sequences {
                            let item = ReferenceItem(nodeGraph.mmView)
                        
                            let name : String = seq.name
                            let category : String = object.name
                        
                            item.name.setText( name, scale: 0.4)
                            item.category.setText(category, scale: 0.3)
                            item.uuid = seq.uuid
                            item.classUUID = inst.uuid
                        
                            refs.append(item)
                        }
                    }
                }
            }
        }
    }
    
    func draw()
    {
        let mmView = nodeGraph.mmView!
        
        // Round background
        var cb : Float = 2
        //mmView.drawBox.draw( x: rect.x + 2, y: rect.y, width: rect.width, height: rect.height, round: 0, borderSize: 0, fillColor: SIMD4<Float>(0.094, 0.098, 0.102, 1.000))
        
        mmView.drawBox.draw( x: rect.x + cb, y: rect.y + cb, width: rect.width - 2 * cb, height: rect.height - 2 * cb, round: 26, borderSize: 0, fillColor: SIMD4<Float>(0.094, 0.098, 0.102, 1.000))
        
        if offsetY < -(Float(refs.count) * itemHeight - rect.height) {
            offsetY = -(Float(refs.count) * itemHeight - rect.height)
        }
        
        if offsetY > 0 {
            offsetY = 0
        }
        
        var y : Float = rect.y + offsetY + 1
        
        let scrollRect = MMRect(rect)
        scrollRect.shrink(2,2)
        mmView.renderer.setClipRect(scrollRect)
        
        for item in refs {
         
            if y + itemHeight < scrollRect.y || y > scrollRect.bottom() {
                y += itemHeight
                continue
            }
            
            let isSelected = selectedUUID == item.uuid
            
            mmView.drawBox.draw(x: scrollRect.x, y: y, width: scrollRect.width, height: itemHeight - 1, round: 26, fillColor: isSelected ? selColor : color)
            
            let x : Float = item.previewScene == nil && item.previewObject == nil ? scrollRect.x + 10 : scrollRect.x + 70
            
            if item.previewObject != nil || item.previewScene != nil {
                mmView.drawBox.draw(x: scrollRect.x + 2, y: y + 2.5, width: itemHeight - 5, height: itemHeight - 5, round: 26, fillColor: float4(0,0,0,1))
                
                var previewTexture : MTLTexture? = nil
                let prevSize :Float = itemHeight - 5
                
                if let object = item.previewObject {
                    
                    if object.previewTexture == nil {
                        object.updatePreview(nodeGraph: nodeGraph)
                    } else
                        if object.instance != nil {
                            previewTexture = object.previewTexture
                    }
                } else
                if let scene = item.previewScene {
                    if scene.previewTexture == nil || Float(scene.previewTexture!.width) != nodeGraph.previewSize.x || Float(scene.previewTexture!.height) != nodeGraph.previewSize.y || scene.previewStatus == .NeedsUpdate {
                        scene.createIconPreview(nodeGraph: nodeGraph, size: nodeGraph.previewSize)
                    }
                    if scene.previewStatus == .Valid {
                        if let texture = scene.previewTexture {
                            previewTexture = texture
                        }
                    }
                }
                
                if let texture = previewTexture {
                    
                    let xFactor : Float = nodeGraph.previewSize.x / prevSize
                    let yFactor : Float = nodeGraph.previewSize.y / prevSize
                    let factor : Float = min(xFactor, yFactor)
                    
                    var topX : Float = scrollRect.x + 2
                    var topY : Float = y + 2
                    let scale : Float = 1
                    
                    topX += ((prevSize * factor) - (prevSize * xFactor)) / 2 * scale / factor / scale
                    topY += ((prevSize * factor) - (prevSize * yFactor)) / 2 * scale / factor / scale
                    
                    mmView.drawTexture.draw(texture, x: topX, y: topY, zoom: factor, round: 26 * scale * factor, roundingRect: float4(0,0,prevSize*factor,prevSize*factor))
                }
            }
            
            item.name.drawCenteredY(x: x, y: y + 5, width: scrollRect.width - 5, height: 30)
            item.category.drawCenteredY(x: x, y: y + 25, width: scrollRect.width - 5, height: 30)

            y += itemHeight
        }
            
        mmView.drawBox.draw( x: rect.x + cb, y: rect.y + cb, width: rect.width - 2 * cb, height: rect.height - 2 * cb, round: 26, borderSize: 2, fillColor: SIMD4<Float>(0,0,0,0), borderColor: SIMD4<Float>(0.094, 0.098, 0.102, 1.000))

        cb = -2
        mmView.drawBox.draw( x: rect.x + cb, y: rect.y + cb, width: rect.width - 2 * cb, height: rect.height - 2 * cb, round: 26, borderSize: 5, fillColor: SIMD4<Float>(0,0,0,0), borderColor: SIMD4<Float>(0.165, 0.169, 0.173, 1.000))
        
        mmView.renderer.setClipRect()
    }
    
    func mouseDown(_ event: MMMouseEvent)
    {
        let index : Float = (event.y - rect.y - offsetY) / itemHeight
        let intIndex = Int(index)
        
        if intIndex >= 0 && intIndex < refs.count {
            selectedUUID = refs[intIndex].uuid
            selectedItem = refs[intIndex]
        }
        
        mouseIsDown = true
    }
    
    func mouseUp(_ event: MMMouseEvent)
    {
        mouseIsDown = false
    }
    
    func mouseMoved(_ event: MMMouseEvent)
    {
        if mouseIsDown && dragSource == nil {
            dragSource = createDragSource(event.x - rect.x, event.y - rect.y)
            if dragSource != nil {
                dragSource?.sourceWidget = nodeGraph.app!.editorRegion!.widget
                nodeGraph.mmView.dragStarted(source: dragSource!)
            }
        }
    }
    
    func mouseScrolled(_ event: MMMouseEvent)
    {
        offsetY += event.deltaY! * 4
        
        if !dispatched {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.nodeGraph.mmView.unlockFramerate()
                self.dispatched = false
            }
            dispatched = true
        }
        
        if nodeGraph.mmView.maxFramerateLocks == 0 {
            nodeGraph.mmView.lockFramerate()
        }
    }
    
    func mouseEnter(_ event:MMMouseEvent)
    {
    }
    
    func mouseLeave(_ event:MMMouseEvent)
    {
    }
    
    func keyDown(_ event: MMKeyEvent)
    {
    }
    
    func keyUp(_ event: MMKeyEvent)
    {
    }
    
    /// Create a drag item
    func createDragSource(_ x: Float,_ y: Float) -> ReferenceListDrag?
    {
        if selectedItem == nil {
            return nil
        }
        
        let item = selectedItem!
        var node = nodeGraph.getNodeForUUID(selectedUUID!)
        var name : String = ""
        var type : String = ""
        
        if node != nil && (currentMode == .Variables || currentMode == .SceneAreas || currentMode == .Scenes || currentMode == .BehaviorTrees) {
            name = node!.name
            type = node!.type
        } else
        if currentMode == .ObjectInstances {
            node = nodeGraph.getNodeForUUID(item.classUUID)
            name = item.name.text
            type = "Object Instance"
        } else
        if currentMode == .Animations {
            node = nodeGraph.nodes[0]//nodeGraph.getNodeForUUID(item.classUUID)
            name = item.name.text
            type = "Animation"
        }
        
        if node != nil {
            
            var drag = ReferenceListDrag()
            
            drag.id = type
            drag.name = name
            drag.pWidgetOffset!.x = 0
            drag.pWidgetOffset!.y = 0
            
            drag.node = node
            drag.previewWidget = ReferenceThumb(nodeGraph.mmView, item: selectedItem!)
            
            drag.refItem = selectedItem!
            
            return drag
        }
        return nil
    }
    
    /// Update the current list (after undo / redo etc).
    func update() {
        if isActive == false {
            return
        }
        if currentMode == .Variables {
            createVariableList()
        }
        if currentMode == .ObjectInstances {
            createInstanceList()
        }
        if currentMode == .Scenes {
            createSceneList()
        }
        if currentMode == .SceneAreas {
            createSceneAreaList()
        }
        if currentMode == .Animations {
            createAnimationList()
        }
        if currentMode == .BehaviorTrees {
            createBehaviorTreesList()
        }
    }
    
    /// Activates and switches to the given type
    func switchTo(id: String, selected: UUID? = nil)
    {
        isActive = true
        if id == "Float Variable" || id == "Direction Variable" || id == "Float2 Variable" {
            createVariableList()
            nodeGraph.previewInfoMenu.setText("Variables")
        }
        if id == "Object Instance" {
            createInstanceList()
            nodeGraph.previewInfoMenu.setText("Object Instances")
        }
        if id == "Scene" {
            createSceneList()
            nodeGraph.previewInfoMenu.setText("Scenes")
        }
        if id == "Scene Area" {
            createSceneAreaList()
            nodeGraph.previewInfoMenu.setText("Scene Areas")
        }
        if id == "Animation" {
            createAnimationList()
            nodeGraph.previewInfoMenu.setText("Animations")
        }
        if id == "Behavior Tree" {
            createBehaviorTreesList()
            nodeGraph.previewInfoMenu.setText("Behavior Trees")
        }
        
        if selected != nil {
            setSelected(selected!)
        } else
        if selectedUUID != nil {
            setSelected(selectedUUID!)
        }
    }
    
    /// Sets (and makes visible) the currently selected item
    func setSelected(_ uuid: UUID)
    {
        selectedUUID = nil
        selectedItem = nil
        
        for item in refs {
            if item.uuid == uuid {
                selectedUUID = uuid
                selectedItem = item
                
                break
            }
        }
    }
}

class ReferenceThumb : MMWidget {

    var item            : ReferenceItem
    
    init(_ mmView: MMView, item: ReferenceItem) {
        self.item = item
        super.init(mmView)
        
        rect.width = item.name.rect.width + 20
        rect.height = 30
    }
    
    override func draw(xOffset: Float = 0, yOffset: Float = 0) {
        
        var color : float4 = float4(0.388, 0.392, 0.396, 1.000)
        color.w = 0.5

        mmView.drawBox.draw(x: rect.x, y: rect.y, width: rect.width, height: rect.height, round: 12, fillColor: color)
        item.name.drawCentered(x: rect.x, y: rect.y, width: rect.width - 5, height: 30)
    }
}

struct ReferenceListDrag : MMDragSource
{
    var id              : String = ""
    var sourceWidget    : MMWidget? = nil
    var previewWidget   : MMWidget? = nil
    var pWidgetOffset   : float2? = float2()
    var node            : Node? = nil
    var name            : String = ""
    
    var refItem         : ReferenceItem!
}
