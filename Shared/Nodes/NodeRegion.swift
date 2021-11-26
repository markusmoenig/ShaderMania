//
//  NodeRegion.swift
//  ShaderMania
//
//  Created by Markus Moenig on 26/11/21.
//

import Foundation

class EditorRegion: MMRegion
{
    var widget                  : EditorWidget!
    var core                    : Core
        
    init( _ view: MMView, core: Core)
    {
        self.core = core
        super.init(view, type: .Editor)
        
        widget = EditorWidget(view, editorRegion: self, core: core)
        registerWidgets( widgets: widget! )
    }
    
    override func build()
    {
        if core.nodeGraph.maximizedNode == nil {
            core.nodeGraph.drawRegion(self)
        } else {
            core.nodeGraph.maximizedNode?.maxDelegate?.drawRegion(self)
        }
        
        widget.rect.copy(rect)
    }
}

class EditorWidget      : MMWidget
{
    var region          : EditorRegion
    var core            : Core

    var scrolledMode    : Int? = nil
    
    var dispatched      : Bool = false
    
    var zoomBuffer      : Float = 0
    var scaleBuffer     : Float = 0

    init(_ view: MMView, editorRegion: EditorRegion, core: Core)
    {
        self.core = core
        region = editorRegion
        
        super.init(view)
        
        /*
        dropTargets.append( "ShapeSelectorItem" )
        dropTargets.append( "MaterialSelectorItem" )
        dropTargets.append( "NodeItem" )
        dropTargets.append( "AvailableObjectItem" )
        dropTargets.append( "AvailableLayerItem" )
        
        dropTargets.append( "Float Variable" )
        dropTargets.append( "Direction Variable" )
        dropTargets.append( "Float2 Variable" )
        dropTargets.append( "Object Instance" )
        dropTargets.append( "Scene Area" )
        dropTargets.append( "Scene" )
        dropTargets.append( "Animation" )
        dropTargets.append( "Behavior Tree" )
        */
    }

    override func keyDown(_ event: MMKeyEvent)
    {
        if core.nodeGraph.maximizedNode == nil {
            core.nodeGraph.keyDown(event)
        } else {
            core.nodeGraph.maximizedNode!.maxDelegate!.keyDown(event)
        }
    }
    
    override func keyUp(_ event: MMKeyEvent)
    {
        if core.nodeGraph.maximizedNode == nil {
            core.nodeGraph.keyUp(event)
        } else {
            core.nodeGraph.maximizedNode!.maxDelegate!.keyUp(event)
        }
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        scrolledMode = nil
        if core.nodeGraph.maximizedNode == nil {
            core.nodeGraph.mouseDown(event)
        } else {
            core.nodeGraph.maximizedNode!.maxDelegate!.mouseDown(event)
        }
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
        if core.nodeGraph.maximizedNode == nil {
            core.nodeGraph.mouseUp(event)
        } else {
            core.nodeGraph.maximizedNode!.maxDelegate!.mouseUp(event)
        }
    }
    
    override func pinchGesture(_ scale: Float,_ firstTouch: Bool)
    {
        if core.nodeGraph.maximizedNode == nil {
            if core.nodeGraph.hoverNode != nil && core.nodeGraph.nodeHoverMode == .Preview {
                
                var node = core.nodeGraph.hoverNode!
                if node === core.nodeGraph.currentRoot! {
                    node = core.nodeGraph.previewNode!
                }
                
                if firstTouch == true {
                    let realScale : Float = node.properties["prevScale"] != nil ? node.properties["prevScale"]! : 1
                    zoomBuffer = realScale
                }
                
                node.properties["prevScale"] = max(0.2, zoomBuffer * scale)
                node.updatePreview(nodeGraph: core.nodeGraph)
                mmView.update()
            } else
            if core.nodeGraph.nodeHoverMode == .None && core.nodeGraph.currentRoot != nil
            {
                if let camera = core.nodeGraph.currentRoot!.camera {
                    
                    if firstTouch == true {
                        zoomBuffer = camera.zoom
                        scaleBuffer = scale
                    }
                    camera.zoom = zoomBuffer * scale
                    camera.zoom = max(0.2, camera.zoom)
                    camera.zoom = min(1.5, camera.zoom)
                    
                    #if os(iOS)
                    
                    // Move nodes relative to the mouse position
                    if firstTouch == false && camera.zoom > 0.2 && camera.zoom < 1.5 {
                        let targetPoint = SIMD2<Float>( core.mmView.pinchCenter.x - core.editorRegion!.rect.x, core.mmView.pinchCenter.y - core.editorRegion!.rect.y)
                        
                        print("this", targetPoint)

                        if let currentRoot = core.nodeGraph.currentRoot {
                            let toMove = core.nodeGraph.getNodesOfMaster(for: currentRoot)
                            
                            let percent : Float = (scaleBuffer - scale)
                            scaleBuffer = scale
                            
                            for mNode in toMove {
                                mNode.xPos = mNode.xPos * (1.0 - percent) + targetPoint.x * percent
                                mNode.yPos = mNode.yPos * (1.0 - percent) + targetPoint.y * percent
                            }
                        }
                    }
                    
                    #endif
                    
                    mmView.update()
                }
            }
        } else {
            core.nodeGraph.maximizedNode!.maxDelegate!.pinchGesture(scale, firstTouch)
        }
    }
    
