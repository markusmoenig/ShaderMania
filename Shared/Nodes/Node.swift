//
//  Node.swift
//  Shape-Z
//
//  Created by Markus Moenig on 12/2/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit


/// 2D Camera for Node system
class Camera : Codable
{
    var xPos            : Float = 0
    var yPos            : Float = 0
    var zoom            : Float = 1
    
    convenience init(x: Float, y: Float, zoom: Float)
    {
        self.init()
        
        self.xPos = x
        self.yPos = y
        self.zoom = zoom
    }
}

//

class Node : Codable, Equatable
{
    enum Brand {
        case Shader, Property, Behavior, Function, Arithmetic
    }

    enum Result {
        case Success, Failure, Running, Unused
    }
    
    var brand           : Brand = .Shader
    var type            : String = ""
    var properties      : [String: Float]

    var name            : String = ""
    var uuid            : UUID = UUID()
    
    var xPos            : Float = 50
    var yPos            : Float = 50

    var rect            : MMRect = MMRect()
    
    var maxDelegate     : NodeMaxDelegate?
    
    var label           : MMTextLabel?
    var menu            : MMMenuWidget?
    
    var data            : NODE_DATA = NODE_DATA()
    var buffer          : MTLBuffer? = nil
    
    var codeData        = Data("".utf8)
    var codeDataChanged = false
    
    /// The compiled shader if this is a shader node
    var shader          : Shader? = nil
    
    var texture         : MTLTexture? = nil
    
    var shaderData      : [float4] = [float4(), float4(), float4(), float4(), float4(), float4(), float4(), float4(), float4(),float4()]
    var shaderDataNames  : [String] = [String(), String(), String(), String(), String(), String(), String(), String(), String(),String()]
    var errors          : [CompileError] = []
    
    /// The session id for the script editor
    var scriptSessionId = ""
    
    var previewTexture  : MTLTexture?
    
    var terminals       : [Terminal] = []
    var bindings        : [Terminal] = []
    
    var uiItems         : [NodeUI] = []
    var uiConnections   : [UINodeConnection] = []

    var minimumSize     : SIMD2<Float> = SIMD2<Float>()
    var uiArea          : MMRect = MMRect()
    var uiMaxTitleSize  : SIMD2<Float> = SIMD2<Float>()
    var uiMaxWidth      : Float = 0

    // The subset of nodes and camera for root nodes
    var subset          : [UUID]? = nil
    var camera          : Camera? = nil
    var children        : [Node]? = nil
    
    // Used only for root nodes during playback
    var behaviorTrees   : [BehaviorTree]? = nil
    var behaviorRoot    : BehaviorTreeRoot? = nil
    
    // Set for behavior nodes to allow for tree scaling
    var behaviorTree    : BehaviorTree? = nil

    var playResult      : Result? = nil
    var helpUrl         : String? = nil

    var nodeGraph       : NodeGraph? = nil
    
