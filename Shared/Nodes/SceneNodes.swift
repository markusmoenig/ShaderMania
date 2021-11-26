//
//  LayerNodes.swift
//  Shape-Z
//
//  Created by Markus Moenig on 7.06.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation

class SceneArea : Node
{
    var areaObject  : Object? = nil
    
    private enum CodingKeys: String, CodingKey {
        case type
        case areaObject
    }
    
    override init()
    {
        super.init()
        
        areaObject = Object()
        name = "Area"
    }
    
    override func setup()
    {
        type = "Scene Area"
        brand = .Property
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/9207837/Area"
        //minimumSize = Node.NodeWithPreviewSize
        maxDelegate = SceneAreaMaxDelegate()
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        areaObject = try container.decode(Object?.self, forKey: .areaObject)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(areaObject, forKey: .areaObject)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUISelector(self, variable: "status", title: "Status", items: ["Enabled", "Disabled"], index: 0)
        ]
        super.setupUI(mmView: mmView)
    }
    
    /// Apply the control points to the objects profile array
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Success
        
        //if properties["status"] != nil && properties["status"]! == 0 {
        //    if let _ = root.objectRoot {
        //    }
        //}
        return playResult!
    }
}

class SceneGravity : Node
{
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override init()
    {
        super.init()
        
        name = "Gravity"
    }
    
    override func setup()
    {
        type = "Scene Gravity"
        brand = .Property
        
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/9142364/Gravity"
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
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIAngle(self, variable: "orientation", title: "", value: 90),
            NodeUINumber(self, variable: "angle", title: "Direction", range: SIMD2<Float>(0,360), value: 90),
            NodeUINumber(self, variable: "strength", title: "Strength", range: SIMD2<Float>(0,10), value: 5),
            NodeUINumber(self, variable: "raw", title: "From Float2", value: 0),
            NodeUINumber(self, variable: "rawY", title: "", value: 0)
        ]
        
        uiItems[1].linkedTo = uiItems[0]
        uiItems[0].linkedTo = uiItems[1]
        
        super.setupUI(mmView: mmView)
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "raw", connector: .Right, brand: .Float2Variable, node: self)
        ]
    }
    
    override func updateUIState(mmView: MMView)
    {
        uiItems[3].isDisabled = true
        uiItems[4].isDisabled = true

        super.updateUIState(mmView: mmView)
    }
    
    override func executeReadBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
        if terminal.name == "raw" {
            
            if terminal.connections.count == 0 {
                // Not connected, adjust my own vars
                setInternalData(SIMD2<Float>(0, 0))
            } else
            if let variable = terminal.connections[0].toTerminal!.node as? Float2Variable {
                variable.setValue(SIMD2<Float>(0, 0), adjustBinding: false)
                setInternalData(SIMD2<Float>(0, 0))
            }
        }
    }
    
    override func executeWriteBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
        if terminal.name == "raw" {
            if let variable = terminal.connections[0].toTerminal!.node as? Float2Variable {
                let value = variable.getValue()

                setInternalData(value)
                
                // Update scene
                if let scene = nodeGraph.currentlyPlaying {
                    let strength = properties["strength"]!
                    scene.properties["physicsGravityX"] = -value.y * strength * 10
                    scene.properties["physicsGravityY"] = value.x * strength * 10
                }
            }
        }
    }
    
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Success
        
        let angle = properties["angle"]!
        let strength = properties["strength"]!
        let dir = SIMD2<Float>(cos((360-angle) * Float.pi/180) * strength * 10, sin((360-angle) * Float.pi/180) * strength * 10)
        
        if let scene = root.sceneRoot {
            
            scene.properties["physicsGravityX"] = dir.x
            scene.properties["physicsGravityY"] = dir.y
            
            return .Success
        }
        
        return playResult!
    }
    
    // Adjusts the internal data
    func setInternalData(_ data: SIMD2<Float>)
    {
        if let item = uiItems[3] as? NodeUINumber {
            item.value = data.x
        }
        if let item = uiItems[4] as? NodeUINumber {
            item.value = data.y
        }
    }
}

class SceneDeviceOrientation : Node
{
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override init()
    {
        super.init()
        
        name = "iOS: Device Orientation"
    }
    
    override func setup()
    {
        type = "iOS: Device Orientation"
        brand = .Property
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/28639233/Device+Orientation+iOS"
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
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUISelector(self, variable: "orientation", title: "Orientation", items: ["All", "Portrait", "Portrait U. Down", "Landscape Left", "Landscape Right"], index: 0)
        ]
        super.setupUI(mmView: mmView)
    }
    
    override func finishExecution() {
        #if os(iOS)
            OrientationController.forceLockOrientation(.unknown)
        #endif
    }
    
    /// Apply the control points to the objects profile array
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        #if os(iOS)

        playResult = .Success
        
        let orientation: Int = Int(properties["orientation"]!)
        switch(orientation)
        {
            case 0: OrientationController.forceLockOrientation(.unknown); break
            case 1: OrientationController.forceLockOrientation(.portrait); break
            case 2: OrientationController.forceLockOrientation(.portraitUpsideDown); break
            case 3: OrientationController.forceLockOrientation(.landscapeLeft); break
            case 4: OrientationController.forceLockOrientation(.landscapeRight); break
            
            default: OrientationController.forceLockOrientation(.unknown); break
        }

        #else

        playResult = .Failure
        
        #endif

        return playResult!
    }
}


class SceneFinished : Node
{
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override init()
    {
        super.init()
        
        name = "Finished"
    }
    
