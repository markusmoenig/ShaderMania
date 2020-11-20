//
//  ShaderManiaApp.swift
//  Shared
//
//  Created by Markus Moenig on 19/11/20.
//

import SwiftUI
import Combine

@main
struct ShaderManiaApp: App {
    
    private let exportAsImage               = PassthroughSubject<Void, Never>()
    //@State private var exportingImage       : Bool = false

    var body: some Scene {
        DocumentGroup(newDocument: ShaderManiaDocument()) { file in
            ContentView(document: file.$document)
                .onReceive(exportAsImage) { _ in
                    file.document.exportImage.send()
                }
        }
        .commands {
            
            SidebarCommands()
            
            CommandGroup(replacing: .help) {
                Button(action: {
                    print("Help")
                }) {
                    Text("Help")
                }
            }
            
            CommandGroup(replacing: .importExport) {
                Button(action: {
                    exportAsImage.send()
                }) {
                    Text("Export as Image...")
                }
            }
        }
    }
}
