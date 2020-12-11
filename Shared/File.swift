//
//  File.swift
//  ShaderMania
//
//  Created by Markus Moenig on 2/12/20.
//

import Foundation

class File : NSObject
{
    var containerUrl: URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: /*"<G6R6L3VH62>.<iCloud.com.moenig.Denrim>"*/ nil)?.appendingPathComponent("Documents")
    }
    
    override init()
    {
        super.init()
        
        // --- Check for iCloud container existence
        if let url = self.containerUrl, !FileManager.default.fileExists(atPath: url.path, isDirectory: nil) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
        checkIfExamplesExist()
    }
    
    func checkIfExamplesExist()
    {
        let url = containerUrl?.appendingPathComponent("Examples")
        var isDir : ObjCBool = false
        if let url = url {
            if FileManager.default.fileExists(atPath: url.path, isDirectory:&isDir) == false {
                print("Examples do not exist")
                
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                    
                    print("created examples folder")
                }
                catch {
                    print(error.localizedDescription)
                }
            }
            
            copyTemplateToExamples("FractalLand", url)
            
            /*
            do {
                let mapHelpIndex = try FileManager.default.contentsOfDirectory(atPath: containerUrl!.path)
                print(mapHelpIndex)
            } catch {
            }*/
        }
    }
    
    func copyTemplateToExamples(_ name: String,_ url: URL)
    {
        guard let path = Bundle.main.path(forResource: name, ofType: "shadermania", inDirectory: "Files/Templates") else {
            return
        }
                
        do {
            if let templateData = NSData(contentsOfFile: path) {
                let fileURL = url.appendingPathComponent(name + ".shadermania")
                try templateData.write(to: fileURL)
            }
        } catch {
        }
    }
}