    /// Static sizes
    static var NodeWithPreviewSize : SIMD2<Float> = SIMD2<Float>(260,220)
    static var NodeMinimumSize     : SIMD2<Float> = SIMD2<Float>(230,65)

    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case properties
        case uuid
        case xPos
        case yPos
        case terminals
        case uiConnections
        case camera
        case children
        case codeData
    }
    
    init()
    {
        properties = [:]
        minimumSize = Node.NodeMinimumSize
        setup()
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        properties = try container.decode([String: Float].self, forKey: .properties)
        uuid = try container.decode(UUID.self, forKey: .uuid)
        xPos = try container.decode(Float.self, forKey: .xPos)
        yPos = try container.decode(Float.self, forKey: .yPos)
        terminals = try container.decode([Terminal].self, forKey: .terminals)
        uiConnections = try container.decode([UINodeConnection].self, forKey: .uiConnections)
        camera = try container.decodeIfPresent(Camera.self, forKey: .camera)
        children = try container.decode([Node]?.self, forKey: .children)
        codeData = try container.decode(Data.self, forKey: .codeData)

        for terminal in terminals {
            terminal.node = self
        }
        
        minimumSize = Node.NodeMinimumSize
        setup()
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(properties, forKey: .properties)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(xPos, forKey: .xPos)
        try container.encode(yPos, forKey: .yPos)
        try container.encode(terminals, forKey: .terminals)
        try container.encode(uiConnections, forKey: .uiConnections)
        try container.encode(camera, forKey: .camera)
        try container.encode(children, forKey: .children)
        try container.encode(codeData, forKey: .codeData)
    }
    
    /// Equatable
    static func ==(lhs:Node, rhs:Node) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    /// Sets the code of the node
    func setCode(_ c: String) {
        codeData = Data(c.utf8)
        codeDataChanged = true
    }
    
    /// Retrieves the code of the node
    func getCode() -> String {
        return String(decoding: codeData, as: UTF8.self)
    }
    
    func onConnect(myTerminal: Terminal, toTerminal: Terminal)
    {
    }
    
    func onDisconnect(myTerminal: Terminal, toTerminal: Terminal)
    {
    }
    
    /// Executes a node inside a behaviour tree
    func execute(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node) -> Result
    {
        return .Success
    }
    
    /// Executes a an asynchronous node, that is a node which runs over time, these nodes are installed in the currentlyRunning array in  root
    func executeAsync(nodeGraph: NodeGraph, root: BehaviorTreeRoot, parent: Node)
    {
    }
    
    func finishExecution()
    {
    }
    
    /// Sets up the node terminals
    func setupTerminals()
    {
    }
    
    /// Setup the UI of the node
    func setupUI(mmView: MMView)
    {
        computeUIArea(mmView: mmView)
    }
    
    /// Update the UI elements of the node
    func updateUI(mmView: MMView)
    {
        for item in uiItems {
            item.update()
        }
        updateUIState(mmView: mmView)
    }
    
    /// Update the UI State
    func updateUIState(mmView: MMView)
    {
        // Attach the active bindings for this node
        bindings = []
        for t in terminals {
            if t.connector == .Right {
                for (index, uiItem) in uiItems.enumerated() {
                    if uiItem.variable == t.name {
                        uiItem.isDisabled = t.connections.count == 1
                        t.uiIndex = index
                        if t.connections.count > 0 {
                            bindings.append(t)
                        }
                        executeReadBinding(self.nodeGraph!, t)
                    }
                }
            }
        }
    }
    
    /// Setup
    func setup()
    {
    }
    
    /// Recomputes the UI area of the node
    func computeUIArea(mmView: MMView)
    {
        uiArea.width = 0; uiArea.height = 0;
        uiMaxTitleSize.x = 0; uiMaxTitleSize.y = 0
        uiMaxWidth = 0
        
        for item in uiItems {
            item.calcSize(mmView: mmView)
            
            uiArea.width = max(uiArea.width, item.rect.width)
            uiArea.height += item.rect.height
            uiMaxTitleSize.x = max(uiMaxTitleSize.x, item.titleLabel!.rect.width)
            uiMaxTitleSize.y = max(uiMaxTitleSize.y, item.titleLabel!.rect.height)
            uiMaxWidth = max(uiMaxWidth, item.rect.width -  item.titleLabel!.rect.width)
        }
        uiMaxTitleSize.x += NodeUI.titleMargin.width()
        uiMaxTitleSize.y += NodeUI.titleMargin.height()
        
        uiArea.width = uiMaxTitleSize.x + uiMaxWidth
        uiArea.height += 6
        
        uiMaxWidth -= NodeUI.titleMargin.width() + NodeUI.titleSpacing
        
        updateUIState(mmView: mmView)
    }
    
    /// A UI Variable changed
    func variableChanged(variable: String, oldValue: Float, newValue: Float, continuous: Bool = false, noUndo: Bool = false)
    {
        /*
        func applyProperties(_ uuid: UUID, _ variable: String,_ old: Float,_ new: Float)
        {
            nodeGraph!.mmView.undoManager!.registerUndo(withTarget: self) { target in
                if let node = globalApp!.nodeGraph.getNodeForUUID(uuid) {
                    node.properties[variable] = new
                    
                    applyProperties(uuid, variable, new, old)
                    node.updateUI(mmView: node.nodeGraph!.mmView)
                    node.variableChanged(variable: variable, oldValue: old, newValue: new, continuous: false, noUndo: true)
                    globalApp!.nodeGraph.mmView.update()
                }
            }
            nodeGraph!.mmView.undoManager!.setActionName("Node Property Changed")
            
        }
        
        if continuous == false {
            applyProperties(self.uuid, variable, newValue, oldValue)
        }
        self.updateUIState(mmView: self.nodeGraph!.mmView)*/
    }
    
    func variableChanged(variable: String, oldValue: SIMD3<Float>, newValue: SIMD3<Float>, continuous: Bool = false, noUndo: Bool = false)
    {
        /*
        func applyProperties(_ uuid: UUID, _ variable: String,_ old: SIMD3<Float>,_ new: SIMD3<Float>)
        {
            nodeGraph!.mmView.undoManager!.registerUndo(withTarget: self) { target in
                if let node = globalApp!.nodeGraph.getNodeForUUID(uuid) {
                    node.properties[variable + "_x"] = new.x
                    node.properties[variable + "_y"] = new.y
                    node.properties[variable + "_z"] = new.z

                    applyProperties(uuid, variable, new, old)
                    node.updateUI(mmView: node.nodeGraph!.mmView)
                    node.variableChanged(variable: variable, oldValue: old, newValue: new, continuous: false, noUndo: true)
                    globalApp!.nodeGraph.mmView.update()
                }
            }
            nodeGraph!.mmView.undoManager!.setActionName("Node Property Changed")
        }
        
        if continuous == false {
            applyProperties(self.uuid, variable, newValue, oldValue)
        }
        self.updateUIState(mmView: self.nodeGraph!.mmView)*/
    }
    
    /// Executes the connected properties
    func executeProperties(_ nodeGraph: NodeGraph)
    {
        let propertyNodes = nodeGraph.getPropertyNodes(for: self)
        
        for node in propertyNodes {
            _ = node.execute(nodeGraph: nodeGraph, root: BehaviorTreeRoot(self), parent: self)
        }
    }
    
    /// Update the preview of the node
    func updatePreview(nodeGraph: NodeGraph, hard: Bool = false)
    {
    }
    
    /// Create a live preview if supported
    func livePreview(nodeGraph: NodeGraph, rect: MMRect)
    {
    }
    
    /// Read bindings for this terminal
    func executeReadBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
    }
    
    /// Write bindings for this terminal
    func executeWriteBinding(_ nodeGraph: NodeGraph, _ terminal: Terminal)
    {
    }
    
    /// Called during variableChanged to check if a float variable has to be changed
    func didConnectedFloatVariableChange(_ variable: String,_ variableName: String, uiItem: NodeUI, connection: UINodeConnection, newValue: Float)
    {
        /*
        if variable == variableName {
            let number = uiItem as! NodeUINumber
            number.setValue(newValue)
            for target in connection.targets {
                if let inst = target as? ObjectInstance {
                    inst.properties[variableName] = newValue
                    if let object = inst.instance {
                        object.properties[variableName] = newValue
                    }
                }
            }
        }*/
    }
}