    override func setup()
    {
        type = "Scene Finished"
        brand = .Function
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
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self),
        ]
    }
    
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Success
        
        if let scene = root.sceneRoot {
            if scene.runningInRoot != nil && scene.runBy != nil {
                scene.runningInRoot!.hasRun.append(scene.runBy!)
            }
            //if nodeGraph.playNode != nil && scene.uuid == nodeGraph.playNode!.uuid {
            else
            {
                nodeGraph.stopPreview()
            }
        }

        return playResult!
    }
}

class SceneLight : Node
{
    var currScene   : Scene? = nil
    var lightNumber : Int = 0
    
    override init()
    {
        super.init()
        name = "Light"
    }
    
    override func setup()
    {
        type = "Scene Light"
        brand = .Property
        
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/25329700/Light"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUIColor(self, variable: "color", title: "Color", value: SIMD3<Float>(1,1,1)),
            NodeUINumber(self, variable: "position", title: "X", range: SIMD2<Float>(-4000,4000), value: 10),
            NodeUINumber(self, variable: "y", title: "Y", range: SIMD2<Float>(-4000,4000), value: 0),
            NodeUINumber(self, variable: "height", title: "Height", range: SIMD2<Float>(0,200), value: 100),
            NodeUINumber(self, variable: "power", title: "Power", range: SIMD2<Float>(0,100), value: 3.15),
            NodeUISelector(self, variable: "type", title: "Type", items: ["Directional", "Spherical"], index: 0)
        ]
        
        super.setupUI(mmView: mmView)
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "position", connector: .Right, brand: .Float2Variable, node: self),
            Terminal(name: "power", connector: .Right, brand: .FloatVariable, node: self),
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
        if let scene = nodeGraph?.getMasterForNode(self) as? Scene {
            scene.updateStatus = .NeedsHardUpdate
            //if scene.builderInstance?.scene == nil {
            //    scene.updateStatus = .NeedsHardUpdate
            //} else {
            //    scene.updateStatus = .NeedsUpdate
            //}
            nodeGraph?.mmView.update()
        }

        if noUndo == false {
            super.variableChanged(variable: variable, oldValue: oldValue, newValue: newValue, continuous: continuous)
        }
    }
    
    /// A UI Variable changed
    override func variableChanged(variable: String, oldValue: SIMD3<Float>, newValue: SIMD3<Float>, continuous: Bool = false, noUndo: Bool = false)
    {
        if let scene = nodeGraph?.getMasterForNode(self) as? Scene {
            scene.updateStatus = .NeedsHardUpdate
            nodeGraph?.mmView.update()
        }

        if noUndo == false {
            super.variableChanged(variable: variable, oldValue: oldValue, newValue: newValue, continuous: continuous)
        }
    }
    
    override func executeReadBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
        if terminal.name == "position" {
            if terminal.connections.count == 0 {
            } else
            if let variable = terminal.connections[0].toTerminal!.node as? Float2Variable {
                variable.setValue(SIMD2<Float>(properties["position"]!, properties["y"]!), adjustBinding: false)
                setInternalPos(SIMD2<Float>(properties["position"]!, properties["y"]!))
                updateSettings()
            }
        } else
        if terminal.name == "power" {
            if terminal.connections.count == 0 {
            } else
            if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                variable.setValue(properties["power"]!, adjustBinding: false)
                setInternalPower(properties["power"]!)
                updateSettings()
            }
        }
    }
    
    override func executeWriteBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
        if terminal.name == "position" {
            if let variable = terminal.connections[0].toTerminal!.node as? Float2Variable {
                let value = variable.getValue()
                                
                setInternalPos(value)
                properties["position"] = value.x
                properties["y"] = value.y
                updateSettings()
            }
        } else
        if terminal.name == "power" {
            if let variable = terminal.connections[0].toTerminal!.node as? FloatVariable {
                let value = variable.getValue()
                                
                setInternalPower(value)
                properties["power"] = value
                updateSettings()
            }
        }
        
        if !nodeGraph.isPlaying(), let scene = nodeGraph.getMasterForNode(self) as? Scene {
            scene.updateStatus = .NeedsHardUpdate
            nodeGraph.mmView.update()
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
    
    // Adjusts the internal power
    func setInternalPower(_ mode: Float)
    {
        if let item = uiItems[4] as? NodeUINumber {
            item.value = mode
        }
    }
    
    /// Execute Object physic properties
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) ->    Result
    {
        currScene = nil
        if let scene = root.sceneRoot {
            currScene = scene
            lightNumber = Int(scene.properties["numberOfLights"]!)

            updateSettings()
            
            scene.properties["numberOfLights"] = Float(lightNumber + 1)
        }
        return .Success
    }
    
    func updateSettings()
    {
        if let scene = currScene {
            
            scene.properties["light_\(lightNumber)_color_x"] = properties["color_x"]!
            scene.properties["light_\(lightNumber)_color_y"] = properties["color_y"]!
            scene.properties["light_\(lightNumber)_color_z"] = properties["color_z"]!

            scene.properties["light_\(lightNumber)_posX"] = properties["position"]!
            scene.properties["light_\(lightNumber)_posY"] = properties["y"]!
            scene.properties["light_\(lightNumber)_posZ"] = properties["height"]!

            let type : Float = properties["type"]!
            scene.properties["light_\(lightNumber)_radius"] = 1000//properties["radius"]!
            
            var power : Float = properties["power"]!
            if type == 1 {
                power *= 100
            }
            
            scene.properties["light_\(lightNumber)_power"] = power
            scene.properties["light_\(lightNumber)_type"] = type == 0 ? 1.0 : 0.0
        }
    }
}
