//
//  Nodes.swift
//  Shape-Z
//
//  Created by Markus Moenig on 20.02.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation
import simd

class ObjectInstanceProps : Node
{
    override init()
    {
        super.init()
        name = "Instance Props"
        uiConnections.append(UINodeConnection(.ObjectInstance))
    }
    
    override func setup()
    {
        type = "Object Instance Props"
        brand = .Property
        
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/19791919/Instance+Properties"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "instance", title: "Instance", connection: uiConnections[0]),
            NodeUINumber(self, variable: "position", title: "X", range: nil, value: 0),
            NodeUINumber(self, variable: "y", title: "Y", range: nil, value: 0),
            NodeUINumber(self, variable: "scale", title: "Scale", range: SIMD2<Float>(0, 10), value: 1),
            NodeUINumber(self, variable: "rotate", title: "Rotation", range: SIMD2<Float>(0, 360), value: 0),
            NodeUINumber(self, variable: "opacity", title: "Opacity", range: SIMD2<Float>(0, 1), value: 1),
            NodeUINumber(self, variable: "z-index", title: "Z-Index", range: SIMD2<Float>(-5, 5), int: true, value: 0),
            NodeUISelector(self, variable: "active", title: "Active", items: ["No", "Yes"], index: 1),
        ]
        