/// Connects UI items to nodes of other objects, layers, etc

class UINodeConnection: Codable
{
    enum ConnectionType: Int, Codable {
        case Object, ObjectInstance, Animation, FloatVariable, DirectionVariable, SceneArea, Scene, Float2Variable, BehaviorTree, Float3Variable
    }
    
    var connectionType      : ConnectionType = .FloatVariable
    
    var connectedRoot       : UUID? = nil
    var connectedTo         : UUID? = nil
    
    var rootNode            : Node? = nil
    var target              : Any? = nil
    var targetName          : String? = nil
    
    var targets             : [Any] = []

    var nodeGraph           : NodeGraph? = nil
    
    var uiRootPicker        : NodeUIRootPicker? = nil
    var uiPicker            : NodeUISelector? = nil
    var uiTarget            : NodeUIDropTarget? = nil

    private enum CodingKeys: String, CodingKey {
        case connectionType
        case connectedRoot
        case connectedTo
    }
    
    init(_ connectionType: ConnectionType)
    {
        self.connectionType = connectionType
        self.connectedRoot = nil
        self.connectedTo = nil
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connectionType = try container.decode(ConnectionType.self, forKey: .connectionType)
        connectedRoot = try container.decode(UUID?.self, forKey: .connectedRoot)
        connectedTo = try container.decode(UUID?.self, forKey: .connectedTo)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(connectionType, forKey: .connectionType)
        try container.encode(connectedRoot, forKey: .connectedRoot)
        try container.encode(connectedTo, forKey: .connectedTo)
    }
}

