//
//  ShaderManiaApp.swift
//  Shared
//
//  Created by Markus Moenig on 19/11/20.
//

import SwiftUI
import Combine

#if os(iOS)
import MobileCoreServices
#endif

@main
struct ShaderManiaApp: App {
    
    private let exportAsImage               = PassthroughSubject<Void, Never>()
    @State private var exportingImage       : Bool = false

    var body: some Scene {
        DocumentGroup(newDocument: ShaderManiaDocument()) { file in
            ContentView(document: file.$document)
                .onReceive(exportAsImage) { _ in
                    exportingImage = true
                }
                // Import Image
                .fileExporter(
                    isPresented: $exportingImage,
                    document: file.document,
                    contentType: .image,
                    defaultFilename: "Image"
                ) { result in
                    do {
                        let url = try result.get()
                        let game = file.document.game
                        if let project = game.project {
                            if let texture = project.render(assetFolder: game.assetFolder, device: game.device, time: 0, viewSize: SIMD2<Int>(Int(game.view.frame.width), Int(game.view.frame.height))) {
                                
                                project.stopDrawing(syncTexture: texture, waitUntilCompleted: true)
                                
                                if let cgiTexture = project.makeCGIImage(game.device, game.metalStates.getComputeState(state: .MakeCGIImage), texture) {
                                    if let image = makeCGIImage(texture: cgiTexture, forImage: true) {
                                        if let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) {
                                            CGImageDestinationAddImage(imageDestination, image, nil)
                                            CGImageDestinationFinalize(imageDestination)
                                        }
                                    }
                                }
                            }
                        }
                    } catch {
                        // Handle failure.
                    }
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
