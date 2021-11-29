//
//  ShaderManiaDocument.swift
//  Shared
//
//  Created by Markus Moenig on 19/11/20.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine

extension UTType {
    static var shaderManiaShader: UTType {
        UTType(exportedAs: "com.ShaderMania.shader")
    }
}

struct ShaderManiaDocument: FileDocument {

    var model                = Model()

    var core                 = Core()
    var updated              = false
    
    let exportImage          = PassthroughSubject<Void, Never>()
    let help                 = PassthroughSubject<Void, Never>()

    init() {
    }

    static var readableContentTypes: [UTType] { [.shaderManiaShader] }
    static var writableContentTypes: [UTType] { [.shaderManiaShader, .png] }

    /*
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }*/
    
    init(configuration: ReadConfiguration) throws {
                
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        if let project = try? JSONDecoder().decode(Project.self, from: data) {
            model.setProject(project)
        } else
        if let folder = try? JSONDecoder().decode(AssetFolder.self, from: data) {
            /// Backwards compatibility to ShaderMania v1.x            

            model.project.trees[0].children = []
            for asset in folder.assets {                
                // Create a node for the asset
                if asset.type == .Shader {
                    let node = Node()
                    node.name =  asset.name
                    node.setCode(asset.value)
                    node.setupTerminals()
                    model.project.trees[0].children?.append(node)
                }
            }
        }
    }
    
    /*
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }*/
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var data = Data()
        
        let encodedData = try? JSONEncoder().encode(core.assetFolder)
        if let json = String(data: encodedData!, encoding: .utf8) {
            data = json.data(using: .utf8)!
        }
        
        return .init(regularFileWithContents: data)
    }
}
