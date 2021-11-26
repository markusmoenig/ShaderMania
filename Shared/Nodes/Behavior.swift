//
//  Behavior.swift
//  Shape-Z
//
//  Created by Markus Moenig on 23.02.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation

class BehaviorTree : Node
{
    override init()
    {
        super.init()
        
        name = "Behavior Tree"
    }
    
    override func setup()
    {
        type = "Behavior Tree"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/5505133/Behavior+Tree"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "Behavior", connector: .Bottom, brand: .Behavior, node: self)
        ]
    }
    
    override func setupUI(mmView: MMView)
    {
        uiItems = [
            NodeUISelector(self, variable: "status", title: "Execute", items: ["Always", "On Startup", "On Demand"], index: 0),
            NodeUINumber(self, variable: "treeScale", title: "Scale", range: SIMD2<Float>(0, 1), value: 1)
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
    
    override func variableChanged(variable: String, oldValue: Float, newValue: Float, continuous: Bool = false, noUndo: Bool = false)
    {
        if variable == "treeScale" {
            properties[variable] = newValue
            uiItems[0].mmView.update()
        }
        if noUndo == false {
            super.variableChanged(variable: variable, oldValue: oldValue, newValue: newValue, continuous: continuous)
        }
    }
    
    /// Execute the attached behavior nodes
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Success
        
        for terminal in terminals {
            
            if terminal.connector == .Bottom {
                for conn in terminal.connections {
                    let toTerminal = conn.toTerminal!
                    playResult = toTerminal.node!.execute(nodeGraph: nodeGraph, root: root, parent: self)
                }
            }
        }
        
        return playResult!
    }
}

class Sequence : Node
{
    override init()
    {
        super.init()
        
        name = "Sequence"
    }
    
    override func setup()
    {
        type = "Sequence"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/5734443/Sequence"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self),

            Terminal(name: "Behavior1", connector: .Bottom, brand: .Behavior, node: self),
            Terminal(name: "Behavior2", connector: .Bottom, brand: .Behavior, node: self),
            Terminal(name: "Behavior3", connector: .Bottom, brand: .Behavior, node: self),
            Terminal(name: "Behavior4", connector: .Bottom, brand: .Behavior, node: self),
            Terminal(name: "Behavior5", connector: .Bottom, brand: .Behavior, node: self)
        ]
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
    
    /// Return Success if all behavior outputs succeeded
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Success
        for terminal in terminals {
            
            if terminal.connector == .Bottom {
                for conn in terminal.connections {
                    let toTerminal = conn.toTerminal!
                    playResult = toTerminal.node!.execute(nodeGraph: nodeGraph, root: root, parent: self)
                    if playResult == .Failure {
                        return .Failure
                    }
                    if playResult == .Running {
                        return .Running
                    }
                }
            }
        }
        
        return playResult!
    }
}

class Selector : Node
{
    override init()
    {
        super.init()
        
        name = "Selector"
    }
    
    override func setup()
    {
        type = "Selector"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/5505069/Selector"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self),
            
            Terminal(name: "Behavior1", connector: .Bottom, brand: .Behavior, node: self),
            Terminal(name: "Behavior2", connector: .Bottom, brand: .Behavior, node: self),
            Terminal(name: "Behavior3", connector: .Bottom, brand: .Behavior, node: self),
            Terminal(name: "Behavior4", connector: .Bottom, brand: .Behavior, node: self),
            Terminal(name: "Behavior5", connector: .Bottom, brand: .Behavior, node: self)
        ]
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
    
    /// Return Success if the first encountered behavior output succeeded
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        for terminal in terminals {
            
            if terminal.connector == .Bottom {
                for conn in terminal.connections {
                    let toTerminal = conn.toTerminal!
                    playResult = toTerminal.node!.execute(nodeGraph: nodeGraph, root: root, parent: self)
                    if playResult == .Success {
                        return .Success
                    }
                    if playResult == .Running {
                        return .Running
                    }
                }
            }
        }
        
        return playResult!
    }
}

class Inverter : Node
{
    override init()
    {
        super.init()
        
        name = "Inverter"
    }
    
    override func setup()
    {
        type = "Inverter"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/5537868/Inverter"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self),
            
            Terminal(name: "Behavior", connector: .Bottom, brand: .Behavior, node: self)
        ]
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
    
    /// Return Success if all behavior outputs succeeded
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Success
        for terminal in terminals {
            
            if terminal.connector == .Bottom {
                for conn in terminal.connections {
                    let toTerminal = conn.toTerminal!
                    playResult = toTerminal.node!.execute(nodeGraph: nodeGraph, root: root, parent: self)
                    if playResult == .Failure {
                        playResult = .Success
                    } else
                    if playResult == .Success {
                        playResult = .Failure
                    }
                }
            }
        }
        
        return playResult!
    }
}

class Succeeder : Node
{
    override init()
    {
        super.init()
        
        name = "Succeeder"
    }
    
    override func setup()
    {
        type = "Succeeder"
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/20381701/Succeeder"
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override func setupTerminals()
    {
        terminals = [
            Terminal(name: "In", connector: .Top, brand: .Behavior, node: self),
            Terminal(name: "Behavior", connector: .Bottom, brand: .Behavior, node: self)
        ]
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
    
    /// Return Success if all behavior outputs succeeded
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Success
        for terminal in terminals {
            
            if terminal.connector == .Bottom {
                for conn in terminal.connections {
                    let toTerminal = conn.toTerminal!
                    playResult = toTerminal.node!.execute(nodeGraph: nodeGraph, root: root, parent: self)
                    playResult = .Success
                }
            }
        }
        
        return playResult!
    }
}

class Repeater : Node
{
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    override init()
    {
        super.init()
        
        name = "Repeater"
    }
    
    override func setup()
    {
        type = "Repeater"
        brand = .Behavior
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/19955870/Repeater"
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
            Terminal(name: "Behavior", connector: .Bottom, brand: .Behavior, node: self)
        ]
    }
    
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Success
        for terminal in terminals {
            if terminal.connector == .Bottom {
                for conn in terminal.connections {
                    let toTerminal = conn.toTerminal!
                    playResult = toTerminal.node!.execute(nodeGraph: nodeGraph, root: root, parent: self)
                    if playResult! != .Running {
                        root.hasRun = []
                    }
                }
            }
        }
        return playResult!
    }
}

class ExecuteBehaviorTree : Node
{
    override init()
    {
        super.init()
        
        name = "Execute Tree"
        uiConnections.append(UINodeConnection(.BehaviorTree))
        
        helpUrl = "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/9109510/Execute+Tree"
    }
    
    override func setup()
    {
        brand = .Behavior
        type = "Execute Behavior Tree"
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
            NodeUIBehaviorTreeTarget(self, variable: "tree", title: "Tree", connection:  uiConnections[0])
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
    
    /// Reset the value variable
    override func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        playResult = .Failure
        if let tree = uiConnections[0].target as? BehaviorTree {
            playResult = tree.execute(nodeGraph: nodeGraph, root: root, parent: self)
        }
        return playResult!
    }
}