        super.setupUI(mmView: mmView)
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "position", connector: .Right, brand: .Float2Variable, node: self),
            Terminal(name: "scale", connector: .Right, brand: .FloatVariable, node: self),
            Terminal(name: "rotate", connector: .Right, brand: .FloatVariable, node: self),
            Terminal(name: "opacity", connector: .Right, brand: .FloatVariable, node: self),
            Terminal(name: "z-index", connector: .Right, brand: .FloatVariable, node: self),
            Terminal(name: "active", connector: .Right, brand: .FloatVariable, node: self)
        ]
    }
    
    override func updateUIState(mmView: MMView)
    {
        uiItems[2].isDisabled = terminals[0].connections.count > 0
        
        super.updateUIState(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// A UI Variable changed
    override func variableChanged(variable: String, oldValue: Float, newValue: Float, continuous: Bool = false, noUndo: Bool = false)
    {
        if variable == "position" {
            let number = uiItems[1] as! NodeUINumber
            number.setValue(newValue)
            for target in uiConnections[0].targets {
                if let inst = target as? ObjectInstance {
                    inst.properties["posX"] = newValue
                    if let object = inst.instance {
                        object.properties["posX"] = newValue
                    }
                }
            }
        } else
        if variable == "y" {
            let number = uiItems[2] as! NodeUINumber
            number.setValue(newValue)
            for target in uiConnections[0].targets {
                if let inst = target as? ObjectInstance {
                    inst.properties["posY"] = newValue
                    if let object = inst.instance {
                        object.properties["posY"] = newValue
                    }
                }
            }
        }
        
        if variable == "scale" {
            let selector = uiItems[3] as! NodeUINumber
            selector.setValue(newValue)
            for target in uiConnections[0].targets {
                if let inst = target as? ObjectInstance {
                    inst.properties["scaleX"] = newValue
                    inst.properties["scaleY"] = newValue
                    if let object = inst.instance {
                        object.properties["scaleX"] = newValue
                        object.properties["scaleY"] = newValue
                    }
                }
            }
        }

        didConnectedFloatVariableChange(variable, "rotate", uiItem: uiItems[4], connection: uiConnections[0], newValue: newValue)
        didConnectedFloatVariableChange(variable, "opacity", uiItem: uiItems[5], connection: uiConnections[0], newValue: newValue)
        didConnectedFloatVariableChange(variable, "z-index", uiItem: uiItems[6], connection: uiConnections[0], newValue: newValue)
        
        if variable == "active" {
            let selector = uiItems[7] as! NodeUISelector
            selector.setValue(newValue)
            for target in uiConnections[0].targets {
                if let inst = target as? ObjectInstance {
                    inst.properties["active"] = newValue
                    if let object = inst.instance {
                        object.properties["active"] = newValue
                    }
                }
            }
        }
        
        // Update scene
        if let scene = uiConnections[0].masterNode as? Scene {
            scene.updateStatus = .NeedsUpdate
        }
        
        if noUndo == false {
            super.variableChanged(variable: variable, oldValue: oldValue, newValue: newValue, continuous: continuous)
        }
    }
    
    override func executeReadBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
        for target in uiConnections[0].targets {
            if let inst = target as? ObjectInstance {

                if terminal.name == "position" {
                    
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        setInternalPos(SIMD2<Float>(inst.properties["posX"]!, inst.properties["posY"]!))
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? Float2Variable {
                        if let object = inst.instance {
                            variable.setValue(SIMD2<Float>(object.properties["posX"]!, object.properties["posY"]!), adjustBinding: false)
                            setInternalPos(SIMD2<Float>(object.properties["posX"]!, object.properties["posY"]!))
                        } else {
                            variable.setValue(SIMD2<Float>(inst.properties["posX"]!, inst.properties["posY"]!), adjustBinding: false)
                            setInternalPos(SIMD2<Float>(inst.properties["posX"]!, inst.properties["posY"]!))
                        }
                    }
                } else
                if terminal.name == "scale" {
                    
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        setInternalScale(inst.properties["scaleX"]!)
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        if let object = inst.instance {
                            variable.setValue(object.properties["scaleX"]!, adjustBinding: false)
                            setInternalScale(object.properties["scaleX"]!)
                        } else {
                            variable.setValue(inst.properties["scaleX"]!, adjustBinding: false)
                            setInternalScale(inst.properties["scaleX"]!)
                        }
                    }
                } else
                if terminal.name == "rotate" {
                    
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        setInternalRotate(inst.properties["rotate"]!)
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        if let object = inst.instance {
                            variable.setValue(object.properties["rotate"]!, adjustBinding: false)
                            setInternalRotate(object.properties["rotate"]!)
                        } else {
                            variable.setValue(inst.properties["rotate"]!, adjustBinding: false)
                            setInternalRotate(inst.properties["rotate"]!)
                        }
                    }
                } else
                if terminal.name == "opacity" {
                    
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        setInternalOpacity(inst.properties["opacity"]!)
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        if let object = inst.instance {
                            variable.setValue(object.properties["opacity"]!, adjustBinding: false)
                            setInternalOpacity(object.properties["opacity"]!)
                        } else {
                            variable.setValue(inst.properties["opacity"]!, adjustBinding: false)
                            setInternalOpacity(inst.properties["opacity"]!)
                        }
                    }
                } else
                if terminal.name == "z-index" {
                    
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        setInternalZIndex(inst.properties["z-index"]!)
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        if let object = inst.instance {
                            variable.setValue(object.properties["z-index"]!, adjustBinding: false)
                            setInternalZIndex(object.properties["z-index"]!)
                        } else {
                            variable.setValue(inst.properties["z-index"]!, adjustBinding: false)
                            setInternalZIndex(inst.properties["z-index"]!)
                        }
                    }
                } else
                if terminal.name == "active" {
                    
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        setInternalActive(inst.properties["active"]!)
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        if let object = inst.instance {
                            variable.setValue(object.properties["active"]!, adjustBinding: false)
                            setInternalActive(object.properties["active"]!)
                        } else {
                            variable.setValue(inst.properties["active"]!, adjustBinding: false)
                            setInternalActive(inst.properties["active"]!)
                        }
                    }
                }
            }
        }
    }
    
    override func executeWriteBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
        for target in uiConnections[0].targets {
            if let inst = target as? ObjectInstance {
                if terminal.name == "position" {
                    if let variable = terminal.connections[0].toTerminal!.node as? Float2Variable {
                        let value = variable.getValue()

                        setInternalPos(value)
                        if let object = inst.instance {
                            object.properties["posX"] = value.x
                            object.properties["posY"] = value.y
                        }
                        if nodeGraph.playNode == nil {
                            inst.properties["posX"] = value.x
                            inst.properties["posY"] = value.y
                        }
                    }
                } else
                if terminal.name == "scale" {
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        let value = variable.getValue()
                        
                        setInternalScale(value)
                        if let object = inst.instance {
                            object.properties["scaleX"] = value
                            object.properties["scaleY"] = value
                        }
                        if nodeGraph.playNode == nil {
                            inst.properties["scaleX"] = value
                            inst.properties["scaleY"] = value
                        }
                    }
                }
                if terminal.name == "rotate" {
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        let value = variable.getValue()
                        
                        setInternalRotate(value)
                        if let object = inst.instance {
                            object.properties["rotate"] = value
                        }
                        if nodeGraph.playNode == nil {
                            inst.properties["rotate"] = value
                        }
                    }
                } else
                if terminal.name == "opacity" {
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        let value = variable.getValue()
                        
                        setInternalOpacity(value)
                        if let object = inst.instance {
                            object.properties["opacity"] = value
                        }
                        if nodeGraph.playNode == nil {
                            inst.properties["opacity"] = value
                        }
                    }
                } else
                if terminal.name == "z-index" {
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        let value = variable.getValue()
                        
                        setInternalZIndex(value)
                        if let object = inst.instance {
                            object.properties["z-index"] = value
                        }
                        if nodeGraph.playNode == nil {
                            inst.properties["z-index"] = value
                        }
                    }
                } else
                if terminal.name == "active" {
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        let value = variable.getValue()
                        
                        setInternalActive(value)
                        if let object = inst.instance {
                            object.properties["active"] = value
                        }
                        if nodeGraph.playNode == nil {
                            inst.properties["active"] = value
                        }
                    }
                }
            }
        }
        
        // Update scene
        if let scene = uiConnections[0].masterNode as? Scene {
            scene.updateStatus = .NeedsUpdate
        }
    }
    
    // Adjusts the internal position
    func setInternalPos(_ pos: SIMD2<Float>)
    {
        if let item = uiItems[1] as? NodeUINumber {
            item.value = pos.x
        }
        if let item = uiItems[2] as? NodeUINumber {
            item.value = pos.y
        }
    }
    
    // Adjusts the internal scale
    func setInternalScale(_ value: Float)
    {
        if let item = uiItems[3] as? NodeUINumber {
            item.value = value
        }
    }
    
    // Adjusts the internal rotation
    func setInternalRotate(_ value: Float)
    {
        if let item = uiItems[4] as? NodeUINumber {
            item.value = value
        }
    }
    
    // Adjusts the internal opacity
    func setInternalOpacity(_ opacity: Float)
    {
        if let item = uiItems[5] as? NodeUINumber {
            item.value = opacity
        }
    }
    
    // Adjusts the internal z-index
    func setInternalZIndex(_ zIndex: Float)
    {
        if let item = uiItems[6] as? NodeUINumber {
            item.value = zIndex
        }
    }
    
    // Adjusts the internal z-index
    func setInternalActive(_ active: Float)
    {
        if let item = uiItems[7] as? NodeUISelector {
            item.index = active
        }
    }
    
    /// Execute  properties
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) ->    Result
    {
        /*
        if let object = root.objectRoot {
            let value = properties["physicsMode"]!
            object.properties["physicsMode"] = value
            
            return .Success
        }
        */
        return .Success
    }
}

class ObjectPhysics : Node
{
    override init()
    {
        super.init()
        name = "Physical Props"
    }
    
