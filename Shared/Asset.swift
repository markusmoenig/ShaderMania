//
//  Asset.swift
//  ShaderMania
//
//  Created by Markus Moenig on 26/8/20.
//

import MetalKit
import CloudKit

class AssetFolder       : Codable
{
    var assets          : [Asset] = []
    var game            : Game!
    var current         : Asset? = nil
        
    private enum CodingKeys: String, CodingKey {
        case assets
        case groups
    }
    
    init()
    {
        /*
        CKContainer.default().requestApplicationPermission(.userDiscoverability) { (status, error) in
                    CKContainer.default().fetchUserRecordID { (record, error) in
                        CKContainer.default().discoverUserIdentity(withUserRecordID: record!, completionHandler: { (userID, error) in
                            print(userID?.hasiCloudAccount)
                            print(userID?.lookupInfo?.phoneNumber)
                            print(userID?.lookupInfo?.emailAddress)
                            print((userID?.nameComponents?.givenName)! + " " + (userID?.nameComponents?.familyName)!)
                        })
                    }
                }
        */
    }
    
    func setup(_ game: Game)
    {
        self.game = game
        
        guard let commonPath = Bundle.main.path(forResource: "Common", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        if let value = try? String(contentsOfFile: commonPath, encoding: String.Encoding.utf8) {
            assets.append(Asset(type: .Common, name: "Common", value: value))
        }
        
        guard let path = Bundle.main.path(forResource: "Shader", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        if let value = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            assets.append(Asset(type: .Shader, name: "Final", value: value))
            current = assets[0]
        }
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        assets = try container.decode([Asset].self, forKey: .assets)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(assets, forKey: .assets)
    }
    
    func addBuffer(_ name: String)
    {
        guard let path = Bundle.main.path(forResource: "Shader", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        if let shaderTemplate = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            let asset = Asset(type: .Buffer, name: name, value: shaderTemplate)
            assets.append(asset)
            select(asset.id)
            game.scriptEditor?.createSession(asset)
        }
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
            game.scriptEditor?.createSession(asset)
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
        
        game.scriptEditor?.createSession(asset)
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
        
        game.scriptEditor?.createSession(asset)
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
        
        game.scriptEditor?.createSession(asset)
        select(asset.id)
    }
    
    func select(_ id: UUID)
    {
        for asset in assets {
            if asset.id == id {
                if asset.scriptName.isEmpty {
                    game.scriptEditor?.createSession(asset)
                }
                game.scriptEditor?.setAssetSession(asset)
                
                current = asset
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
                return try? game.textureLoader.newTexture(data: data, options: options)
            }
        }
        return nil
    }
    
    func assetUpdated(id: UUID, value: String)//, deltaStart: Int32, deltaEnd: Int32)
    {
        for asset in assets {
            if asset.id == id {
                asset.value = value
                if game.state == .Idle {
                    if asset.type == .Common {
                        assetCompile(asset)
                        //assetCompileAll()
                    } else {
                        assetCompile(asset)
                    }
                }
            }
        }
    }
    
    /// Compiles the Buffer or Shader asset
    func assetCompile(_ asset: Asset)
    {
        if asset.type == .Shader || asset.type == .Buffer || asset.type == .Common {
            game.shaderCompiler.compile(asset: asset, cb: { (shader, errors) in
                if shader == nil {
                    if Thread.isMainThread {
                        self.game.scriptEditor?.setErrors(errors)
                    } else {
                        DispatchQueue.main.sync {
                            self.game.scriptEditor?.setErrors(errors)
                        }
                    }
                } else {
                    asset.shader = nil
                    asset.shader = shader
                    
                    if Thread.isMainThread {
                        self.game.createPreview(asset)
                        //self.game.scriptEditor?.clearAnnotations()
                        self.game.scriptEditor?.setErrors(errors)
                    } else {
                        DispatchQueue.main.sync {
                            self.game.createPreview(asset)
                            //self.game.scriptEditor?.clearAnnotations()
                            self.game.scriptEditor?.setErrors(errors)
                        }
                    }
                }
            })
        }
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
                self.game.createPreview(asset)
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
    
    var data        : [Data] = []
    var dataIndex   : Int = 0
    var dataScale   : Double = 1
    
    var size        : SIMD2<Int>? = nil

    // For the script based assets
    var scriptName  = ""

    // If this is a shader
    var shader      : Shader? = nil

    // If the asset has an error
    var hasError    : Bool = false
    
    // Texture In/Out
    
    var slots       : [Int: UUID] = [:]
    var output      : UUID? = nil

    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case name
        case value
        case uuid
        case data
        case slots
        case output
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
        if let slots = try container.decodeIfPresent([Int:UUID].self, forKey: .slots) {
            self.slots = slots
        }
        if let output = try container.decodeIfPresent(UUID?.self, forKey: .output) {
            self.output = output
        }
        data = try container.decode([Data].self, forKey: .data)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        try container.encode(data, forKey: .data)
        try container.encode(slots, forKey: .slots)
        try container.encode(output, forKey: .output)
    }
    
    static func ==(lhs:Asset, rhs:Asset) -> Bool { // Implement Equatable
        return lhs.id == rhs.id
    }
}
