//
//  MMFile.swift
//  Shape-Z
//
//  Created by Markus Moenig on 18/2/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation

#if os(OSX)
import AppKit
#else
import UIKit
#endif

class MMFile
{
    var mmView      : MMView!

    var name        : String = "Untitled"
    
    var containerUrl: URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    init(_ view: MMView)
    {
        mmView = view
        
        // --- Check for iCloud container existence
        if let url = self.containerUrl, !FileManager.default.fileExists(atPath: url.path, isDirectory: nil) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    /// Returns the file url
    func url() -> URL?
    {
        let documentUrl = self.containerUrl?
                    .appendingPathComponent(name)
                    .appendingPathExtension("shape-z")
        return documentUrl
    }
    
    /// Saves the file to iCloud
    func save(_ stringData: String)
    {
        do {
            /*
            try FileManager.default.createDirectory(at: (self.containerUrl?
                .appendingPathComponent("Temp"))!,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            
            print( url()! )
            */
            try stringData.write(to: url()!, atomically: true, encoding: .utf8)
        } catch
        {
            print(error.localizedDescription)
        }
    }
    
    /*
    func saveAs(_ stringData: String, _ app: App)
    {
        #if os(OSX)

        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = false
        savePanel.title = "Select Project"
        savePanel.directoryURL =  containerUrl
        savePanel.showsHiddenFiles = false
        savePanel.allowedFileTypes = ["shape-z"]
        
        func save(url: URL)
        {
            do {
                try stringData.write(to: url, atomically: true, encoding: .utf8)
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
        savePanel.beginSheetModal(for: self.mmView.window!) { (result) in
            if result == .OK {
                save(url: savePanel.url!)
                self.mmView.undoManager!.removeAllActions()
            }
        }
        
        #elseif os(iOS)
        
        app.viewController?.exportFile(stringData)

        /*
        do {
            try stringData.write(to: url()!, atomically: true, encoding: .utf8)
            self.mmView.undoManager!.removeAllActions()
        } catch
        {
            print(error.localizedDescription)
        }*/
        
        #endif
    }*/
    
    func loadJSON(url: URL) -> String
    {
        var string : String = ""
        
        do {
            string = try String(contentsOf: url, encoding: .utf8)
        }
        catch {
            print(error.localizedDescription)
        }
        
        return string
    }

    /*
    ///
    func chooseFile(app: App)
    {
        #if os(OSX)

        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.title = "Select Project"
        openPanel.directoryURL =  containerUrl
        openPanel.showsHiddenFiles = false
        openPanel.allowedFileTypes = ["shape-z"]
        
        func load(url: URL) -> String
        {
            var string : String = ""
            
            do {
                string = try String(contentsOf: url, encoding: .utf8)
            }
            catch {
                print(error.localizedDescription)
            }
            
            return string
        }
        
        openPanel.beginSheetModal(for:self.mmView.window!) { (response) in
            if response == NSApplication.ModalResponse.OK {
                let string = load(url: openPanel.url!)
                app.loadFrom(string)
                
                self.name = openPanel.url!.deletingPathExtension().lastPathComponent
                
                app.mmView.window!.title = self.name
                app.mmView.window!.representedURL = self.url()
                
                app.mmView.undoManager!.removeAllActions()
            }
            openPanel.close()
        }
        
        #elseif os(iOS)
        
        app.viewController?.importFile()
        
        #endif
    }*/
}