    override func setup()
    {
        type = "Object Physics"
        brand = .Property
        
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/9109521/Physical+Properties"
        uiConnections.append(UINodeConnection(.ObjectInstance))
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "instance", title: "Instance", connection: uiConnections[0]),
            NodeUISelector(self, variable: "physicsMode", title: "Mode", items: ["Off", "Static", "Dynamic"], index: 1),
            NodeUINumber(self, variable: "physicsMass", title: "Mass", range: SIMD2<Float>(0, 100), value: 1),
            NodeUINumber(self, variable: "physicsRestitution", title: "Restitution", range: SIMD2<Float>(0, 5), value: 0.2),
            NodeUINumber(self, variable: "physicsFriction", title: "Friction", range: SIMD2<Float>(0, 1), value: 0.3),
            NodeUISelector(self, variable: "physicsSupportsRotation", title: "Rotation", items: ["No", "Yes"], index: 1),
            NodeUISelector(self, variable: "physicsCollisions", title: "Collisions", items: ["Natural", "Reflect", "Custom"], index: 0)
        ]
        
        super.setupUI(mmView: mmView)
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "physicsMass", connector: .Right, brand: .FloatVariable, node: self),
            Terminal(name: "physicsRestitution", connector: .Right, brand: .FloatVariable, node: self),
            Terminal(name: "physicsFriction", connector: .Right, brand: .FloatVariable, node: self)
        ]
    }
    
    override func updateUIState(mmView: MMView)
    {
        let mode = properties["physicsMode"]!
        let collisions = properties["physicsCollisions"]!
    
        uiItems[2].isDisabled = mode == 0 || mode == 1
        uiItems[3].isDisabled = mode == 0 /*|| mode == 1*/ || collisions == 1
        uiItems[4].isDisabled = mode == 0 || collisions == 1
        uiItems[5].isDisabled = mode == 0 || mode == 1 || collisions == 1
        uiItems[6].isDisabled = mode == 0 || mode == 1
        
        super.updateUIState(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //        test = try container.decode(Float.self, forKey: .test)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// A UI Variable changed
    override func variableChanged(variable: String, oldValue: Float, newValue: Float, continuous: Bool = false, noUndo: Bool = false)
    {
        didConnectedFloatVariableChange(variable, "physicsMass", uiItem: uiItems[2], connection: uiConnections[0], newValue: newValue)
        didConnectedFloatVariableChange(variable, "physicsRestitution", uiItem: uiItems[3], connection: uiConnections[0], newValue: newValue)
        didConnectedFloatVariableChange(variable, "physicsFriction", uiItem: uiItems[4], connection: uiConnections[0], newValue: newValue)
        
        if noUndo == false {
            super.variableChanged(variable: variable, oldValue: oldValue, newValue: newValue, continuous: continuous)
        }
    }
    
    override func executeReadBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
        for target in uiConnections[0].targets {
            if let inst = target as? ObjectInstance {
                
                if terminal.name == "physicsMass" {
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        if inst.properties["physicsMass"] == nil { inst.properties["physicsMass"] = 1 }
                        setInternalPhysicsMass(inst.properties["physicsMass"]!)
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        if let object = inst.instance {
                            variable.setValue(object.properties["physicsMass"]!, adjustBinding: false)
                            setInternalPhysicsMass(object.properties["physicsMass"]!)
                        } else {
                            variable.setValue(inst.properties["physicsMass"]!, adjustBinding: false)
                            setInternalPhysicsMass(inst.properties["physicsMass"]!)
                        }
                    }
                } else
                if terminal.name == "physicsRestitution" {
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        if inst.properties["physicsRestitution"] == nil { inst.properties["physicsRestitution"] = 0.2 }
                        setInternalPhysicsRestitution(inst.properties["physicsRestitution"]!)
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        if let object = inst.instance {
                            variable.setValue(object.properties["physicsRestitution"]!, adjustBinding: false)
                            setInternalPhysicsRestitution(object.properties["physicsRestitution"]!)
                        } else {
                            variable.setValue(inst.properties["physicsRestitution"]!, adjustBinding: false)
                            setInternalPhysicsRestitution(inst.properties["physicsRestitution"]!)
                        }
                    }
                } else
                if terminal.name == "physicsFriction" {
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        if inst.properties["physicsFriction"] == nil { inst.properties["physicsFriction"] = 0.3 }
                        setInternalPhysicsFriction(inst.properties["physicsFriction"]!)
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        if let object = inst.instance {
                            variable.setValue(object.properties["physicsFriction"]!, adjustBinding: false)
                            setInternalPhysicsFriction(object.properties["physicsFriction"]!)
                        } else {
                            variable.setValue(inst.properties["physicsFriction"]!, adjustBinding: false)
                            setInternalPhysicsFriction(inst.properties["physicsFriction"]!)
                        }
                    }
                }
            }
        }
    }
    
    override func executeWriteBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
        for target in uiConnections[0].targets {
            if let inst = target as? ObjectInstance {
                
                if terminal.name == "physicsMass" {
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        let value = variable.getValue()
                        
                        setInternalPhysicsMass(value)
                        if let object = inst.instance {
                            object.properties["physicsMass"] = value
                            if let body = object.body {
                                let physicsMode = object.getPhysicsMode()
                                if physicsMode == .Dynamic {
                                    body.mass = value
                                    if value == 0 {
                                        body.invMass = 0
                                    } else {
                                        body.invMass = 1 / value
                                    }
                                }
                            }
                        }
                        if nodeGraph.playNode == nil {
                            inst.properties["physicsMass"] = value
                        }
                    }
                } else
                if terminal.name == "physicsRestitution" {
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        let value = variable.getValue()
                        
                        setInternalPhysicsRestitution(value)
                        if let object = inst.instance {
                            object.properties["physicsRestitution"] = value
                            if let body = object.body {
                                body.restitution = value
                            }
                        }
                        if nodeGraph.playNode == nil {
                            inst.properties["physicsRestitution"] = value
                        }
                    }
                } else
                if terminal.name == "physicsFriction" {
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        let value = variable.getValue()
                        
                        setInternalPhysicsFriction(value)
                        if let object = inst.instance {
                            object.properties["physicsFriction"] = value
                            if let body = object.body {
                                body.dynamicFriction = value
                                body.staticFriction = value + 0.2
                            }
                        }
                        if nodeGraph.playNode == nil {
                            inst.properties["physicsFriction"] = value
                        }
                    }
                }
            }
        }
    }
    
    /// Execute Object physic properties
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) ->    Result
    {
        for target in uiConnections[0].targets {
            if let inst = target as? ObjectInstance {
                if let object = inst.instance {
                    object.properties["physicsMode"] = properties["physicsMode"]!
                    object.properties["physicsMass"] = properties["physicsMass"]!
                    object.properties["physicsRestitution"] = properties["physicsRestitution"]!
                    object.properties["physicsFriction"] = properties["physicsFriction"]!
                    object.properties["physicsSupportsRotation"] = properties["physicsSupportsRotation"]!
                    object.properties["physicsCollisions"] = properties["physicsCollisions"]!
                    return .Success
                }
            }
        }
        return .Failure
    }
    
    // Adjusts the internal physics mass
    func setInternalPhysicsMass(_ value: Float)
    {
        if let item = uiItems[2] as? NodeUINumber {
            item.value = value
        }
    }
    
    // Adjusts the internal physics restitution
    func setInternalPhysicsRestitution(_ value: Float)
    {
        if let item = uiItems[3] as? NodeUINumber {
            item.value = value
        }
    }
    
    // Adjusts the internal physics friction
    func setInternalPhysicsFriction(_ value: Float)
    {
        if let item = uiItems[4] as? NodeUINumber {
            item.value = value
        }
    }
}

