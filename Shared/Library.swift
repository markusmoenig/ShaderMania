//
//  Library.swift
//  ShaderMania
//
//  Created by Markus Moenig on 17/2/21.
//

import Foundation
import CloudKit
import CoreGraphics

class LibraryShader
{
    var id              = UUID()

    var name            : String = ""
    var description     : String = ""

    var cgiImage        : CGImage? = nil
    var folder          : AssetFolder? = nil

    var userRecord      : CKRecord? = nil
}

class LibraryShaderList
{
    var shaders         : [LibraryShader] = []
    
    deinit {
        for shader in shaders {
            shader.cgiImage = nil
            shader.folder = nil
            shader.userRecord = nil
        }
        shaders = []
    }
}

class Library
{
    private let thumbnailRenderSize = SIMD2<Int>(360, 240)

    let core            : Core
    
    var project         : Project
    
    let container       : CKContainer
    
    let privateDatabase : CKDatabase
    let publicDatabase  : CKDatabase
    
    var userId          : CKRecord.ID? = nil
    var userNickName    : String = ""
    var userDescription : String = ""

    var currentList     : LibraryShaderList? = nil
    var authorList      : LibraryShaderList? = nil

    init(_ core: Core)
    {
        self.core = core
        
        container = CKContainer.init(identifier: "iCloud.com.moenig.ShaderMania")
        
        privateDatabase = container.privateCloudDatabase
        publicDatabase = container.publicCloudDatabase
        
        project = Project()

        container.fetchUserRecordID { recordID, error in
            guard let recordID = recordID, error == nil else {
                return
            }
            
            self.userId = recordID
            
            self.container.publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
                if let record = record {
                    if let existing = record["nickName"] as? String {
                        self.userNickName = existing
                    }
                    if let existing = record["description"] as? String {
                        self.userDescription = existing
                    }
                }
            }
        }        
    }
    
    func uploadFolder()
    {
        guard let folder = core.assetFolder else {
            return
        }

        let summary = makeSummary(for: folder)
        guard LibraryQuality.isUploadable(summary) else {
            print("Library upload rejected: \(LibraryQuality.uploadIssues(for: summary))")
            return
        }

        updateUserInfo()
            let encodedData = try? JSONEncoder().encode(folder)
            if let encodedData = encodedData, let encodedFolder = String(data: encodedData, encoding: .utf8)
            {
            let recordID  = CKRecord.ID(recordName: folder.libraryName)
            let record    = CKRecord(recordType: "Shaders", recordID: recordID)

            record["description"] = folder.libraryDescription
            record["json"] = encodedFolder
            record["tags"] = folder.libraryTags

            var tagList = folder.libraryTags.lowercased().split(separator: " ").map(String.init)
            tagList.append(contentsOf: folder.libraryDescription.lowercased().split(separator: " ").map(String.init))
            tagList.append(folder.libraryName.lowercased())

            record["tagList"] = tagList as __CKRecordObjCValue

            var uploadComponents = [CKRecord]()
            uploadComponents.append(record)

            let operation = CKModifyRecordsOperation(recordsToSave: uploadComponents, recordIDsToDelete: nil)
            operation.savePolicy = .allKeys

#if os(iOS)
            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, operationError in

                if let error = operationError {
                    print( "Error: " + error.localizedDescription)
                }

                if savedRecords != nil {
                    print( "Success" )
                }
            }
#else
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("Success")
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
#endif
            
            publicDatabase.add(operation)
        }
    }

    private func makeSummary(for folder: AssetFolder) -> LibraryProjectSummary {
        LibraryProjectSummary(
            name: folder.libraryName,
            description: folder.libraryDescription,
            tags: folder.libraryTags,
            assets: folder.assets.map { asset in
                LibraryAssetSummary(
                    type: makeSummaryType(for: asset.type),
                    name: asset.name,
                    source: asset.value
                )
            }
        )
    }

    private func makeSummaryType(for type: Asset.AssetType) -> LibraryAssetSummary.AssetType {
        switch type {
        case .Shader, .Common:
            return .shader
        case .Image:
            return .image
        case .Audio:
            return .audio
        case .Texture:
            return .texture
        default:
            return .other
        }
    }

    func updateUserInfo()
    {
        if let recordID = userId {
            container.publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
                guard let record = record, error == nil else {
                    return
                }
                
                record["nickName"] = self.userNickName
                record["description"] = self.userDescription

                self.container.publicCloudDatabase.save(record) { _, error in
                    guard error == nil else {
                        return
                    }

                    print("Successfully updated user info")
                }
            }
        }
    }
    
    /// Request shaders based on the search field
    func requestShaders(_ searchFor: String = "")
    {
        if searchFor == "" {
            let predicate = NSPredicate(value: true)
            
            currentList = getShaders(predicate, { (list) -> () in
                self.currentList = list
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.core.libraryChanged.send(self.currentList)
                }
            })
        } else {
            //predicate = NSPredicate(format: "self contains %@", searchFor)
            //predicate = NSPredicate(format: "allTokens TOKENMATCHES[cdl]  %@"), searchFor)
            
            let p1 = NSPredicate(format: "tags BEGINSWITH %@", searchFor)
            let p2 = NSPredicate(format: "tagList CONTAINS %@", searchFor)

            let mergeList = LibraryShaderList()

            currentList = getShaders(p1, { (list) -> () in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.core.libraryChanged.send(self.currentList)
                }
            }, mergeList)
            
            currentList = getShaders(p2, { (list) -> () in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.core.libraryChanged.send(self.currentList)
                }
            }, mergeList)
            
            /*
            query(predicate, { (list) -> () in
                self.currentList = list
                
                print("got", list.shaders.count)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.core.libraryChanged.send(self.currentList)
                }
            })*/
        }
    }
    
    /// Get the shaders for the author of this shader
    func requestShadersOfShaderAuthor(_ shader: LibraryShader)
    {
        guard let userRecord = shader.userRecord else {
            return
        }

        let reference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        let predicate = NSPredicate(format: "creatorUserRecordID == %@", reference)
        
        authorList = getShaders(predicate, { (list) -> () in
            self.authorList = list
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.core.libraryChanged.send(self.authorList)
            }
        })
    }

    func query(_ predicate: NSPredicate,_ cb: @escaping (LibraryShaderList)->())
    {
        let query = CKQuery(recordType: "Shaders", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        //queryOperation.desiredKeys = [""]
        //queryOperation.queuePriority = .veryHigh

#if os(iOS)
        queryOperation.recordFetchedBlock = { (record: CKRecord!) -> Void in
            print("got something")
            if let shaderRecord = record {
            //this is where you are appending to your array
                //self.moviesArray.append(moviesRecord)
                print(shaderRecord.recordID.recordName)
            }
        }
        
        queryOperation.queryCompletionBlock = { cursor, error in
        }
#else
        queryOperation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                print("got something")
                print(record.recordID.recordName)
            case .failure(let error):
                print("Shader query record failed for \(recordID.recordName): \(error.localizedDescription)")
            }
        }

        queryOperation.queryResultBlock = { result in
            if case .failure(let error) = result {
                print("Shader query failed: \(error.localizedDescription)")
            }
        }