/// Terminal class, connects nodes
class Terminal : Codable
{
    enum Connector : Int, Codable {
        case Left, Top, Right, Bottom
    }
    
    enum Brand : Int, Codable {
        case All, Properties, Behavior, FloatVariable, Float2Variable, DirectionVariable, Float3Variable
    }
    
    var name            : String = ""
    var connector       : Connector = .Left
    var brand           : Brand = .All
    var uuid            : UUID!
    
    var uiIndex         : Int = -1
    
    var posX            : Float = 0
    var posY            : Float = 0
    
    var readBinding     : ((Terminal) -> ())? = nil
    var writeBinding    : ((Terminal) -> ())? = nil

    var connections     : [Connection] = []
    
    var node            : Node? = nil

    private enum CodingKeys: String, CodingKey {
        case name
        case connector
        case brand
        case uuid
        case connections
    }
    
    init(name: String? = nil, uuid: UUID? = nil, connector: Terminal.Connector? = nil, brand: Terminal.Brand? = nil, node: Node)
    {
        self.name = name != nil ? name! : ""
        self.uuid = uuid != nil ? uuid! : UUID()
        self.connector = connector != nil ? connector! : .Left
        self.brand = brand != nil ? brand! : .All
        self.node = node
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        connector = try container.decode(Connector.self, forKey: .connector)
        uuid = try container.decode(UUID.self, forKey: .uuid)
        brand = try container.decode(Brand.self, forKey: .brand)
        connections = try container.decode([Connection].self, forKey: .connections)
        
        for connection in connections {
            connection.terminal = self
        }
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(connector, forKey: .connector)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(brand, forKey: .brand)
        try container.encode(connections, forKey: .connections)
    }
}

/// Connection between two terminals
class Connection : Codable
{
    var uuid            : UUID!
    var terminal        : Terminal?
    
    /// UUID of the Terminal this connection is connected to
    var toTerminalUUID  : UUID!
    /// UUID of the Connection this connection is connected to
    var toUUID          : UUID!
    var toTerminal      : Terminal? = nil
    
    private enum CodingKeys: String, CodingKey {
        case uuid
        case toTerminalUUID
        case toUUID
    }
    
    init(from: Terminal, to: Terminal)
    {
        uuid = UUID()
        self.terminal = from
        
        toTerminalUUID = to.uuid
        toTerminal = to
    }
}

/// Handles the maximized UI of a node
class NodeMaxDelegate
{
    func activate()
    {
    }
    
    func deactivate()
    {
    }
    
    func setChanged()
    {
    }
    
    func drawRegion(_ region: MMRegion)
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
    
    func mouseScrolled(_ event: MMMouseEvent)
    {
    }
    
    func pinchGesture(_ scale: Float,_ firstTouch: Bool)
    {
    }
    
    func update(_ hard: Bool = false, updateLists: Bool = false)
    {
    }
    
    func getCamera() -> Camera?
    {
        return nil
    }
    
    func getTimeline() -> MMTimeline?
    {
        return nil
    }
}

/// A class describing the root node of a behavior tree
class BehaviorTreeRoot
{
    var rootNode        : Node
    //var objectRoot      : Object? = nil
    //var sceneRoot       : Scene? = nil
    
    var runningNode     : Node? = nil

    /// List of
    var hasRun          : [UUID] = []
    
    /// List of asynchronous nodes which are currently running for this tree
    var asyncNodes      : [Node] = []
    
    init(_ node : Node)
    {
        rootNode = node
        //objectRoot = node as? Object
        //sceneRoot = node as? Scene
    }
    
    /// Install a node to the async nodes
    func installAsyncNode(_ node: Node) -> Bool
    {
        if !asyncNodes.contains(node) {
            asyncNodes.append(node)
            return true
        }
        return false
    }
    
    /// Remove a node from the async nodes
    func deinstallAsyncNode(_ node: Node)
    {
        asyncNodes.removeAll(where: { (n) -> Bool in
            n.uuid == node.uuid
        })
    }
}