class ObjectRender : Node
{
    override init()
    {
        super.init()
        name = "Render Props"
    }
    
    override func setup()
    {
        type = "Object Render"
        brand = .Property
        
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/21659649/Render+Properties"
        uiConnections.append(UINodeConnection(.ObjectInstance))
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "instance", title: "Instance", connection: uiConnections[0]),
            NodeUISelector(self, variable: "renderMode", title: "Mode", items: ["Color", "PBR", "Distance"], index: 1),
            NodeUISelector(self, variable: "aaLevel", title: "Anti-Aliasing", items: ["None", "Good", "Best"], index: 0),

            NodeUISelector(self, variable: "bBox", title: "Bounding Box", items: ["Screen", "Object Size"], index: 0),
            NodeUINumber(self, variable: "bBoxBorder", title: "Bounding Border", range: SIMD2<Float>(0, 500), value: 0)
        ]
        
        super.setupUI(mmView: mmView)
    }
    
    override func setupTerminals()
    {
        terminals = [
            //Terminal(name: "updateMode", connector: .Right, brand: .FloatVariable, node: self),
        ]
    }
    
    override func updateUIState(mmView: MMView)
    {
        let mode = properties["bBox"]!
        uiItems[4].isDisabled = mode == 0
        
        super.updateUIState(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// A UI Variable changed
    override func variableChanged(variable: String, oldValue: Float, newValue: Float, continuous: Bool = false, noUndo: Bool = false)
    {
        if variable == "renderMode" || variable == "aaLevel" {
            // Update scene
            if let scene = uiConnections[0].masterNode as? Scene {
                scene.updateStatus = .NeedsHardUpdate
            }
            if let object = globalApp!.nodeGraph.currentMaster as? Object {
                object.properties[variable] = newValue
                object.updatePreview(nodeGraph: globalApp!.nodeGraph, hard: true)
                globalApp!.mmView.update()
            }
        }
    
        if noUndo == false {
            super.variableChanged(variable: variable, oldValue: oldValue, newValue: newValue, continuous: continuous)
        }
    }
    
    /// Execute Object physic properties
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) ->    Result
    {
        for target in uiConnections[0].targets {
            if let inst = target as? ObjectInstance {
                if let object = inst.instance {
                    object.properties["renderMode"] = properties["renderMode"]!
                    object.properties["aaLevel"] = properties["aaLevel"]!
                    object.properties["bBox"] = properties["bBox"]!
                    object.properties["bBoxBorder"] = properties["bBoxBorder"]!
                    return .Success
                }
            }
        }
        return .Failure
    }
}

class ObjectCollision : Node
{
    override init()
    {
        super.init()
        name = "Collision Props"
    }
    