#endif

        publicDatabase.add(queryOperation)
    }

    @discardableResult func getShaders(_ predicate: NSPredicate,_ cb: @escaping (LibraryShaderList)->(),_ mergeList: LibraryShaderList? = nil) -> LibraryShaderList
    {
        let list = mergeList ?? LibraryShaderList()
        let publicQuery = CKQuery(recordType: "Shaders", predicate: predicate)
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        publicQuery.sortDescriptors = [sort]

        let addRecordToList: (CKRecord) -> Void = { record in
            let shader = LibraryShader()
            shader.name = record.recordID.recordName

            if let description = record.value(forKey: "description") as? String {
                shader.description = description
            }

            if let creatorUserRecordID = record.creatorUserRecordID {
                self.container.publicCloudDatabase.fetch(withRecordID: creatorUserRecordID) { record, error in
                    guard let record = record, error == nil else {
                        return
                    }

                    shader.userRecord = record
                }
            }

            if let json = record.value(forKey: "json") as? String {
                if let jsonData = json.data(using: .utf8) {

                    if let folder = try? JSONDecoder().decode(AssetFolder.self, from: jsonData) {
                        let summary = self.makeSummary(for: folder)
                        guard LibraryQuality.isDisplayable(summary) else {
                            return
                        }

                        shader.folder = folder

                        var current = folder.current
                        if current == nil && folder.assets.isEmpty == false {
                            current = folder.assets[0]
                        }

                        if let current = current {
                            self.project.compileAssets(assetFolder: folder, forAsset: current, compiler: self.core.shaderCompiler, finished: { () in
                                if let texture = self.project.render(assetFolder: folder, device: self.core.device, time: 0, frame: 0, viewSize: self.thumbnailRenderSize, forAsset: current) {

                                    self.project.stopDrawing(syncTexture: texture, waitUntilCompleted: true)

                                    if let cgiTexture = self.project.makeCGIImage(self.core.device, self.core.metalStates.getComputeState(state: .MakeCGIImage), texture) {
                                        if let image = makeCGIImage(texture: cgiTexture, forImage: true) {
                                            if list.shaders.contains(where: { $0.name == shader.name }) == false {
                                                list.shaders.append(shader)
                                            }
                                            shader.cgiImage = image
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                self.core.libraryChanged.send(list)
                                            }
                                        }
                                    }
                                }
                            })
                        }

                    }
                }
            }
        }

