//
//  Asset.swift
//  ShaderMania
//
//  Created by Markus Moenig on 26/8/20.
//

// ONLY INCLUDED FOR BACKWARD COMPATIBILITY FOR v1

import MetalKit

/// A general purpose class representing an asset in the project
class Asset         : Codable, Equatable
{
    enum AssetType  : Int, Codable {
        case Buffer, Image, Shader, Audio, Texture, Common
    }
    
    var type        : AssetType = .Shader
    var id          = UUID()
    
    var name        = ""
    var value       = ""
    
    // For Drawing
    var nodeRect    = MMRect()
    var nodeIn      = [MMRect(), MMRect(),MMRect(),MMRect()]
    var nodeOut     = MMRect()

    var nodeData    = float4(0, 0, 0, 0)
    
    var data        : [Data] = []
    var dataIndex   : Int = 0
    var dataScale   : Double = 1
    
    // For the script based assets
    var scriptName  = ""

    // If this is a shader
    var shader      : Shader? = nil
    var shaderData  : [float4] = [float4(), float4(), float4(), float4(), float4(), float4(), float4(), float4(), float4(),float4()]
    var shaderDataNames  : [String] = [String(), String(), String(), String(), String(), String(), String(), String(), String(),String()]
    var errors      : [CompileError] = []
    
    // Texture In/Out
    
    var slots       : [Int: UUID] = [:]
    var output      : UUID? = nil
    
    // Textures
    var texture     : MTLTexture? = nil
    var previewTexture  : MTLTexture? = nil
    
    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case name
        case value
        case uuid
        case data
        case slots
        case output
        case nodeData
        case shaderData
        case shaderDataNames
    }
    
    init(type: AssetType, name: String, value: String = "", data: [Data] = [])
    {
        self.type = type
        self.name = name
        self.value = value
        self.data = data
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(AssetType.self, forKey: .type)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(String.self, forKey: .value)
        if let base64 = value.fromBase64() {
            value = base64
        }
        if let slots = try container.decodeIfPresent([Int:UUID].self, forKey: .slots) {
            self.slots = slots
        }
        if let output = try container.decodeIfPresent(UUID?.self, forKey: .output) {
            self.output = output
        }
        
        // Convert old projects
        if type == .Buffer || type == .Common {
            type = .Shader
        }
        
        data = try container.decode([Data].self, forKey: .data)
        if let nodeData = try container.decodeIfPresent(float4.self, forKey: .nodeData) {
            self.nodeData = nodeData
        }
        if let shaderData = try container.decodeIfPresent([float4].self, forKey: .shaderData) {
            self.shaderData = shaderData
        }
        if let shaderDataNames = try container.decodeIfPresent([String].self, forKey: .shaderDataNames) {
            self.shaderDataNames = shaderDataNames
        }        
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(value.toBase64(), forKey: .value)
        try container.encode(data, forKey: .data)
        try container.encode(slots, forKey: .slots)
        try container.encode(output, forKey: .output)
        try container.encode(nodeData, forKey: .nodeData)
        try container.encode(shaderData, forKey: .shaderData)
        try container.encode(shaderDataNames, forKey: .shaderDataNames)
    }
    
    deinit
    {
        if texture != nil {
            texture!.setPurgeableState(.volatile)
            texture = nil
        }
        
        if previewTexture != nil {
            previewTexture!.setPurgeableState(.volatile)
            previewTexture = nil
        }
    }
    
    static func ==(lhs:Asset, rhs:Asset) -> Bool { // Implement Equatable
        return lhs.id == rhs.id
    }
}