    override func setup()
    {
        type = "Object Collision"
        brand = .Property
        
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/19791995/Collision+Properties"
        uiConnections.append(UINodeConnection(.ObjectInstance))
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "instance", title: "Instance", connection: uiConnections[0]),
            NodeUIAngle(self, variable: "collisionVelocity", title: "Collision Velocity", value: 0),
            NodeUIAngle(self, variable: "collisionNormal", title: "Collision Normal", value: 0)
        ]
        
        super.setupUI(mmView: mmView)
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "collisionVelocity", connector: .Right, brand: .Float2Variable, node: self),
            Terminal(name: "collisionNormal", connector: .Right, brand: .Float2Variable, node: self)
        ]
    }
    
    override func updateUIState(mmView: MMView)
    {
        super.updateUIState(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //        test = try container.decode(Float.self, forKey: .test)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// A UI Variable changed
    override func variableChanged(variable: String, oldValue: Float, newValue: Float, continuous: Bool = false, noUndo: Bool = false)
    {
        if noUndo == false {
            super.variableChanged(variable: variable, oldValue: oldValue, newValue: newValue, continuous: continuous)
        }
    }
    
    override func executeReadBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
        for target in uiConnections[0].targets {
            if let inst = target as? ObjectInstance {
                
                if terminal.name == "collisionVelocity" {
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        if let object = inst.instance {
                            if let body = object.body {
                                setInternalVelocity(body.velocity)
                            } else {
                                setInternalVelocity()
                            }
                        }
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? Float2Variable {
                        if let object = inst.instance {
                            if let body = object.body {
                                variable.setValue(body.velocity)
                                setInternalVelocity(body.velocity)
                            } else {
                                setInternalVelocity()
                            }
                        } else {
                            setInternalVelocity()
                        }
                    }
                } else
                if terminal.name == "collisionNormal" {
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        setInternalNormal()
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? Float2Variable {
                        if let object = inst.instance {
                            if let body = object.body {
                                if let manifold = body.manifold {
                                    variable.setValue(manifold.normal)
                                    setInternalNormal(manifold.normal)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func executeWriteBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
        for target in uiConnections[0].targets {
            if let inst = target as? ObjectInstance {
                
                if terminal.name == "collisionVelocity" {
                    if let variable = terminal.connections[0].toTerminal!.node as? Float2Variable {
                        let value = variable.getValue()
                        
                        setInternalVelocity(value)
                        if let object = inst.instance {
                            if let body = object.body {
                                
                                if body.collisionMode == 2 && body.velocity != value {
                                    // Only set velocity when in custom collision mode
                                    body.velocity = value
                                
                                    let delta : Float = 1/60
                                    body.integrateVelocity(delta)
                                    body.integrateForces(delta)
                                
                                    body.force = SIMD2<Float>(0,0)
                                    body.torque = 0
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Execute Object physic properties
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) ->    Result
    {
        /*
        for target in uiConnections[0].targets {
            if let inst = target as? ObjectInstance {
                if let object = inst.instance {
                }
            }
        }*/
        return .Success
    }
    
    // Adjusts the internal velocity
    func setInternalVelocity(_ value: SIMD2<Float> = SIMD2<Float>(0,0))
    {
        if let item = uiItems[1] as? NodeUIAngle {
            let rad : Float = atan2(value.x, value.y)
            item.value = toDegrees(rad) - 90
        }
    }
    
    // Adjusts the internal normal
    func setInternalNormal(_ value: SIMD2<Float> = SIMD2<Float>(0,0))
    {
        if let item = uiItems[2] as? NodeUIAngle {
            let rad : Float = atan2(value.x, value.y)
            item.value = toDegrees(rad) - 90
        }
    }
}

class ObjectGlow : Node
{
    override init()
    {
        super.init()
        name = "Glow Effect"
        uiConnections.append(UINodeConnection(.ObjectInstance))
        
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/19595480/Glow+Properties"
    }
    
    override func setup()
    {
        type = "Object Glow"
        brand = .Property
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "instance", title: "Instance", connection: uiConnections[0]),
            NodeUISelector(self, variable: "glowMode", title: "Mode", items: ["Off", "On"], index: 0),
            NodeUIColor(self, variable: "glowColor", title: "Color", value: SIMD3<Float>(1,1,1)),
            NodeUINumber(self, variable: "glowOpacity", title: "Opacity", range: SIMD2<Float>(0, 1), value: 1),
            NodeUINumber(self, variable: "glowSize", title: "Size", range: SIMD2<Float>(0, 50), value: 10),
        ]
        
        super.setupUI(mmView: mmView)
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "glowColor", connector: .Right, brand: .Float3Variable, node: self),
            Terminal(name: "glowOpacity", connector: .Right, brand: .FloatVariable, node: self),
            Terminal(name: "glowSize", connector: .Right, brand: .FloatVariable, node: self)
        ]
    }
    
    override func updateUIState(mmView: MMView)
    {
        let mode = properties["glowMode"]!
        
        uiItems[2].isDisabled = mode == 0
        uiItems[3].isDisabled = mode == 0
        uiItems[4].isDisabled = mode == 0
        
        super.updateUIState(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //        test = try container.decode(Float.self, forKey: .test)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// A UI Variable changed
    override func variableChanged(variable: String, oldValue: Float, newValue: Float, continuous: Bool = false, noUndo: Bool = false)
    {
        //print("objectNodes variableChanged", oldValue, newValue)
        
        didConnectedFloatVariableChange(variable, "glowOpacity", uiItem: uiItems[3], connection: uiConnections[0], newValue: newValue)
        didConnectedFloatVariableChange(variable, "glowSize", uiItem: uiItems[4], connection: uiConnections[0], newValue: newValue)

        if variable == "glowMode" {
            let number = uiItems[1] as! NodeUISelector
            number.setValue(newValue)
            for target in uiConnections[0].targets {
                if let inst = target as? ObjectInstance {
                    inst.properties["glowMode"] = newValue
                    if let object = inst.instance {
                        object.properties["glowMode"] = newValue
                    }
                }
            }
        }
        
        // Update scene
        if let scene = uiConnections[0].masterNode as? Scene {
            scene.updateStatus = variable == "glowMode" ? .NeedsHardUpdate : .NeedsUpdate
        }
        
        if noUndo == false {
            super.variableChanged(variable: variable, oldValue: oldValue, newValue: newValue, continuous: continuous)
        }
    }
    
    /// A UI Variable changed: float3
    override func variableChanged(variable: String, oldValue: SIMD3<Float>, newValue: SIMD3<Float>, continuous: Bool = false, noUndo: Bool = false)
    {
        if variable == "glowColor" {
            let color = uiItems[2] as! NodeUIColor
            color.setValue(newValue)
            for target in uiConnections[0].targets {
                if let inst = target as? ObjectInstance {
                    inst.properties["glowColor_x"] = newValue.x
                    inst.properties["glowColor_y"] = newValue.y
                    inst.properties["glowColor_z"] = newValue.z
                    if let object = inst.instance {
                        object.properties["glowColor_x"] = newValue.x
                        object.properties["glowColor_y"] = newValue.y
                        object.properties["glowColor_z"] = newValue.z
                    }
                }
            }
        }
        
        // Update scene
        if let scene = uiConnections[0].masterNode as? Scene {
            scene.updateStatus = .NeedsUpdate
        }
        
        if noUndo == false {
            super.variableChanged(variable: variable, oldValue: oldValue, newValue: newValue, continuous: continuous)
        }
    }
    
    override func executeReadBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
        for target in uiConnections[0].targets {
            if let inst = target as? ObjectInstance {
                
                if terminal.name == "glowOpacity" {
                    if inst.properties["glowOpacity"] == nil { inst.properties["glowOpacity"] = properties["glowOpacity"] }
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        if inst.properties["glowOpacity"] == nil { inst.properties["glowOpacity"] = properties["glowOpacity"] }
                        setInternalGlowOpacity(inst.properties["glowOpacity"]!)
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        if let object = inst.instance {
                            if object.properties["glowOpacity"] == nil { object.properties["glowOpacity"] = properties["glowOpacity"] }
                            variable.setValue(object.properties["glowOpacity"]!, adjustBinding: false)
                            setInternalGlowOpacity(object.properties["glowOpacity"]!)
                        } else {
                            variable.setValue(inst.properties["glowOpacity"]!, adjustBinding: false)
                            setInternalGlowOpacity(inst.properties["glowOpacity"]!)
                        }
                    }
                } else
                if terminal.name == "glowColor" {
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        if inst.properties["glowColor_x"] == nil {
                            inst.properties["glowColor_x"] = properties["glowColor_x"]
                            inst.properties["glowColor_y"] = properties["glowColor_y"]
                            inst.properties["glowColor_z"] = properties["glowColor_z"]
                        }
                        setInternalGlowColor(inst.properties)
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? Float3Variable {
                        if let object = inst.instance {
                            variable.setValue(SIMD3<Float>(object.properties["glowColor_x"]!, object.properties["glowColor_y"]!, object.properties["glowColor_z"]!), adjustBinding: false)
                            setInternalGlowColor(object.properties)
                        } else {
                            variable.setValue(SIMD3<Float>(inst.properties["glowColor_x"]!, inst.properties["glowColor_y"]!, inst.properties["glowColor_z"]!), adjustBinding: false)
                            setInternalGlowColor(inst.properties)
                        }
                    }
                } else
                if terminal.name == "glowSize" {
                    if inst.properties["glowSize"] == nil { inst.properties["glowSize"] = properties["glowSize"] }
                    if terminal.connections.count == 0 {
                        // Not connected, adjust my own vars
                        setInternalGlowSize(inst.properties["glowSize"]!)
                    } else
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        if let object = inst.instance {
                            if object.properties["glowSize"] == nil { object.properties["glowSize"] = properties["glowSize"] }
                            variable.setValue(object.properties["glowSize"]!, adjustBinding: false)
                            setInternalGlowSize(object.properties["glowSize"]!)
                        } else {
                            variable.setValue(inst.properties["glowSize"]!, adjustBinding: false)
                            setInternalGlowSize(inst.properties["glowSize"]!)
                        }
                    }
                }
            }
        }
    }
    
    override func executeWriteBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
        for target in uiConnections[0].targets {
            if let inst = target as? ObjectInstance {
                
                if terminal.name == "glowOpacity" {
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        let value = variable.getValue()
                        
                        setInternalGlowOpacity(value)
                        if let object = inst.instance {
                            object.properties["glowOpacity"] = value
                        }
                        if nodeGraph.playNode == nil {
                            inst.properties["glowOpacity"] = value
                        }
                    }
                } else
                if terminal.name == "glowSize" {
                    if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                        let value = variable.getValue()
                        
                        setInternalGlowSize(value)
                        if let object = inst.instance {
                            object.properties["glowSize"] = value
                        }
                        if nodeGraph.playNode == nil {
                            inst.properties["glowSize"] = value
                        }
                    }
                } else
                if terminal.name == "glowColor" {
                    if let variable = terminal.connections[0].toTerminal!.node as? Float3Variable {
                        let value = variable.getValue()
                        
                        if let item = uiItems[2] as? NodeUIColor {
                            item.value = value
                            if let widget = item.colorWidget {
                                if widget.value != value {
                                    widget.setValue(color:value)
                                }
                            }
                        }
                        
                        if let object = inst.instance {
                            object.properties["glowColor_x"] = value.x
                            object.properties["glowColor_y"] = value.y
                            object.properties["glowColor_z"] = value.z
                        }
                        if nodeGraph.playNode == nil {
                            inst.properties["glowColor_x"] = value.x
                            inst.properties["glowColor_y"] = value.y
                            inst.properties["glowColor_z"] = value.z
                        }
                    }
                }
            }
        }
        
        // Update scene
        if let scene = uiConnections[0].masterNode as? Scene {
            scene.updateStatus = .NeedsUpdate
        }
    }
    
    // Adjusts the glow color
    func setInternalGlowColor(_ props: [String:Float])
    {
        if let item = uiItems[2] as? NodeUIColor {
            item.value = SIMD3<Float>(props["glowColor_x"]!, props["glowColor_y"]!, props["glowColor_z"]!)
            if let widget = item.colorWidget {
                widget.setValue(color: item.value)
            }
        }
    }
    
    // Adjusts the internal glow opacity
    func setInternalGlowOpacity(_ mode: Float)
    {
        if let item = uiItems[3] as? NodeUINumber {
            item.value = mode
        }
    }
    
    // Adjusts the glow size
    func setInternalGlowSize(_ mode: Float)
    {
        if let item = uiItems[4] as? NodeUINumber {
            item.value = mode
        }
    }
    
    /// Execute Object physic properties
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        /*
        if let object = root.objectRoot {
            let value = properties["glowMode"]!
            object.properties["glowMode"] = value
            object.properties["glowSize"] = properties["glowSize"]!
            object.properties["glowColor_r"] = properties["glowColor_r"]!
            object.properties["glowColor_g"] = properties["glowColor_g"]!
            object.properties["glowColor_b"] = properties["glowColor_b"]!
            object.properties["glowOpacity"] = properties["glowOpacity"]!
            
            return .Success
        }*/
        return .Success
    }
}

/// Resets an object
class ResetObject : Node
{
    override init()
    {
        super.init()
        
        name = "Reset Instance"
        uiConnections.append(UINodeConnection(.ObjectInstance))
    }
    
    override func setup()
    {
        brand = .Function
        type = "Object Reset"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/20316206/Reset+Instance"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self)
        ]
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "master", title: "Instance", connection: uiConnections[0])
        ]
        super.setupUI(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// Execute the given animation
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        
        if root.objectRoot != nil {
            if uiConnections[0].connectedTo != nil {
                if let inst = nodeGraph.getInstance(uiConnections[0].connectedTo!) {

                    //let object = inst.instanceOf!
                    
                    inst.properties["posX"] = inst.properties["copy_posX"]
                    inst.properties["posY"] = inst.properties["copy_posY"]
                    inst.properties["rotate"] = inst.properties["copy_rotate"]

                    if let body = inst.body {
                        body.velocity = SIMD2<Float>(0,0)
                        body.angularVelocity = 0
                        playResult = .Success
                    }
                }
            }
        }
        
        return playResult!
    }
}

class ObjectAnimation : Node
{
    override init()
    {
        super.init()
        
        name = "Play Animation"
        uiConnections.append(UINodeConnection(.Animation))
    }
    
    override func setup()
    {
        brand = .Function
        type = "Object Animation"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/9207830/Play+Animation"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self)
        ]
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIAnimationTarget(self, variable: "animation", title: "Animation", connection: uiConnections[0]),
            NodeUISelector(self, variable: "mode", title: "Mode", items: ["Loop", "Inverse Loop", "Goto Start", "Goto End"], index: 0),
            NodeUINumber(self, variable: "scale", title: "Scale", range: float2(0, 20), value: 1)
        ]
        super.setupUI(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// Execute the given animation
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure

        func applySequence(_ object: Object) {
            for seq in object.sequences {
                if seq.uuid == uiConnections[0].connectedTo {
                    
                    let mode = properties["mode"]!
                    let scale = properties["scale"]!
                    
                    object.setSequence(sequence: seq, timeline: nodeGraph.timeline)
                    object.setAnimationMode(Object.AnimationMode(rawValue: Int(mode))!, scale: scale)
                    
                    playResult = .Success
                    
                    break
                }
            }
        }
        
        if let instance = uiConnections[0].target as? ObjectInstance {
            if let object = instance.instance {
                applySequence(object)
            } else {
                // --- No instance, this should only happen in behavior preview for objects!
                if let object = root.objectRoot {
                    applySequence(object)
                }
            }
        }
        
        return playResult!
    }
}

/// Tests the current state of the animation
class ObjectAnimationState : Node
{
    override init()
    {
        super.init()
        
        name = "Get Animation State"
        uiConnections.append(UINodeConnection(.ObjectInstance))
    }
    
    override func setup()
    {
        brand = .Function
        type = "Object Animation State"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/20054029/Get+Animation+State"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self)
        ]
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "master", title: "Instance", connection: uiConnections[0]),
            NodeUISelector(self, variable: "state", title: "State", items: ["Not Animating", "At Start", "Going Forward", "Going Backward", "At End"], index: 0)
        ]
        super.setupUI(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// Execute the given animation
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        
        if root.objectRoot != nil {
            if uiConnections[0].connectedTo != nil {
                if let inst = nodeGraph.getInstance(uiConnections[0].connectedTo!) {
                    let state = properties["state"]!
                    
                    if Int(state) == inst.animationState.rawValue {
                        playResult = .Success
                    }
                }
            }
        }
        
        return playResult!
    }
}

