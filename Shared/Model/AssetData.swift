//
//  AssetData.swift
//  ShaderMania
//
//  Created by Markus Moenig on 19/1/23.
//

import Foundation

/// A general purpose class representing an asset in the project
class AssetData     : Codable, Equatable
{
    enum AssetDataType : Int, Codable {
        case Image
    }
    
    var type        : AssetDataType = .Image
    var uuid        = UUID()
    
    var name        = ""
    
    var data        : Data? = nil
    
    private enum CodingKeys: String, CodingKey {
        case type
        case uuid
        case name
        case data
    }
    
    init(type: AssetDataType, name: String, data: Data)
    {
        self.type = type
        self.name = name
        self.data = data
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(AssetDataType.self, forKey: .type)
        uuid = try container.decode(UUID.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
        data = try container.decode(Data?.self, forKey: .data)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encode(data, forKey: .data)
    }
    
    deinit
    {
    }
    
    static func ==(lhs: AssetData, rhs: AssetData) -> Bool { // Implement Equatable
        return lhs.uuid == rhs.uuid
    }
}
