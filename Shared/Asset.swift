//
//  Asset.swift
//  ShaderMania
//
//  Created by Markus Moenig on 26/8/20.
//

import MetalKit
import CloudKit

/// Base64 extension for string
extension String {

func fromBase64() -> String? {
    guard let data = Data(base64Encoded: self, options: Data.Base64DecodingOptions(rawValue: 0)) else {
        return nil
    }

    return String(data: data as Data, encoding: String.Encoding.utf8)
}

func toBase64() -> String? {
    guard let data = self.data(using: String.Encoding.utf8) else {
        return nil
    }

    return data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
}

class AssetFolder       : Codable
{
    var assets          : [Asset] = []
    
    var core            : Core!
    var current         : Asset? = nil
    var currentId       : UUID? = nil

    var customSize      : SIMD2<Int>? = nil
    
    var libraryName     : String = ""
    var libraryTags     : String = ""
    var libraryDescription : String = ""

    private enum CodingKeys: String, CodingKey {
        case assets
        case currentId
        case libraryName
        case libraryTags
        case libraryDescription
    }
    
    init()
    {
    }
    
    func setup(_ core: Core)
    {
        self.core = core
        
        guard let path = Bundle.main.path(forResource: "Shader", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        if let value = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            assets.append(Asset(type: .Shader, name: "Shader", value: value))
            current = assets[0]
            currentId = assets[0].id
        }
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        assets = try container.decode([Asset].self, forKey: .assets)
        if let id = try container.decodeIfPresent(UUID?.self, forKey: .currentId) {
            select(id!)
        }
        if let libraryName = try container.decodeIfPresent(String.self, forKey: .libraryName) {
            self.libraryName = libraryName
        }
        if let libraryTags = try container.decodeIfPresent(String.self, forKey: .libraryTags) {
            self.libraryTags = libraryTags
        }
        if let libraryDescription = try container.decodeIfPresent(String.self, forKey: .libraryDescription) {
            self.libraryDescription = libraryDescription
        }
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(assets, forKey: .assets)
        try container.encode(currentId, forKey: .currentId)
        try container.encode(libraryName, forKey: .libraryName)
        try container.encode(libraryTags, forKey: .libraryTags)
        try container.encode(libraryDescription, forKey: .libraryDescription)
    }
    
    func addShader(_ name: String)
    {
        guard let path = Bundle.main.path(forResource: "Shader", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        if let shaderTemplate = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            let asset = Asset(type: .Shader, name: name, value: shaderTemplate)
            assets.append(asset)
            select(asset.id)
            core.scriptEditor?.createSession(asset)
        }
    }
    
    func addImages(_ name: String, _ urls: [URL], existingAsset: Asset? = nil)
    {
        let asset: Asset
            
        if existingAsset != nil {
            asset = existingAsset!
        } else {
            asset = Asset(type: .Image, name: name)
            assets.append(asset)
        }

        for url in urls {
            if let imageData: Data = try? Data(contentsOf: url) {
                asset.data.append(imageData)
            }
        }
        
        core.scriptEditor?.createSession(asset)
        select(asset.id)
    }
    
    func attachImage(_ asset: Asset, _ url: URL)
    {
        asset.data = []
        if let imageData: Data = try? Data(contentsOf: url) {
            asset.data.append(imageData)
        }
        
        select(asset.id)
    }
    
    func addTexture(_ name: String)
    {
        let asset: Asset
            
        asset = Asset(type: .Texture, name: name)
        assets.append(asset)
        
        core.scriptEditor?.createSession(asset)
        select(asset.id)
    }
    
    func addAudio(_ name: String, _ urls: [URL], existingAsset: Asset? = nil)
    {
        let asset: Asset
            
        if existingAsset != nil {
            asset = existingAsset!
        } else {
            asset = Asset(type: .Audio, name: name)
            assets.append(asset)
        }

        for url in urls {
            if let audioData: Data = try? Data(contentsOf: url) {
                asset.data.append(audioData)
            }
        }
        
        core.scriptEditor?.createSession(asset)
        select(asset.id)
    }
    