/// Returns the distance to another object instance (both have to be under physics control)
class ObjectDistanceTo : Node
{
    override init()
    {
        super.init()
        
        name = "Distance To"
        
        uiConnections.append(UINodeConnection(.ObjectInstance))
        uiConnections.append(UINodeConnection(.ObjectInstance))
    }
    
    override func setup()
    {
        brand = .Function
        type = "Object Distance To"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/19988526/Distance+To"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self)
        ]
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "from", title: "From", connection: uiConnections[0]),
            NodeUIObjectInstanceTarget(self, variable: "to", title: "To", connection: uiConnections[1]),

            NodeUISelector(self, variable: "mode", title: "Distance", items: ["Equal To", "Smaller As", "Bigger As"], index: 0),
            NodeUINumber(self, variable: "value", title: "Value", range: nil, value: 1)
        ]
        super.setupUI(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// Execute the given animation
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        
        if uiConnections[0].connectedTo != nil {
            if let fromInstance = nodeGraph.getInstance(uiConnections[0].connectedTo!) {
                if uiConnections[1].connectedTo != nil {
                    if let toInstance = nodeGraph.getInstance(uiConnections[1].connectedTo!) {
                        if fromInstance.body != nil && toInstance.body != nil {
                            if let distance = fromInstance.body!.distanceInfos[toInstance.uuid] {
                             
                                let myMode : Float = properties["mode"]!
                                let myValue : Float = properties["value"]!
                                
                                if myMode == 0 {
                                    // Equal to
                                    if distance == myValue {
                                        playResult = .Success
                                    }
                                } else
                                if myMode == 1 {
                                    // Smaller as
                                    if distance < myValue {
                                        playResult = .Success
                                    }
                                } else
                                if myMode == 2 {
                                    // Bigger as
                                    if distance > myValue {
                                        playResult = .Success
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return playResult!
    }
}

/// Applies physical force to an object
class ObjectApplyForce : Node
{
    override init()
    {
        super.init()
        
        name = "Apply Force"
        
        uiConnections.append(UINodeConnection(.ObjectInstance))
        uiConnections.append(UINodeConnection(.FloatVariable))
    }
    
    override func setup()
    {
        brand = .Function
        type = "Object Apply Force"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/20217859/Apply+Force"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self)
        ]
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "master", title: "Instance", connection: uiConnections[0]),
            NodeUIFloatVariableTarget(self, variable: "power", title: "Force Value", connection: uiConnections[1]),
            NodeUINumber(self, variable: "scale", title: "Scale", range: SIMD2<Float>(0, 100), value: 10),
        ]
        super.setupUI(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// Execute the given animation
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        
        if root.objectRoot != nil {
            let scale = properties["scale"]!
            
            var power : Float = 0
            
            if let powerVariable = uiConnections[1].target as? FloatVariable {
//                let number = powerVariable.uiItems[0] as? NodeUINumber
                power = powerVariable.properties["value"]! * scale
            }
            
            //print( power, dir.x, dir.y )
            
            if uiConnections[0].connectedTo != nil {
                if let instance = nodeGraph.getInstance(uiConnections[0].connectedTo!) {

                    if let body = instance.body {
                        body.force.x = power * scale
                        body.force.y = power * scale
                        //print( body.force.x, body.force.y )
                    }
                }
            }
            
            playResult = .Success
        }
        
        return playResult!
    }
}

/// Applies directional physical force to an object
class ObjectApplyDirectionalForce : Node
{
    override init()
    {
        super.init()
        
        name = "Apply Directional Force"
        
        uiConnections.append(UINodeConnection(.ObjectInstance))
        uiConnections.append(UINodeConnection(.FloatVariable))
        uiConnections.append(UINodeConnection(.DirectionVariable))
    }
    
    override func setup()
    {
        brand = .Function
        type = "Object Apply Directional Force"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/19988503/Apply+Directional+Force"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self)
        ]
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "master", title: "Instance", connection: uiConnections[0]),
            NodeUIFloatVariableTarget(self, variable: "power", title: "Force Value", connection: uiConnections[1]),
            NodeUINumber(self, variable: "scale", title: "Scale", range: SIMD2<Float>(0, 100), value: 10),
            NodeUIDirectionVariableTarget(self, variable: "direction", title: "Force Direction", connection: uiConnections[2]),
        ]
        super.setupUI(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// Execute the given animation
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        
        if root.objectRoot != nil {
            let scale = properties["scale"]!
            
            var power : Float = 0
            var dir : SIMD2<Float> = SIMD2<Float>(0,0)
            
            if let powerVariable = uiConnections[1].target as? FloatVariable {
                //                let number = powerVariable.uiItems[0] as? NodeUINumber
                power = powerVariable.properties["value"]! * scale
            }
            
            if let dirVariable = uiConnections[2].target as? DirectionVariable {
                let angle = dirVariable.getValue()
                //print("angle", angle)
                dir.x = cos((360-angle) * Float.pi/180)
                dir.y = sin((360-angle) * Float.pi/180)
            }
            
            //print( power, dir.x, dir.y )
            
            if uiConnections[0].connectedTo != nil {
                if let instance = nodeGraph.getInstance(uiConnections[0].connectedTo!) {
                    
                    if let body = instance.body {
                        body.force.x = dir.x * power * scale
                        body.force.y = dir.y * power * scale
                        //print( body.force.x, body.force.y )
                    }
                }
            }
            
            playResult = .Success
        }
        
        return playResult!
    }
}

/// Detects any collision
class ObjectCollisionAny : Node
{
    override init()
    {
        super.init()
        
        name = "Collision (Any)"
        uiConnections.append(UINodeConnection(.ObjectInstance))
    }
    
    override func setup()
    {
        brand = .Function
        type = "Object Collision (Any)"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/20217880/Collision+Any"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self)
        ]
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "master", title: "Instance", connection: uiConnections[0])
        ]
        super.setupUI(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }

    /// Check if we collide with anything
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        
        if root.objectRoot != nil {
            
            if uiConnections[0].connectedTo != nil {
                if let instance = nodeGraph.getInstance(uiConnections[0].connectedTo!) {
                    
                    if let body = instance.body {
                        if body.manifold != nil {
                            playResult = .Success
                        }
                    }
                
                    //if let body = instance.body {
                    //    for (_, distance) in body.distanceInfos {
                    //        if distance < 0.2 {
                    //            playResult = .Success
                    //            print("yesyes")
                    //        }
                    //    }
                    //}
                }
            }
        }
        
        return playResult!
    }
}