    override func mouseScrolled(_ event: MMMouseEvent)
    {
        if core.nodeGraph.maximizedNode == nil {
            if core.nodeGraph.hoverNode != nil && core.nodeGraph.nodeHoverMode == .Preview && core.nodeGraph.overviewIsOn == false {
                
                #if os(iOS)
                // Prevent scrolling over several areas
                if scrolledMode == nil {
                    scrolledMode = 0
                } else {
                    if scrolledMode != 0 {
                        return
                    }
                }
                #endif
                
                // Node preview translation
                var node = core.nodeGraph.hoverNode!
                if node === core.nodeGraph.currentRoot! {
                    node = core.nodeGraph.previewNode!
                }
                
                /*
                if core.nodeGraph.refList.isActive && core.nodeGraph.refList.rect.contains(event.x, event.y) {
                    core.nodeGraph.refList.mouseScrolled(event)
                    return
                }*/
                
                var prevOffX = node.properties["prevOffX"] != nil ? node.properties["prevOffX"]! : 0
                var prevOffY = node.properties["prevOffY"] != nil ? node.properties["prevOffY"]! : 0
                var prevScale = node.properties["prevScale"] != nil ? node.properties["prevScale"]! : 1
                
                #if os(OSX)
                if mmView.commandIsDown && event.deltaY! != 0 {
                    prevScale += event.deltaY! * 0.003
                    prevScale = max(0.1, prevScale)
                } else {
                    prevOffX += event.deltaX!
                    prevOffY += event.deltaY!
                }
                #else
                prevOffX -= event.deltaX!
                prevOffY -= event.deltaY!
                #endif
                
                node.properties["prevOffX"] = prevOffX
                node.properties["prevOffY"] = prevOffY
                node.properties["prevScale"] = prevScale
                node.updatePreview(nodeGraph: core.nodeGraph)
            } else
            if core.nodeGraph.nodeHoverMode == .None && core.nodeGraph.currentRoot != nil
            {
                // NodeGraph translation
                
                #if os(iOS)
                // Prevent scrolling over several areas
                if scrolledMode == nil {
                    scrolledMode = 1
                } else {
                    if scrolledMode != 1 {
                        return
                    }
                }
                #endif

                if let camera = core.nodeGraph.currentRoot!.camera {
                    #if os(OSX)
                    if mmView.commandIsDown && event.deltaY! != 0 {
                        camera.zoom += event.deltaY! * 0.003
                        camera.zoom = max(0.2, camera.zoom)
                        camera.zoom = min(1.5, camera.zoom)
                        
                        // Move nodes relative to the mouse position
                        
                        if camera.zoom > 0.2 && camera.zoom < 1.5 {
                            let targetPoint = SIMD2<Float>(event.x - core.nodeRegion!.rect.x, event.y - core.nodeRegion!.rect.y)

                            if let currentRoot = core.nodeGraph.currentRoot {
                                let toMove = core.nodeGraph.getNodesOfRoot(for: currentRoot)
                                
                                for mNode in toMove {
                                    
                                let percent : Float = event.deltaY! * 0.05
                                    mNode.xPos = mNode.xPos * (1.0 - percent) + targetPoint.x * percent
                                    mNode.yPos = mNode.yPos * (1.0 - percent) + targetPoint.y * percent
                                }
                            }
                        }
                    } else {
                        camera.xPos -= event.deltaX!
                        camera.yPos -= event.deltaY!
                    }
                    #else
                    camera.xPos += event.deltaX!
                    camera.yPos += event.deltaY!
                    #endif
                }
            }
            
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
        } else {
            core.nodeGraph.maximizedNode!.maxDelegate!.mouseScrolled(event)
        }
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
        if core.nodeGraph.maximizedNode == nil {
            core.nodeGraph.mouseMoved(event)
        } else {
            core.nodeGraph.maximizedNode!.maxDelegate!.mouseMoved(event)
        }
    }
    
