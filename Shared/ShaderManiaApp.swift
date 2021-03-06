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
    
    @StateObject var storeManager           = StoreManager()

    private let exportAsImage               = PassthroughSubject<Void, Never>()
    private let help                        = PassthroughSubject<Void, Never>()

    var body: some Scene {
        DocumentGroup(newDocument: ShaderManiaDocument()) { file in
            ContentView(document: file.$document, storeManager: storeManager)
                .onReceive(exportAsImage) { _ in
                    file.document.exportImage.send()
                }
                .onReceive(help) { _ in
                    file.document.help.send()
                }
        }
        .commands {
            
            SidebarCommands()
            
            CommandGroup(replacing: .help) {
                Button(action: {
                    help.send()
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