/// Detects a collection with another instance
class ObjectCollisionWith : Node
{
    override init()
    {
        super.init()
        
        name = "Collision With"
        uiConnections.append(UINodeConnection(.ObjectInstance))
        uiConnections.append(UINodeConnection(.ObjectInstance))
    }
    
    override func setup()
    {
        brand = .Function
        type = "Object Collision With"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/20185109/Collision+With"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self)
        ]
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "master", title: "Instance", connection: uiConnections[0]),
            NodeUIObjectInstanceTarget(self, variable: "with", title: "With", connection: uiConnections[1])
        ]
        super.setupUI(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// Check if we collide with anything
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        
        if root.objectRoot != nil {
            
            if uiConnections[0].connectedTo != nil {
                if let instance = nodeGraph.getInstance(uiConnections[0].connectedTo!) {
                    if uiConnections[1].connectedTo != nil {
                        if let withInstance = nodeGraph.getInstance(uiConnections[1].connectedTo!) {
                            if let body = instance.body {
                                if let distanceTo = body.distanceInfos[withInstance.uuid] {
                                
                                    if distanceTo < 0.2 {
                                        playResult = .Success
                                        //print("collision with", withInstance.name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return playResult!
    }
}

/// Distance To Scene Area
class ObjectTouchSceneArea : Node
{
    override init()
    {
        super.init()
        
        name = "Touch Area ?"
        uiConnections.append(UINodeConnection(.ObjectInstance))
        uiConnections.append(UINodeConnection(.SceneArea))
    }
    
    override func setup()
    {
        brand = .Function
        type = "Object Touch Scene Area"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/19988547/Touches+Area"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self)
        ]
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIObjectInstanceTarget(self, variable: "master", title: "Instance", connection: uiConnections[0]),
            NodeUISceneAreaTarget(self, variable: "sceneArea", title: "Area", connection: uiConnections[1])
        ]
        
        super.setupUI(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //        test = try container.decode(Float.self, forKey: .test)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    /// Return Success if the selected key is currently down
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        
        var instanceObject : Object? = nil
        
        if root.objectRoot != nil {
            if uiConnections[0].connectedTo != nil {
                if let inst = nodeGraph.getInstance(uiConnections[0].connectedTo!) {
                    instanceObject = inst
                }
            }
        }
        
        if instanceObject == nil {
            return playResult!
        }
        
        if uiConnections[1].masterNode == nil || uiConnections[1].target == nil { return playResult! }
        
        if let layer = uiConnections[1].masterNode as? Scene {
            if let area = uiConnections[1].target as? SceneArea {
                if area.areaObject == nil || area.areaObject!.shapes.count == 0 { return playResult! }
                
                if instanceObject!.disks.count > 0 {
                    //print("mouse", area.name, mouse.x, mouse.y)
                    
                    let x : Float = instanceObject!.properties["posX"]! + instanceObject!.disks[0].xPos
                    let y : Float = instanceObject!.properties["posY"]! + instanceObject!.disks[0].yPos
                    let radius : Float = instanceObject!.disks[0].distance / 2
                    
                    let object = area.areaObject!
                    let shape = object.shapes[0]
                    
                    func rotateCW(_ pos : SIMD2<Float>, angle: Float) -> SIMD2<Float>
                    {
                        let ca : Float = cos(angle), sa = sin(angle)
                        return pos * float2x2(float2(ca, -sa), float2(sa, ca))
                    }
                    
                    var uv = SIMD2<Float>(x, y)
                    
                    uv -= SIMD2<Float>(object.properties["posX"]!, object.properties["posY"]!)
                    //uv /= float2(object.properties["scaleX"]!, object.properties["scaleY"]!)
                    
                    uv = rotateCW(uv, angle: object.properties["rotate"]! * Float.pi / 180 );
                    
                    let d : SIMD2<Float> = simd_abs( uv ) - SIMD2<Float>(shape.properties[shape.widthProperty]! * object.properties["scaleX"]!, shape.properties[shape.heightProperty]! * object.properties["scaleY"]!)
                    let dist : Float = simd_length(max(d,SIMD2<Float>(repeating: 0))) + min(max(d.x,d.y),0.0)
                    
                    //print( dist, dist - radius )
                    if dist < radius {
                        playResult = .Success
                        
                        if nodeGraph.debugMode == .SceneAreas {
                            let pos = SIMD2<Float>(object.properties["posX"]!, object.properties["posY"]!)
                            let size = SIMD2<Float>(shape.properties[shape.widthProperty]! * object.properties["scaleX"]!, shape.properties[shape.heightProperty]! * object.properties["scaleY"]!)
                            nodeGraph.debugInstance!.addBox(pos, size, 0, 0, SIMD4<Float>(0.541, 0.098, 0.125, 0.8))
                        }
                    }
                }
            }
        }
        return playResult!
    }
}

