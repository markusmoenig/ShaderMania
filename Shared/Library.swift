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
        updateUserInfo()
        let encodedData = try? JSONEncoder().encode(core.assetFolder)
        if let encodedFolder = String(data: encodedData!, encoding: .utf8)
        {
            let folder = core.assetFolder!
            
            let recordID  = CKRecord.ID(recordName: folder.libraryName)
            let record    = CKRecord(recordType: "Shaders", recordID: recordID)

            record["description"] = core.assetFolder.libraryDescription
            record["json"] = encodedFolder
            record["tags"] = folder.libraryName
            
            var tagList = folder.libraryDescription.lowercased().split(separator: " ")
            tagList.append(String.SubSequence(folder.libraryName.lowercased()))
            
            record["tagList"] = tagList as __CKRecordObjCValue

            var uploadComponents = [CKRecord]()
            uploadComponents.append(record)

            let operation = CKModifyRecordsOperation(recordsToSave: uploadComponents, recordIDsToDelete: nil)
            operation.savePolicy = .allKeys

            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, operationError in

                if let error = operationError {
                    print( "Error: " + error.localizedDescription)
                }

                if savedRecords != nil {
                    print( "Success" )
                }
            }
            
            publicDatabase.add(operation)
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
        let reference = CKRecord.Reference(recordID: shader.userRecord!.recordID, action: .none)
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
        
        publicDatabase.add(queryOperation)
    }

    @discardableResult func getShaders(_ predicate: NSPredicate,_ cb: @escaping (LibraryShaderList)->(),_ mergeList: LibraryShaderList? = nil) -> LibraryShaderList
    {
        let list = mergeList == nil ? LibraryShaderList() : mergeList!
        let publicQuery = CKQuery(recordType: "Shaders", predicate: predicate)
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        publicQuery.sortDescriptors = [sort]
        publicDatabase.perform(publicQuery, inZoneWith: nil) { (records, error) in
            
            records?.forEach({ (record) in
                
                let shader = LibraryShader()
                shader.name = record.recordID.recordName
                                                
                if let description = record.value(forKey: "description") as? String {
                    shader.description = description
                }

                self.container.publicCloudDatabase.fetch(withRecordID: record.creatorUserRecordID!) { record, error in
                    guard let record = record, error == nil else {
                        return
                    }
                    
                    shader.userRecord = record
                }
                
                if let json = record.value(forKey: "json") as? String {
                    if let jsonData = json.data(using: .utf8) {
                        
                        if let folder = try? JSONDecoder().decode(AssetFolder.self, from: jsonData) {
                            
                            shader.folder = folder
                            
                            var current : Asset? = nil
                            if folder.current != nil {
                                current = folder.current!
                            } else {
                                current = folder.assets[0]
                            }
                                
                            if let current = current {
                                self.project.compileAssets(assetFolder: folder, forAsset: current, compiler: self.core.shaderCompiler, finished: { () in
                                    if let texture = self.project.render(assetFolder: folder, device: self.core.device, time: 0, frame: 0, viewSize: SIMD2<Int>(120, 80), forAsset: current) {
                                        
                                        self.project.stopDrawing(syncTexture: texture, waitUntilCompleted: true)
                                        
                                        if let cgiTexture = self.project.makeCGIImage(self.core.device, self.core.metalStates.getComputeState(state: .MakeCGIImage), texture) {
                                            if let image = makeCGIImage(texture: cgiTexture, forImage: true) {
                                                list.shaders.append(shader)
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
            })
            
            cb(list)
        }
        
        return list
    }
    
    /// Adds the library to the curent project
    func addShaderToProject(_ shader: LibraryShader)
    {
        if let folder = shader.folder {
            for asset in folder.assets {
                if asset.type == .Shader || asset.type == .Image {
                    core.assetFolder.assets.append(asset)
                }
            }
        }
        core.nodesWidget.update()
        core.contentChanged.send()
    }
}