    /*
    override func dragTerminated() {
        core.nodeGraph.refList.dragSource = nil
        mmView.unlockFramerate()
        core.nodeGraph.refList.mouseIsDown = false
    }*/
    
    /*
    /// Drag and Drop Target
    override func dragEnded(event:MMMouseEvent, dragSource:MMDragSource)
    {
        if dragSource.id == "ShapeSelectorItem" {
            // Object Editor, shape drag to editor
            let drag = dragSource as! ShapeSelectorDrag
        
            let currentObject = core.nodeGraph.maximizedNode as? Object
            let delegate = currentObject!.maxDelegate as! ObjectMaxDelegate
            let selObject = delegate.selObject!
            
            let addedShape = selObject.addShape(drag.shape!)
            selObject.selectedShapes = [addedShape.uuid]
            app.setChanged()
            
            func shapeStatusChanged(_ object: Object, _ shape: Shape)
            {
                mmView.undoManager!.registerUndo(withTarget: self) { target in
                    
                    let index = selObject.shapes.firstIndex(where: { $0.uuid == shape.uuid })
                    if index != nil {
                        object.shapes.remove(at: index!)
                        object.selectedShapes = []
                        self.app.updateObjectPreview(object)
                    } else {
                        object.addShape(shape)
                        object.selectedShapes = [shape.uuid]
                        self.app.updateObjectPreview(object)
                    }
                    shapeStatusChanged(object, shape)
                }
            }
            
            shapeStatusChanged(selObject, addedShape)
            
            if let shape = drag.shape {
                
                var xOff : Float = 0
                var yOff : Float = 0
                
                let deltaX = drag.pWidgetOffset!.x
                let deltaY = drag.pWidgetOffset!.y

                if shape.name == "Disk" {
                    xOff = shape.properties["radius"]! - deltaX + 2.5
                    yOff = shape.properties["radius"]! - deltaY + 2.5
                    
                    shape.properties["radius"] = shape.properties["radius"]!// * 700 / rect.width
                } else
                if shape.name == "Box" {
                    xOff = shape.properties["width"]! - deltaX + 2.5
                    yOff = shape.properties["height"]! - deltaY + 2.5
                    
                    shape.properties["width"] = shape.properties["width"]!// * 700 / rect.width
                    shape.properties["height"] = shape.properties["height"]!// * 700 / rect.width
                }
                
                let camera = currentObject!.maxDelegate!.getCamera()!
                
                // --- Transform coordinates
                xOff = (event.x - rect.x + xOff)
                yOff = (event.y - rect.y + yOff)
                
                // --- Center
                xOff -= rect.width / 2 - camera.xPos
                yOff += camera.yPos
                yOff -= rect.width / 2 * rect.height / rect.width
                
                shape.properties["posX"] = xOff / camera.zoom
                shape.properties["posY"] = -yOff / camera.zoom
                
                if shape.pointCount == 1 {
                    shape.properties["point_0_y"] = -shape.properties["point_0_y"]!
                } else
                if shape.pointCount == 2 {
                    shape.properties["point_0_y"] = -shape.properties["point_0_y"]!
                    shape.properties["point_1_y"] = -shape.properties["point_1_y"]!
                } else
                if shape.pointCount == 3 {
                    shape.properties["point_0_y"] = -shape.properties["point_0_y"]!
                    shape.properties["point_1_y"] = -shape.properties["point_1_y"]!
                    shape.properties["point_2_y"] = -shape.properties["point_2_y"]!
                }
            }
            currentObject!.maxDelegate?.update(true)
            // Update the Gizmo properly
            if let delegate = currentObject!.maxDelegate as? ObjectMaxDelegate {
                app.gizmo.setObject(delegate.selObject, rootObject: delegate.currentObject, context: delegate.gizmoContext, materialType: delegate.materialType)
            }
        } else
        if dragSource.id == "MaterialSelectorItem" {
            // Object Editor, shape drag to editor
            let drag = dragSource as! MaterialSelectorDrag
            
            let currentObject = app.nodeGraph.maximizedNode as? Object
            let delegate = currentObject!.maxDelegate as! ObjectMaxDelegate
            let selObject = delegate.selObject!
            
            if delegate.materialType == .Body {
                selObject.bodyMaterials.append(drag.material!)
                selObject.selectedBodyMaterials = [drag.material!.uuid]
            } else {
                selObject.borderMaterials.append(drag.material!)
                selObject.selectedBorderMaterials = [drag.material!.uuid]
            }
            
            func materialStatusChanged(_ object: Object, _ material: Material,_ materialType: Object.MaterialType)
            {
                mmView.undoManager!.registerUndo(withTarget: self) { target in
                    
                    if materialType == .Body {
                        let index = selObject.bodyMaterials.firstIndex(where: { $0.uuid == material.uuid })
                        if index != nil {
                            object.bodyMaterials.remove(at: index!)
                            object.selectedBodyMaterials = []
                            self.app.updateObjectPreview(object)
                        } else {
                            object.bodyMaterials.append(material)
                            object.selectedBodyMaterials = [material.uuid]
                            self.app.updateObjectPreview(object)
                        }
                    } else
                    if materialType == .Border {
                        let index = selObject.borderMaterials.firstIndex(where: { $0.uuid == material.uuid })
                        if index != nil {
                            object.borderMaterials.remove(at: index!)
                            object.selectedBorderMaterials = []
                            self.app.updateObjectPreview(object)
                        } else {
                            object.borderMaterials.append(material)
                            object.selectedBorderMaterials = [material.uuid]
                            self.app.updateObjectPreview(object)
                        }
                    }
                    materialStatusChanged(object, material, materialType)
                }
            }
            
            materialStatusChanged(selObject, drag.material!, delegate.materialType)
            app.setChanged()

            if let material = drag.material {
                
                var xOff : Float = 0
                var yOff : Float = 0
                
                //let deltaX = drag.pWidgetOffset!.x
                //let deltaY = drag.pWidgetOffset!.y
                
                let camera = currentObject!.maxDelegate!.getCamera()!
                
                // --- Transform coordinates
                xOff = (event.x - rect.x + xOff)
                yOff = (event.y - rect.y + yOff)
                
                // --- Center
                xOff -= rect.width / 2 - camera.xPos
                yOff += camera.yPos
                yOff -= rect.width / 2 * rect.height / rect.width
                
                material.properties["posX"] = xOff / camera.zoom
                material.properties["posY"] = -yOff / camera.zoom
            }
            currentObject!.maxDelegate?.update(true)
            // Update the Gizmo properly
            if let delegate = currentObject!.maxDelegate as? ObjectMaxDelegate {
                app.gizmo.setObject(delegate.selObject, rootObject: delegate.currentObject, context: delegate.gizmoContext, materialType: delegate.materialType)
            }
        } else

            
        if dragSource.id == "NodeItem"
        {
            // NodeGraph, node drag to editor

            let drag = dragSource as! NodeListDrag
            let node = drag.node!
                                    
            if app.nodeGraph.currentRoot != nil {
                if let camera = app.nodeGraph.currentRoot!.camera {

                    node.xPos = (event.x - rect.x) / camera.zoom - camera.xPos / camera.zoom - drag.pWidgetOffset!.x
                    node.yPos = (event.y - rect.y) / camera.zoom - camera.yPos / camera.zoom - drag.pWidgetOffset!.y

                    if node.type == "Object" {
                        let object = node as! Object
                        
                        node.name = "New " + node.type

                        object.sequences.append( MMTlSequence() )
                        object.currentSequence = object.sequences[0]
                    }
                    node.setupTerminals()

                    if app.nodeGraph.currentRoot != nil {
                        
                        let before = app.nodeGraph.encodeJSON()

                        app.nodeGraph.nodes.append(node)
                        app.nodeGraph.currentRoot?.subset!.append(node.uuid)
                        app.nodeGraph.setCurrentNode(node)
                        app.nodeGraph.updateMasterNodes(app.nodeGraph.currentRoot!)
                        app.nodeGraph.refList.update()
                        
                        let after = app.nodeGraph.encodeJSON()
                        app.nodeGraph.globalStateUndo(oldState: before, newState: after, text: "Insert Node")
                    }
                }
            }
        } else
        if dragSource.id == "AvailableObjectItem"
        {
            // Scene editor, available object drag to editor
            
            let drag = dragSource as! AvailableObjectListItemDrag
            let node = drag.node!
            
            if node.type == "Object" {
                if let currentScene = app.nodeGraph.maximizedNode as? Scene {
                    
                    var instanceName = node.name + " #"
                    var instanceCounter : Int = 1
                    // --- Compute the name of the instance by counting existing occurences
                    for n in app.nodeGraph.nodes {
                        if let scene = n as? Scene {
                            for inst in scene.objectInstances {
                                if inst.objectUUID == node.uuid {
                                    instanceCounter += 1
                                }
                            }
                        }
                    }
                    instanceName += String(instanceCounter)
                    // ---
                    let instance = ObjectInstance(name: instanceName, objectUUID: node.uuid, properties: [:])
                    currentScene.objectInstances.append(instance)
                    
                    if let camera = app.nodeGraph.maximizedNode!.maxDelegate!.getCamera() {
                        // --- Transform coordinates
                        var xOff : Float = (event.x - rect.x)
                        var yOff : Float = (event.y - rect.y)
                        
                        // --- Center
                        xOff -= rect.width / 2 - camera.xPos
                        yOff += camera.yPos
                        yOff -= rect.width / 2 * rect.height / rect.width
                        
                        instance.properties["posX"] = xOff / camera.zoom
                        instance.properties["posY"] = -yOff / camera.zoom
                        
                        instance.properties["scaleX"] = 1
                        instance.properties["scaleY"] = 1
                        instance.properties["rotate"] = 0
                    }
                    
                    let sceneDelegate = app.nodeGraph.maximizedNode!.maxDelegate as! SceneMaxDelegate
                    sceneDelegate.objectList!.rebuildList()
                    currentScene.selectedObjects = [instance.uuid]
                    currentScene.maxDelegate?.update(true, updateLists: true)
                    
                    func instanceStatusChanged(_ instance: ObjectInstance)
                    {
                        mmView.undoManager!.registerUndo(withTarget: self) { target in
                            
                            let index = currentScene.objectInstances.firstIndex(where: { $0.uuid == instance.uuid })
                            if index != nil {
                                currentScene.objectInstances.remove(at: index!)
                                currentScene.selectedObjects = []
                                
                                if let maximized = self.app.nodeGraph.maximizedNode {
                                    if let sceneDelegate = maximized.maxDelegate as? SceneMaxDelegate {
                                        sceneDelegate.objectList!.rebuildList()
                                    }
                                } else {
                                    currentScene.builderInstance = nil
                                    currentScene.updatePreview(nodeGraph: self.app.nodeGraph)
                                }
                                currentScene.maxDelegate?.update(true)
                            } else {
                                currentScene.objectInstances.append(instance)
                                currentScene.selectedObjects = [instance.uuid]
                                if let maximized = self.app.nodeGraph.maximizedNode {
                                    if let sceneDelegate = maximized.maxDelegate as? SceneMaxDelegate {                                    sceneDelegate.objectList!.rebuildList()
                                    }
                                } else {
                                    currentScene.builderInstance = nil
                                    currentScene.updatePreview(nodeGraph: self.app.nodeGraph)
                                }
                                currentScene.maxDelegate?.update(true)
                            }
                            instanceStatusChanged(instance)
                        }
                    }
                    instanceStatusChanged(instance)
                }
            }
        } else {
            // --- Drop Target ?
            if app.nodeGraph.validHoverTarget != nil {
                app.nodeGraph.acceptDragSource(dragSource)
            }
        }
    }*/
}
