//
//  BehaviorLeaves.swift
//  Shape-Z
//
//  Created by Markus Moenig on 22.04.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation
import simd

/// OSX: Key Is Down
class KeyDown : Node
{
    override init()
    {
        super.init()
        
        name = "Key Down"
    }
    
    override func setup()
    {
        type = "Key Down"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/20250714/OSX+Key+Down"
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
            NodeUIKeyDown(self, variable: "keyCode", title: "Key")
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
        
        #if os(OSX)
        let index = nodeGraph.mmView.keysDown.firstIndex{$0 == properties["keyCode"]!}
        
        if index != nil {
            playResult = .Success
        }
        #endif
        
        return playResult!
    }
}

/// Clicked in Scene Area
class ClickInSceneArea : Node
{
    override init()
    {
        super.init()
        
        name = "Click In Area"
        uiConnections.append(UINodeConnection(.SceneArea))
    }
    
    override func setup()
    {
        type = "Click In Scene Area"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/20348968/Click+in+Area"
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
            NodeUISceneAreaTarget(self, variable: "sceneArea", title: "Area", connection: uiConnections[0])
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
        
        if uiConnections[0].masterNode == nil || uiConnections[0].target == nil { return playResult! }
        
        if let layer = uiConnections[0].masterNode as? Scene {
            if let area = uiConnections[0].target as? SceneArea {
                if area.areaObject == nil || area.areaObject!.shapes.count == 0 { return playResult! }
                
                let screen = nodeGraph.mmScreen!
                let camera : Camera
                    
                if nodeGraph.app != nil {
                    camera = createNodeCamera(layer)
                } else {
                    camera = layer.gameCamera!
                }
                
                //#if os(iOS)
                //if nodeGraph.app != nil && nodeGraph.contentType == .Objects && screen.mouseDown == true && root.objectRoot != nil {
                //    playResult = .Success
                //}
                //#endif
                
                if screen.mouseDown == false {
                    return playResult!
                }
                
                if let mouse = screen.tranformToCamera(screen.mouseDownPos, camera) {
                    
                    let object = area.areaObject!
                    let shape = object.shapes[0]
                    
                    func rotateCW(_ pos : SIMD2<Float>, angle: Float) -> SIMD2<Float>
                    {
                        let ca : Float = cos(angle), sa = sin(angle)
                        return pos * float2x2(float2(ca, -sa), float2(sa, ca))
                    }
                    
                    var uv = SIMD2<Float>(mouse.x, -mouse.y)
                    
                    uv -= SIMD2<Float>(object.properties["posX"]!, object.properties["posY"]!)
                    //uv /= float2(object.properties["scaleX"]!, object.properties["scaleY"]!)
                    
                    uv = rotateCW(uv, angle: object.properties["rotate"]! * Float.pi / 180 );

                    let d : SIMD2<Float> = simd_abs( uv ) - SIMD2<Float>(shape.properties[shape.widthProperty]! * object.properties["scaleX"]!, shape.properties[shape.heightProperty]! * object.properties["scaleY"]!)
                    let dist : Float = simd_length(max(d,SIMD2<Float>(repeating: 0))) + min(max(d.x,d.y),0.0)

                    if dist < 0 {
                        playResult = .Success
                        
                        if nodeGraph.debugMode == .SceneAreas {
                            let pos = SIMD2<Float>(object.properties["posX"]!, object.properties["posY"]!)
                            let size = SIMD2<Float>(shape.properties[shape.widthProperty]! * object.properties["scaleX"]!, shape.properties[shape.heightProperty]! * object.properties["scaleY"]!)
                            nodeGraph.debugInstance!.addBox(pos, size, 0, 0, float4(0.541, 0.098, 0.125, 0.8))
                        }
                    }
                }
            }
        }
        return playResult!
    }
}

#if os(iOS)
import CoreMotion
#endif

/// Gyroscope
class Accelerometer : Node
{
    #if os(iOS)
    var motionManager   : CMMotionManager? = nil
    #endif
    var isValid         : Bool = false
    
    override init()
    {
        super.init()
        
        name = "iOS: Accelerometer"
        uiConnections.append(UINodeConnection(.Float2Variable))
    }
    
    override func setup()
    {
        type = "Accelerometer"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/19988601/iOS+Accelerometer"
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
            NodeUIFloat2VariableTarget(self, variable: "variable", title: "Float2", connection: uiConnections[0])
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
        
        #if os(iOS)
        if let float2Var = uiConnections[0].target as? Float2Variable {

            if motionManager == nil {
                
                isValid = false
                motionManager = CMMotionManager()
                if motionManager!.isAccelerometerAvailable {
                    motionManager!.accelerometerUpdateInterval = 1/60
                    motionManager!.startAccelerometerUpdates()
                    isValid = true
                }
            }
            
            if isValid {
                
                if let data = motionManager!.accelerometerData {
                    let accelData = SIMD2<Float>(Float(data.acceleration.x), Float(data.acceleration.y))
                    float2Var.setValue(accelData)
                    playResult = .Success
                }
            }
        }
        #endif
        
        return playResult!
    }
    
    override func finishExecution() {
        
        #if os(iOS)
        if motionManager != nil {
            motionManager?.stopAccelerometerUpdates()
            motionManager = nil
        }
        #endif
    }
}
