//
//  ContentView.swift
//  ShaderMania
//
//  Created by Markus Moenig on 18/11/20.
//

import SwiftUI

#if os(iOS)
import MobileCoreServices
#endif

struct ContentView: View {
    
    enum EditingState {
        case Source, Nodes, Both
    }
    
    @State var editingState                 : EditingState = .Both

    @Binding var document                   : ShaderManiaDocument

    @State private var showAssetNamePopover : Bool = false
    @State private var assetName            : String = ""

    @State private var showDeleteAssetAlert : Bool = false

    @State private var showCustomResPopover : Bool = false
    @State private var customResWidth       : String = ""
    @State private var customResHeight      : String = ""

    @State private var rightSideBarIsVisible: Bool = true
    
    @State private var updateView           : Bool = false

    @State private var helpIsVisible        : Bool = false
    
    @State private var importingImage       : Bool = false
    @State private var exportingImage       : Bool = false


    @Environment(\.colorScheme) var deviceColorScheme: ColorScheme

    var body: some View {
        
        NavigationView() {

            ParameterView(document: document)

            /*
            LeftPanelView(document: document, updateView: $updateView, showAssetNamePopover: $showAssetNamePopover, assetName: $assetName, showDeleteAssetAlert: $showDeleteAssetAlert)
            .frame(minWidth: 160, idealWidth: 200, maxWidth: 200)
            .layoutPriority(0)
            */
            
            GeometryReader { geometry in
                ZStack(alignment: .topTrailing) {

                    VStack {
                        
                        if editingState == .Source || editingState == .Both {
                            GeometryReader { geometry in
                                ScrollView {

                                    WebView(document.core, deviceColorScheme).tabItem {
                                    }
                                        .animation(.default)
                                        .frame(height: geometry.size.height)
                                        .tag(1)
                                        .onChange(of: deviceColorScheme) { newValue in
                                            document.core.scriptEditor?.setTheme(newValue)
                                        }
                                }
                                .zIndex(0)
                                .frame(maxWidth: .infinity)
                                .layoutPriority(2)
                                .animation(.default)

                                .onReceive(self.document.core.contentChanged) { state in
                                    document.updated.toggle()
                                }
                            }
                        }
                        
                        MiddleToolbarView(document: document, editingState: $editingState)
                        
                        if editingState == .Nodes || editingState == .Both {
                            MetalView(document.core, .Nodes)
                                .zIndex(0)
                                .animation(.default)
                                .allowsHitTesting(true)
                        }                        
                    }
                    
                    MetalView(document.core, .Main)
                        .zIndex(2)
                        .frame(minWidth: 0,
                               maxWidth: geometry.size.width / document.core.previewFactor,
                               minHeight: 0,
                               maxHeight: geometry.size.height / document.core.previewFactor,
                               alignment: .topTrailing)
                        .opacity(helpIsVisible ? 0 : (document.core.state == .Running ? 1 : document.core.previewOpacity))
                        .animation(.default)
                        .allowsHitTesting(false)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                
                Menu {
                    Section(header: Text("Preview")) {
                        Button("Small", action: {
                            document.core.previewFactor = 4
                            updateView.toggle()
                        })
                        .keyboardShortcut("1")
                        Button("Medium", action: {
                            document.core.previewFactor = 2
                            updateView.toggle()
                        })
                        .keyboardShortcut("2")
                        Button("Large", action: {
                            document.core.previewFactor = 1
                            updateView.toggle()
                        })
                        .keyboardShortcut("3")
                        Button("Set Custom", action: {
                            
                            if let project = document.core.project {
                                customResWidth = String(project.size.x)
                                customResHeight = String(project.size.y)
                            }
                            
                            showCustomResPopover = true
                            updateView.toggle()
                        })
                        
                        Button("Clear Custom", action: {
                            
                            if let final = document.core.assetFolder.getAsset("Final", .Shader) {
                                final.size = nil
                                if let asset = document.core.assetFolder.current {
                                    document.core.createPreview(asset)
                                }
                            }
                            updateView.toggle()
                        })
                    }
                    Section(header: Text("Opacity")) {
                        Button("Opacity Off", action: {
                            document.core.previewOpacity = 0
                            updateView.toggle()
                        })
                        .keyboardShortcut("4")
                        Button("Opacity Half", action: {
                            document.core.previewOpacity = 0.5
                            updateView.toggle()
                        })
                        .keyboardShortcut("5")
                        Button("Opacity Full", action: {
                            document.core.previewOpacity = 1.0
                            updateView.toggle()
                        })
                        .keyboardShortcut("6")
                    }
                    Section(header: Text("Export")) {
                        Button("Export Image...", action: {
                            exportingImage = true
                        })
                    }
                }
                label: {
                    Text("\(document.core.project!.size.x) x \(document.core.project!.size.y)")
                    //Label("View", systemImage: "viewfinder")
                }
                
                Divider()
                    .padding(.horizontal, 20)
                    .opacity(0)
                
                // Core Controls
                Button(action: {
                    document.core.stop()
                    document.core.start()
                    helpIsVisible = false
                    updateView.toggle()
                })
                {
                    Label("Run", systemImage: "play.fill")
                }
                .keyboardShortcut("r")
                
                Button(action: {
                    document.core.stop()
                    if let asset = document.core.assetFolder.current {
                        document.core.createPreview(asset)
                    }
                    updateView.toggle()
                }) {
                    Label("Stop", systemImage: "stop.fill")
                }.keyboardShortcut("t")
                .disabled(document.core.state == .Idle)
                
                Divider()
                    .padding(.horizontal, 20)
                    .opacity(0)

                Button(action: {
                    document.help.send()
                }) {
                    Label("Help", systemImage: "questionmark")
                }
                .keyboardShortcut("h")
                
                Button(action: { rightSideBarIsVisible.toggle() }, label: {
                    Image(systemName: "sidebar.right")
                })
            }
        }
        //.onReceive(self.document.core.timeChanged) { value in
        //    timeString = String(format: "%.02f", value)
        //}
        
        .onReceive(self.document.core.createPreview) { value in
            if let asset = document.core.assetFolder.current {
                document.core.createPreview(asset)
            }
        }
        
        .onReceive(self.document.help) { value in
            if self.helpIsVisible == false {
                self.document.core.scriptEditor!.activateHelpSession()
            } else {
                if let asset = document.core.assetFolder.current {
                    self.document.core.assetFolder.select(asset.id)
                }
            }
            self.helpIsVisible.toggle()
        }
        
        .onReceive(self.document.exportImage) { value in
            exportingImage = true
        }
        
        .onReceive(self.document.core.updateUI) { value in
            updateView.toggle()
        }
    
        /*
        if rightSideBarIsVisible == true {
            if helpIsVisible == true {
                /*
                HelpIndexView(document.core)
                    .frame(minWidth: 160, idealWidth: 160, maxWidth: 160)
                    .layoutPriority(0)
                    .animation(.easeInOut)
                */
            } else {
                VStack {
                    if let asset = document.core.assetFolder.current {
                        if asset.type == .Texture {
                            Button("Attach Image", action: {
                                importingImage = true
                            })
                            .padding(4)
                            .padding(.top, 10)
                        }
                        if asset.type == .Shader || asset.type == .Buffer {
                            BufferInputsView(document: document, updateView: $updateView)

                            if asset.type == .Buffer {
                                BufferOutputView(document: document, updateView: $updateView)
                            }
                        }
                    }
                    Spacer()
                }
                .frame(minWidth: 160, idealWidth: 160, maxWidth: 160)
                .layoutPriority(0)
                .animation(.easeInOut)
                
                // Custom Resolution Popover
                .popover(isPresented: self.$showCustomResPopover,
                         arrowEdge: .top
                ) {
                    VStack(alignment: .leading) {
                        Text("Resolution:")
                        TextField("Width", text: $customResWidth, onEditingChanged: { (changed) in
                            if let width = Int(customResWidth), width > 0 {
                                if let height = Int(customResHeight), height > 0 {
                                    if let final = document.core.assetFolder.getAsset("Final", .Shader) {
                                        final.size = SIMD2<Int>(width, height)
                                        if let asset = document.core.assetFolder.current {
                                            document.core.createPreview(asset)
                                        }
                                    }
                                }
                            }
                        })
                        TextField("Height", text: $customResHeight, onEditingChanged: { (changed) in
                            if let width = Int(customResWidth), width > 0 {
                                if let height = Int(customResHeight), height > 0 {
                                    if let final = document.core.assetFolder.getAsset("Final", .Shader) {
                                        final.size = SIMD2<Int>(width, height)
                                        if let asset = document.core.assetFolder.current {
                                            document.core.createPreview(asset)
                                        }
                                    }
                                }
                            }
                        })
                        .frame(minWidth: 200)
                    }.padding()
                }
                
                // Import Image
                .fileImporter(
                    isPresented: $importingImage,
                    allowedContentTypes: [.item],
                    allowsMultipleSelection: false
                ) { result in
                    do {
                        let selectedFiles = try result.get()
                        if selectedFiles.count > 0 {
                            if let asset = document.core.assetFolder.current {
                                document.core.assetFolder.attachImage(asset, selectedFiles[0])
                                asset.name = selectedFiles[0].deletingPathExtension().lastPathComponent
                                document.core.assetFolder.current = nil
                                document.core.assetFolder.select(asset.id)
                                updateView.toggle()
                                document.core.createPreview(asset)
                            }
                        }
                    } catch {
                        // Handle failure.
                    }
                }
                
                // Export Image
                .fileExporter(
                    isPresented: $exportingImage,
                    document: document,
                    contentType: .png,
                    defaultFilename: "Image"
                ) { result in
                    do {
                        let url = try result.get()
                        let core = document.core
                        if let project = core.project {
                            if let texture = project.render(assetFolder: core.assetFolder, device: core.device, time: 0, frame: 0, viewSize: SIMD2<Int>(Int(core.view.frame.width), Int(core.view.frame.height))) {
                                
                                project.stopDrawing(syncTexture: texture, waitUntilCompleted: true)
                                
                                if let cgiTexture = project.makeCGIImage(core.device, core.metalStates.getComputeState(state: .MakeCGIImage), texture) {
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
                
                // Delete an asset
                .alert(isPresented: $showDeleteAssetAlert) {
                    Alert(
                        title: Text("Do you want to remove the asset '\(document.core.assetFolder.current!.name)' ?"),
                        message: Text("This action cannot be undone!"),
                        primaryButton: .destructive(Text("Yes"), action: {
                            if let asset = document.core.assetFolder.current {
                                document.core.assetFolder.removeAsset(asset)
                                for a in document.core.assetFolder.assets {
                                    document.core.assetFolder.select(a.id)
                                    break
                                }
                                self.updateView.toggle()
                            }
                        }),
                        secondaryButton: .cancel(Text("No"), action: {})
                    )
                }
            }
        }
        */
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(ShaderManiaDocument()))
    }
}
