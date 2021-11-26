//
//  GameNodes.swift
//  Shape-Z
//
//  Created by Markus Moenig on 22.04.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation

class GamePlatformOSX : Node
{
    override init()
    {
        super.init()
        
        name = "Platform: OSX"
    }
    
    override func setup()
    {
        type = "Platform OSX"
        brand = .Property
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/19955853/Platform+OSX"
    }
    
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            //NodeUIDropDown(self, variable: "animationMode", title: "Mode", items: ["Loop", "Inverse Loop", "Goto Start", "Goto End"], index: 0),
            NodeUINumber(self, variable: "width", title: "Width", range: SIMD2<Float>(100, 4096), int: true, value: 800),
            NodeUINumber(self, variable: "height", title: "Height", range: SIMD2<Float>(100, 4096), int: true, value: 600)
        ]
        super.setupUI(mmView: mmView)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //        test = try container.decode(Float.self, forKey: .test)
        
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
        
        type = "Platform OSX"
    }
    
    override func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        let superdecoder = container.superEncoder()
        try super.encode(to: superdecoder)
    }
    
    func getScreenSize() -> SIMD2<Float>
    {
        return SIMD2<Float>(properties["width"]!, properties["height"]!)
    }
    
    /// Return Success if the selected key is currently down
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        
        return playResult!
    }
}

class GamePlatformIPAD : Node
{
    override init()
    {
        super.init()
        
        name = "Platform: iOS"
    }
    
    override func setup()
    {
        type = "Platform IPAD"
        brand = .Property
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/19955863/Platform+iPAD"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            //NodeUIDropDown(self, variable: "type", title: "iPad", items: ["1536 x 2048", "2048 x 2732"], index: 0),
            //NodeUIDropDown(self, variable: "orientation", title: "Orientation", items: ["Vertical", "Horizontal"], index: 0),
            NodeUINumber(self, variable: "width", title: "Width", range: SIMD2<Float>(100, 4096), int: true, value: 800),
            NodeUINumber(self, variable: "height", title: "Height", range: SIMD2<Float>(100, 4096), int: true, value: 600)
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
    
    func getScreenSize() -> SIMD2<Float>
    {
        return SIMD2<Float>(properties["width"]!, properties["height"]!)
        /*
        var width : Float = 0
        var height : Float = 0
        
        let index = properties["type"]
        let orient = properties["orientation"]
        
        if index == 0 {
            width = 1536; height = 2048
        }
        if index == 1 {
            width = 2048; height = 2732
        } else
            if index == 2 {
                width = 2048; height = 2732
        }
        
        if orient == 1 {
            let temp = height
            height = width
            width = temp
        }
        
        return float2(width, height)*/
    }
    
    /// Return Success if the selected key is currently down
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        
        return playResult!
    }
}

class GamePlatformTVOS : Node
{
    override init()
    {
        super.init()
        
        name = "Platform: tvOS"
    }
    
    override func setup()
    {
        type = "Platform tvOS"
        brand = .Property
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/19955863/Platform+iPAD"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            //NodeUIDropDown(self, variable: "type", title: "iPad", items: ["1536 x 2048", "2048 x 2732"], index: 0),
            //NodeUIDropDown(self, variable: "orientation", title: "Orientation", items: ["Vertical", "Horizontal"], index: 0),
            NodeUINumber(self, variable: "width", title: "Width", range: SIMD2<Float>(100, 4096), int: true, value: 800),
            NodeUINumber(self, variable: "height", title: "Height", range: SIMD2<Float>(100, 4096), int: true, value: 600)
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
    
    func getScreenSize() -> SIMD2<Float>
    {
        return SIMD2<Float>(properties["width"]!, properties["height"]!)
        /*
        var width : Float = 0
        var height : Float = 0
        
        let index = properties["type"]
        let orient = properties["orientation"]
        
        if index == 0 {
            width = 1536; height = 2048
        }
        if index == 1 {
            width = 2048; height = 2732
        } else
            if index == 2 {
                width = 2048; height = 2732
        }
        
        if orient == 1 {
            let temp = height
            height = width
            width = temp
        }
        
        return float2(width, height)*/
    }
    
    /// Return Success if the selected key is currently down
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        
        return playResult!
    }
}

class GamePlayScene : Node
{
    var currentlyPlaying        : Scene? = nil
    var gameNode                : Game? = nil

    var toExecute               : [Node] = []
    var terminalBindings        : [Terminal] = []

    override init()
    {
        super.init()
        
        name = "Play Scene"
    }
    
    override func setup()
    {
        brand = .Function
        type = "Game Play Scene"
        uiConnections.append(UINodeConnection(.Scene))
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/20086957/Play+Scene"
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
            NodeUISceneTarget(self, variable: "scene", title: "Scene", connection:  uiConnections[0]),
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
    
    override func finishExecution() {
        currentlyPlaying = nil
        gameNode = nil
    }
    
    /// Play the Scene
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        
        // If scene has already run
        if root.hasRun.contains(self.uuid) {
            playResult = .Success
            currentlyPlaying = nil
            return playResult!
        }
        
        if let scene = uiConnections[0].masterNode as? Scene {
            
            if scene !== currentlyPlaying {
                
                currentlyPlaying = scene
                nodeGraph.currentlyPlaying = scene
                
                camera = Camera()

                toExecute = []
                
                scene.setupExecution(nodeGraph: nodeGraph)
                for inst in scene.objectInstances {
                    toExecute.append(inst.instance!)
                }
                toExecute.append(scene)
                
                // -- Collect bindings, TODO: Only use
                terminalBindings = []
                for node in nodeGraph.nodes {
                    if node.bindings.count > 0 {
                        terminalBindings.append(contentsOf: node.bindings)
                    }
                }
                
                for exe in toExecute {
                    exe.behaviorRoot = BehaviorTreeRoot(exe)
                    exe.behaviorTrees = []
                    let trees = nodeGraph.getBehaviorTrees(for: exe)
                    
                    for tree in trees {
                        let status = tree.properties["status"]!
                        
                        if status == 0 {
                            // Always execute
                            exe.behaviorTrees!.append(tree)
                        } else
                        if status == 1 {
                            // Execute all "On Startup" behavior trees
                            _ = tree.execute(nodeGraph: nodeGraph, root: exe.behaviorRoot!, parent: exe.behaviorRoot!.rootNode)
                        }
                    }
                }
                
                root.runningNode = self
                scene.runningInRoot = root
                scene.runBy = uuid
            }
            
            playResult = .Running
            
            for terminal in terminalBindings {
                terminal.node?.executeReadBinding(nodeGraph, terminal)
            }
            
            for exe in toExecute {
                let root = exe.behaviorRoot!
                
                /// Execute the async nodes currently in the tree
                for asyncNode in root.asyncNodes {
                    _ = asyncNode.executeAsync(nodeGraph: nodeGraph, root: root, parent: exe.behaviorRoot!.rootNode)
                }
                
                /// Execute the tree
                _ = exe.execute(nodeGraph: nodeGraph, root: root, parent: exe.behaviorRoot!.rootNode)
            }
            
            if gameNode == nil {
                gameNode = nodeGraph.getNodeOfType("Game") as? Game
            }
            
            if let game = gameNode {
                scene.updatePreview(nodeGraph: nodeGraph)
                game.currentScene = scene
            }
        }
        
        return playResult!
    }
}