    func select(_ id: UUID)
    {
        currentId = id
        for asset in assets {
            if asset.id == id {
                
                current = asset

                if core != nil {
                    if asset.scriptName.isEmpty {
                        core.scriptEditor?.createSession(asset)
                    }
                    core.scriptEditor?.setAssetSession(asset)
                }
                
                break
            }
        }
    }
    
    func getAsset(_ name: String,_ type: Asset.AssetType = .Shader) -> Asset?
    {
        for asset in assets {
            if asset.type == type && (asset.name == name || String(asset.name.split(separator: ".")[0]) == name) {
                return asset
            }
        }
        return nil
    }
    
    func getAssetById(_ id: UUID,_ type: Asset.AssetType = .Shader) -> Asset?
    {
        for asset in assets {
            if asset.type == type && asset.id == id {
                return asset
            }
        }
        return nil
    }
    
    func getAssetById(_ id: UUID) -> Asset?
    {
        for asset in assets {
            if asset.id == id {
                return asset
            }
        }
        return nil
    }
    
    func getAssetTexture(_ name: String,_ index: Int = 0) -> MTLTexture?
    {
        if let asset = getAsset(name, .Image) {
            if index >= 0 && index < asset.data.count {
                let data = asset.data[index]
                
                let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : false, .SRGB : false]                
                return try? core.textureLoader.newTexture(data: data, options: options)
            }
        }
        return nil
    }
    
    func assetUpdated(id: UUID, value: String)//, deltaStart: Int32, deltaEnd: Int32)
    {
        /*
        for asset in assets {
            if asset.id == id {
                asset.value = value
                core.contentChanged.send()
                if core.state == .Idle {
                    if asset.type == .Common {
                        assetCompile(asset)
                        //assetCompileAll()
                    } else {
                        assetCompile(asset)
                    }
                }
            }
        }
        */
    }
    
    /// Compiles the Buffer or Shader asset
    func assetCompile(_ asset: Asset)
    {
        /*
        if asset.type == .Shader || asset.type == .Buffer || asset.type == .Common {
            core.shaderCompiler.compile(asset: asset, cb: { (shader, errors) in
                if shader == nil {
                    if Thread.isMainThread {
                        self.core.scriptEditor?.setErrors(errors)
                    } else {
                        DispatchQueue.main.sync {
                            self.core.scriptEditor?.setErrors(errors)
                        }
                    }
                } else {
                    asset.shader = nil
                    asset.shader = shader
                    
                    if Thread.isMainThread {
                        self.core.createPreview(asset)
                        //self.core.scriptEditor?.clearAnnotations()
                        self.core.scriptEditor?.setErrors(errors)
                    } else {
                        DispatchQueue.main.sync {
                            self.core.createPreview(asset)
                            //self.core.scriptEditor?.clearAnnotations()
                            self.core.scriptEditor?.setErrors(errors)
                        }
                    }
                }
            })
        }*/
    }
    
    /// Compiles all assets, used after loading the project
    func assetCompileAll()
    {
        for asset in assets {
            assetCompile(asset)
        }
    }
    
    /// Safely removes an asset from the project
    func removeAsset(_ asset: Asset)
    {
        if let index = assets.firstIndex(of: asset) {
            assets.remove(at: index)
            select(assets[0].id)
        }
    }
    
    // Create a preview for the current asset
    func createPreview()
    {
        if let asset = current {
            if asset.type == .Shader {
                self.core.createPreview(asset)
            }
        }
    }
    
    func getSlotName(_ asset: Asset, _ index: Int) -> String {
        if let uuid = asset.slots[index] {
            if let textureAsset = getAssetById(uuid) {
                return textureAsset.name
            }
        }
        return "Black"
    }
    
    func getOutputName(_ asset: Asset) -> String {
        if let uuid = asset.output {
            if let textureAsset = getAssetById(uuid) {
                return textureAsset.name
            }
        }
        return "None"
    }
}

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
            texture!.setPurgeableState(.empty)
            texture = nil
        }
        
        if previewTexture != nil {
            previewTexture!.setPurgeableState(.empty)
            previewTexture = nil
        }
    }
    
    static func ==(lhs:Asset, rhs:Asset) -> Bool { // Implement Equatable
        return lhs.id == rhs.id
    }
}