#if os(iOS)
        publicDatabase.perform(publicQuery, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Shader query failed: \(error.localizedDescription)")
            }

            records?.forEach { record in
                addRecordToList(record)
            }

            cb(list)
        }
#else
        let queryOperation = CKQueryOperation(query: publicQuery)
        queryOperation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                addRecordToList(record)
            case .failure(let error):
                print("Shader query record failed for \(recordID.recordName): \(error.localizedDescription)")
            }
        }

        queryOperation.queryResultBlock = { result in
            if case .failure(let error) = result {
                print("Shader query failed: \(error.localizedDescription)")
            }

            cb(list)
        }

        publicDatabase.add(queryOperation)
#endif
        
        return list
    }
    
    /// Adds the library to the curent project
    @discardableResult
    func addShaderToProject(_ shader: LibraryShader) -> [Asset]
    {
        guard let folder = shader.folder else {
            return []
        }

        let sourceAssets = folder.assets.filter { asset in
            asset.type == .Shader || asset.type == .Image
        }

        var idMap: [UUID: UUID] = [:]
        var importedAssets: [Asset] = []

        for sourceAsset in sourceAssets {
            guard let copiedAsset = copyAssetForImport(sourceAsset) else {
                continue
            }
            idMap[sourceAsset.id] = copiedAsset.id
            importedAssets.append(copiedAsset)
        }

        for asset in importedAssets {
            asset.slots = asset.slots.reduce(into: [Int: UUID]()) { result, item in
                result[item.key] = idMap[item.value] ?? item.value
            }
            if let output = asset.output {
                asset.output = idMap[output] ?? output
            }
        }

        core.assetFolder.assets.append(contentsOf: importedAssets)

        let selectedSourceId = folder.currentId ?? folder.current?.id
        let selectedAsset = selectedSourceId
            .flatMap { idMap[$0] }
            .flatMap { importedId in importedAssets.first { $0.id == importedId } }
            ?? importedAssets.first { $0.type == .Shader }
            ?? importedAssets.first

        if let selectedAsset = selectedAsset {
            core.nodesWidget.selectNode(selectedAsset)
        }

        core.nodesWidget.update()
        core.contentChanged.send()

        return importedAssets
    }

    private func copyAssetForImport(_ asset: Asset) -> Asset?
    {
        guard let data = try? JSONEncoder().encode(asset),
              let copiedAsset = try? JSONDecoder().decode(Asset.self, from: data) else {
            return nil
        }

        copiedAsset.id = UUID()
        copiedAsset.shader = nil
        copiedAsset.texture = nil
        copiedAsset.previewTexture = nil
        return copiedAsset
    }
}
