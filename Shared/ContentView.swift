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
    
    @Environment(\.managedObjectContext) var managedObjectContext

    enum EditingState {
        case Source, Nodes, Both
    }
    
    @State var editingState                 : EditingState = .Both
    @State var editingStateText             : String = "Source & Nodes"

    @Binding var document                   : ShaderManiaDocument
    @StateObject var storeManager           : StoreManager

    @State private var showSharePopover     : Bool = false
    @State private var libraryName          : String = ""
    @State private var libraryTags          : String = ""
    @State private var libraryDescription   : String = ""
    @State private var userNickName         : String = ""
    @State private var userDescription      : String = ""

    @State private var showLibrary          : Bool = true

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
        
        //HStack() {
            NavigationView() {

                ParameterListView(document: document, updateView: $updateView)
                    .frame(minWidth: leftPanelWidth, idealWidth: leftPanelWidth, maxWidth: leftPanelWidth)
                
                VSplitView {
                    
                    MetalManiaView(document.core)

                    HSplitView {
                        

                        WebView(document.core, deviceColorScheme).tabItem {
                        }
                            .animation(.default)
                            .onChange(of: deviceColorScheme) { newValue in
                                document.core.scriptEditor?.setTheme(newValue)
                            }
                        
                        BrowserView(document: $document)
                        
                        //VSplitView {
                            
                            //MetalView(document.core, .Main)
                                /*
                                .frame(minWidth: 0,
                                       maxWidth: geometry.size.width / document.core.previewFactor,
                                       minHeight: 0,
                                       maxHeight: geometry.size.height / document.core.previewFactor,
                                       alignment: .topTrailing)
                                 
                                .opacity(helpIsVisible ? 0 : (document.core.state == .Running ? 1 : document.core.previewOpacity))
                                 */
                                //.animation(.default)
                                //.allowsHitTesting(false)
                            
                            /*
                            MetalView(document.core, .Nodes)
                                //.animation(.default)
                                .allowsHitTesting(true)
                                //.frame(maxHeight: editingState == .Both ? geometry.size.height / 2.5 : geometry.size.height)
                             */
                        //}
                    }
                    
                    /*
                    ZStack(alignment: .topTrailing) {

                        VStack(spacing: 2) {
                            
                            if editingState == .Source || editingState == .Both {
                                GeometryReader { geometry in
                                    ScrollView {

                                        if document.core.assetFolder.assets.isEmpty == false {
                                            WebView(document.core, deviceColorScheme).tabItem {
                                            }
                                                .animation(.default)
                                            
                                                .frame(height: geometry.size.height)
                                                .tag(1)
                                                .onChange(of: deviceColorScheme) { newValue in
                                                    document.core.scriptEditor?.setTheme(newValue)
                                                }
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
                                    .frame(maxHeight: editingState == .Both ? geometry.size.height / 2.5 : geometry.size.height)
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
                     */
                    
                    //if showBrowser {
                        //BrowserView(document: $document)
                        //    .frame(maxHeight: 140)
                    //}
                }
            }
            
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    
                    toolNodeMenu
                    
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
                    }.keyboardShortcut(".")
                    .disabled(document.core.state == .Idle)
                    
                    //Divider()
                        //.padding(.horizontal, 2)
                        //.opacity(0)

                    toolShareMenu
                    toolGiftMenu
                    
                    Button(action: {
                        document.help.send()
                    }) {
                        Label("Help", systemImage: "questionmark")
                    }
                    .keyboardShortcut("h")
                    
                    Button(action: {
                        showLibrary.toggle()
                    }) {
                        Label("Library", systemImage: "sidebar.right")
                    }
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
            if showLibrary == true {
                LibraryView(document: document, updateView: $updateView)
                    .frame(minWidth: 220, idealWidth: 220, maxWidth: 220)
                    .animation(.easeInOut)
            }*/
        //}
        // For Mac Screenshots, 1440x900
        //.frame(minWidth: 1440, minHeight: 806)
        //.frame(maxWidth: 1440, maxHeight: 806)
        // For Mac App Previews 1920x1080
        //.frame(minWidth: 1920, minHeight: 978)
        //.frame(maxWidth: 1920, maxHeight: 978)
    }
    
    // tool bar menus
    
    var toolShareMenu : some View {

        Button(action: {
            
            libraryName = document.core.assetFolder.libraryName
            libraryTags = document.core.assetFolder.libraryTags
            libraryDescription = document.core.assetFolder.libraryDescription
            
            userNickName = document.core.library.userNickName
            userDescription = document.core.library.userDescription
            
            showSharePopover = true
        }) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        // Edit Node name
        .popover(isPresented: self.$showSharePopover,
                 arrowEdge: .top
        ) {
            VStack(alignment: .leading) {
                Text("Shader Library Name")
                    .foregroundColor(Color.secondary)
                TextField("Name", text: $libraryName, onEditingChanged: { (changed) in
                    document.core.assetFolder.libraryName = libraryName
                    updateView.toggle()
                })
                .frame(minWidth: 300)
                
                Text("Shader Description")
                    .foregroundColor(Color.secondary)
                    .padding(.top, 5)
                TextEditor(text: $libraryDescription)
                .onChange(of: libraryDescription) { value in
                    document.core.assetFolder.libraryDescription = libraryDescription
                 }
                .frame(minWidth: 300, minHeight: 60)

                Divider()
                
                /*
                Text("Your User Nickname - Required")
                    .foregroundColor(Color.secondary)
                TextField("Required", text: $userNickName, onEditingChanged: { (changed) in
                    document.core.library.userNickName = userNickName
                    updateView.toggle()
                })
                .frame(minWidth: 300)
                
                Text("About You - Optional")
                    .foregroundColor(Color.secondary)
                    .padding(.top, 5)
                TextEditor(text: $userDescription)
                .onChange(of: userDescription) { value in
                    document.core.library.userDescription = userDescription
                 }
                .frame(minWidth: 300, minHeight: 60)
                 */
                
                Button("Upload", action: {
                    document.core.library.uploadFolder()
                })
                .disabled(document.core.assetFolder.libraryName.count == 0 || document.core.library.userNickName.count == 0)
                .padding(.top, 10)

            }.padding()
        }
    }
    
    var toolNodeMenu : some View {
        Menu {
            Section(header: Text("Add Node")) {
                Button("Add Image", action: {
                    importingImage = true
                })
                .keyboardShortcut("1")
                Button("Add Shader", action: {
                    if let asset = document.core.assetFolder.addShader("New Shader") {
                        /*
                        document.core.nodesWidget.selectNode(asset)
                        document.core.nodesWidget.compileAndUpdatePreview(asset)
                        document.core.nodesWidget.update()
                         */
                        document.core.contentChanged.send()
                        updateView.toggle()
                    }
                })
                .keyboardShortcut("2")
            }
            Section(header: Text("Edit Node")) {
                Button("Rename", action: {
                    /*
                    if let node = document.core.nodesWidget.currentNode {
                        assetName = node.name
                        showAssetNamePopover = true
                        document.core.contentChanged.send()
                    }*/
                })
                Button("Delete", action: {
                    /*
                    if document.core.nodesWidget.currentNode != nil {
                        showDeleteAssetAlert = true
                        document.core.nodesWidget.update()
                        document.core.contentChanged.send()
                    }*/
                })
            }
            Section(header: Text("Show")) {
                Button("Source Only", action: {
                    editingState = .Source
                    editingStateText = "Source Only"
                })
                .keyboardShortcut("3")
                Button("Nodes Only", action: {
                    editingState = .Nodes
                    editingStateText = "Nodes Only"
                })
                .keyboardShortcut("4")
                Button("Source & Nodes", action: {
                    editingState = .Both
                    editingStateText = "Source & Nodes"
                })
                .keyboardShortcut("5")
            }
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
                    /*
                    if let node = document.core.nodesWidget.currentNode {
                        node.name = assetName
                        updateView.toggle()
                        document.core.nodesWidget.update()
                    }*/
                })
                .frame(minWidth: 200)
            }.padding()
        }
        // Delete an asset
        .alert(isPresented: $showDeleteAssetAlert) {
            Alert(
                title: Text("Do you want to remove the node '\(/*document.core.nodesWidget.currentNode!.name*/"")' ?"),
                message: Text("This action cannot be undone!"),
                primaryButton: .destructive(Text("Yes"), action: {
                    /*
                    if let asset = document.core.nodesWidget.currentNode {
                        document.core.nodesWidget.nodeIsAboutToBeDeleted(asset)
                        document.core.assetFolder.removeAsset(asset)
                        for a in document.core.assetFolder.assets {
                            document.core.nodesWidget.selectNode(a)
                            break
                        }
                        self.updateView.toggle()
                        document.core.nodesWidget.update()
                    }*/
                }),
                secondaryButton: .cancel(Text("No"), action: {})
            )
        }
        // Import Image
        .fileImporter(
            isPresented: $importingImage,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            do {
                let selectedFiles = try result.get()
                
                document.core.assetFolder.addImages("New", [selectedFiles[0]])
                if selectedFiles.count > 0 {
                    if let asset = document.core.assetFolder.current {
                        asset.name = selectedFiles[0].deletingPathExtension().lastPathComponent
                        /*
                        document.core.nodesWidget.selectNode(asset)
                        document.core.nodesWidget.update()*/
                        document.core.contentChanged.send()
                        updateView.toggle()
                    }
                }
            } catch {
                // Handle failure.
            }
        }
        
        // Init StoreManager
        .onAppear(perform: {
            if storeManager.myProducts.isEmpty {
                DispatchQueue.main.async {
                    storeManager.getProducts()
                }
            }
        })
    }
    
    var toolGiftMenu : some View {
        Menu {
            HStack {
                VStack(alignment: .leading) {
                    Text("Small Tip")
                        .font(.headline)
                    Text("Tip of $2 for the author")
                        .font(.caption2)
                }
                Button(action: {
                    storeManager.purchaseId("com.moenig.ShaderMania.IAP.Tip2")
                }) {
                    Text("Buy for $2")
                }
                .foregroundColor(.blue)
                Divider()
                VStack(alignment: .leading) {
                    Text("Medium Tip")
                        .font(.headline)
                    Text("Tip of $5 for the author")
                        .font(.caption2)
                }
                Button(action: {
                    storeManager.purchaseId("com.moenig.ShaderMania.IAP.Tip5")
                }) {
                    Text("Buy for $5")
                }
                .foregroundColor(.blue)
                Divider()
                VStack(alignment: .leading) {
                    Text("Large Tip")
                        .font(.headline)
                    Text("Tip of $10 for the author")
                        .font(.caption2)
                }
                Button(action: {
                    storeManager.purchaseId("com.moenig.ShaderMania.IAP.Tip10")
                }) {
                    Text("Buy for $10")
                }
                .foregroundColor(.blue)
                Divider()
                Text("You are awesome! ❤️❤️")
            }
        }
        label: {
            Label("Dollar", systemImage: "gift")//dollarsign.circle")
        }
    }
    
    var toolPreviewMenu : some View {
        Menu {
            Section(header: Text("Preview")) {
                Button("Small", action: {
                    document.core.previewFactor = 4
                    updateView.toggle()
                })
                .keyboardShortcut("6")
                Button("Medium", action: {
                    document.core.previewFactor = 2
                    updateView.toggle()
                })
                .keyboardShortcut("7")
                Button("Large", action: {
                    document.core.previewFactor = 1
                    updateView.toggle()
                })
                .keyboardShortcut("8")
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
                Button("Opacity Half", action: {
                    document.core.previewOpacity = 0.5
                    updateView.toggle()
                })
                Button("Opacity Full", action: {
                    document.core.previewOpacity = 1.0
                    updateView.toggle()
                })
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
                    /*
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
                    }*/
                }
            } catch {
                // Handle failure.
            }
        }
        // Custom Resolution Popover
        .popover(isPresented: self.$showCustomResPopover,
                 arrowEdge: .top
        ) {
            VStack(alignment: .leading) {
                Text("Resolution:")
                TextField("Width", text: $customResWidth, onEditingChanged: { (changed) in
                    if let width = Int(customResWidth), width > 0 {
                        if let height = Int(customResHeight), height > 0 {
                            document.core.assetFolder.customSize = SIMD2<Int>(width, height)
                            if let asset = document.core.assetFolder.current {
                                document.core.createPreview(asset)
                            }
                        }
                    }
                })
                TextField("Height", text: $customResHeight, onEditingChanged: { (changed) in
                    if let width = Int(customResWidth), width > 0 {
                        if let height = Int(customResHeight), height > 0 {
                            document.core.assetFolder.customSize = SIMD2<Int>(width, height)
                            if let asset = document.core.assetFolder.current {
                                document.core.createPreview(asset)
                            }
                        }
                    }
                })
                .frame(minWidth: 200)
            }.padding()
        }
    }
}
