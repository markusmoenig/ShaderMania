//
//  Library.swift
//  ShaderMania
//
//  Created by Markus Moenig on 17/2/21.
//

import Foundation
import CloudKit

class Library
{
    let core                : Core
    
    let container       : CKContainer
    
    let privateDatabase : CKDatabase
    let publicDatabase  : CKDatabase
    
    var userId          : CKRecord.ID? = nil
    var userNickName    : String = ""
    
    init(_ core: Core)
    {
        self.core = core
        
        container = CKContainer.init(identifier: "iCloud.com.moenig.ShaderMania")
        
        privateDatabase = container.privateCloudDatabase
        publicDatabase = container.publicCloudDatabase
        
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
                }
            }
        }
    }
    
    func uploadFolder()
    {
        updateUserNick()
        let encodedData = try? JSONEncoder().encode(core.assetFolder)
        if let encodedFolder = String(data: encodedData!, encoding: .utf8)
        {
            let folder = core.assetFolder!
            
            let recordID  = CKRecord.ID(recordName: folder.libraryName)
            let record    = CKRecord(recordType: "Shaders", recordID: recordID)

            record["json"] = encodedFolder

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
    
    func updateUserNick()
    {
        if let recordID = userId {
            container.publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
                guard let record = record, error == nil else {
                    return
                }
                
                var needsUpdate = true
                if let existing = record["nickName"] as? String {
                    if existing == self.userNickName {
                        needsUpdate = false
                    }
                }
                
                if needsUpdate == true {
                    record["nickName"] = self.userNickName
                    
                    self.container.publicCloudDatabase.save(record) { _, error in
                        guard error == nil else {
                            return
                        }

                        print("Successfully updated user nick")
                    }
                }
            }
        }
    }
}
