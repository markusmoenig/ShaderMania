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
    @State var editingStateText             : String = " Source & Nodes"

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

    #if os(macOS)
    let leftPanelWidth                      : CGFloat = 200
    #else
    let leftPanelWidth                      : CGFloat = 250
    #endif
    
    var body: some View {
        
        NavigationView() {

            ParameterListView(document: document, updateView: $updateView)
                .frame(minWidth: leftPanelWidth, idealWidth: leftPanelWidth, maxWidth: leftPanelWidth)

            /*
            LeftPanelView(document: document, updateView: $updateView, showAssetNamePopover: $showAssetNamePopover, assetName: $assetName, showDeleteAssetAlert: $showDeleteAssetAlert)
            .frame(minWidth: 160, idealWidth: 200, maxWidth: 200)
            .layoutPriority(0)
            */
            
            GeometryReader { geometry in
                ZStack(alignment: .topTrailing) {

                    VStack(spacing: 2) {
                        
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
                                                
                        if editingState == .Nodes || editingState == .Both {
                            MetalView(document.core, .Nodes)
                                .zIndex(0)
                                .animation(.default)
                                .allowsHitTesting(true)
                                //.frame(maxHeight: geometry.size.height / 2.3)
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
                
                toolAddMenu

                Divider()
                    .padding(.horizontal, 2)
                    .opacity(0)
                
                toolEditMenu
                
                Divider()
                    .padding(.horizontal, 2)
                    .opacity(0)
                
                toolPreviewMenu
                
                Divider()
                    .padding(.horizontal, 2)
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
                    .padding(.horizontal, 2)
                    .opacity(0)

                Button(action: {
                    document.help.send()
                }) {
                    Label("Help", systemImage: "questionmark")
                }
                .keyboardShortcut("h")
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
    
    // tool bar menus
    
    var toolAddMenu : some View {
        Menu {
            Button("Add Image", action: {
                editingState = .Nodes
                editingStateText = "Nodes Only"
            })
            .keyboardShortcut("1")
            Button("Add Shader", action: {
                document.core.assetFolder.addShader("New Shader")
                //assetName = "New Shader"
                //showAssetNamePopover = true
                document.core.nodesWidget.drawables.update()
            })
            .keyboardShortcut("2")
            Divider()
            Button("Rename", action: {
                if let node = document.core.nodesWidget.currentNode {
                    assetName = node.name
                    showAssetNamePopover = true
                }
            })
            Button("Delete", action: {
                if document.core.nodesWidget.currentNode != nil {
                    showDeleteAssetAlert = true
                    document.core.nodesWidget.drawables.update()
                }
            })
        }
        label: {
            Text("Nodes")
        }
        // Edit Node name
        .popover(isPresented: self.$showAssetNamePopover,
                 arrowEdge: .top
        ) {
            VStack(alignment: .leading) {
                Text("Name:")
                TextField("Name", text: $assetName, onEditingChanged: { (changed) in
                    if let node = document.core.nodesWidget.currentNode {
                        node.name = assetName
                        updateView.toggle()
                        document.core.nodesWidget.update()
                    }
                })
                .frame(minWidth: 200)
            }.padding()
        }
        // Delete an asset
        .alert(isPresented: $showDeleteAssetAlert) {
            Alert(
                title: Text("Do you want to remove the node '\(document.core.nodesWidget.currentNode!.name)' ?"),
                message: Text("This action cannot be undone!"),
                primaryButton: .destructive(Text("Yes"), action: {
                    if let asset = document.core.nodesWidget.currentNode {
                        document.core.nodesWidget.nodeIsAboutToBeDeleted(asset)
                        document.core.assetFolder.removeAsset(asset)
                        for a in document.core.assetFolder.assets {
                            document.core.assetFolder.select(a.id)
                            break
                        }
                        self.updateView.toggle()
                        document.core.nodesWidget.update()
                    }
                }),
                secondaryButton: .cancel(Text("No"), action: {})
            )
        }
    }
    
    var toolEditMenu : some View {
        Menu {
            Button("Source", action: {
                editingState = .Source
                editingStateText = "Source Only"
            })
            .keyboardShortcut("1")
            Button("Nodes", action: {
                editingState = .Nodes
                editingStateText = "Nodes Only"
            })
            .keyboardShortcut("2")
            Button("Source & Nodes", action: {
                editingState = .Both
                editingStateText = "Source & Nodes"
            })
            .keyboardShortcut("3")
        }
        label: {
            Text(editingStateText)
        }
    }
    
    var toolPreviewMenu : some View {
        Menu {
            Section(header: Text("Preview")) {
                Button("Small", action: {
                    document.core.previewFactor = 4
                    updateView.toggle()
                })
                .keyboardShortcut("4")
                Button("Medium", action: {
                    document.core.previewFactor = 2
                    updateView.toggle()
                })
                .keyboardShortcut("5")
                Button("Large", action: {
                    document.core.previewFactor = 1
                    updateView.toggle()
                })
                .keyboardShortcut("6")
                Button("Set Custom", action: {
                    
                    if let project = document.core.project {
                        customResWidth = String(project.size.x)
                        customResHeight = String(project.size.y)
                    }
                    
                    showCustomResPopover = true
                    updateView.toggle()
                })
                
                Button("Clear Custom", action: {
                    
                    document.core.assetFolder.customSize = nil
                    if let asset = document.core.assetFolder.current {
                        document.core.createPreview(asset)
                    }
                    updateView.toggle()
                })
            }
            Section(header: Text("Opacity")) {
                Button("Opacity Off", action: {
                    document.core.previewOpacity = 0
                    updateView.toggle()
                })
                .keyboardShortcut("7")
                Button("Opacity Half", action: {
                    document.core.previewOpacity = 0.5
                    updateView.toggle()
                })
                .keyboardShortcut("8")
                Button("Opacity Full", action: {
                    document.core.previewOpacity = 1.0
                    updateView.toggle()
                })
                .keyboardShortcut("9")
            }
            Section(header: Text("Export")) {
                Button("Export Image...", action: {
                    exportingImage = true
                })
            }
        }
        label: {
            Label("View", systemImage: "viewfinder")
            Text("\(document.core.project!.size.x) x \(document.core.project!.size.y)")
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
                    if let asset = core.nodesWidget.currentNode {
                        if let texture = project.render(assetFolder: core.assetFolder, device: core.device, time: 0, frame: 0, viewSize: SIMD2<Int>(Int(core.view.frame.width), Int(core.view.frame.height)), forAsset: asset) {
                            
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
                }
            } catch {
                // Handle failure.
            }
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(ShaderManiaDocument()))
    }
}
