//
//  Scene.swift
//  ShaderMania
//
//  Created by Markus Moenig on 19/1/23.
//

import Foundation

class SceneNode : Codable, Equatable
{
    var uuid            : UUID = UUID()
    var name            : String = "Scene"
    
    var nodes           : [Node] = []
    
    private enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case nodes
    }

    init() {
        let node = Node(brand: .Object)
        node.children = []
        //tree.sequences.append( MMTlSequence() )
        //tree.currentSequence = object.sequences[0]
        node.setupTerminals()
        nodes.append(node)
        
        var shaderNode = Node(brand: .ShaderTree)

        shaderNode.name = "Shader Tree"
        //node.sequences.append( MMTlSequence() )
        //node.currentSequence = object.sequences[0]
        shaderNode.setupTerminals()
        node.children!.append(shaderNode)
        
        shaderNode = Node(brand: .Shader)

        shaderNode.name = "Shader"
        //node.sequences.append( MMTlSequence() )
        //node.currentSequence = object.sequences[0]
        shaderNode.setupTerminals()
        node.children!.append(shaderNode)
    }
    
    deinit
    {
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(UUID.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
        nodes = try container.decode([Node].self, forKey: .nodes)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encode(nodes, forKey: .nodes)
    }
    
    static func ==(lhs: SceneNode, rhs: SceneNode) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
