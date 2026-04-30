//
//  ContentView.swift
//  ShaderMania
//
//  Created by Markus Moenig on 18/11/20.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    
    enum EditingState: Equatable {
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

    @State private var showLibrary          : Bool = false

    @State private var showAssetNamePopover : Bool = false
    @State private var assetName            : String = ""

    @State private var showCustomResPopover : Bool = false
    @State private var customResWidth       : String = ""
    @State private var customResHeight      : String = ""

    @State private var rightSideBarIsVisible: Bool = true
    
    @State private var updateView           : Bool = false

    @State private var helpIsVisible        : Bool = false
    @State private var editorAnimationTick  : Bool = false
    
    @State private var importingImage       : Bool = false
    @State private var exportingImage       : Bool = false

    @Environment(\.colorScheme) var deviceColorScheme: ColorScheme
    @Environment(\.undoManager) private var undoManager

    #if os(macOS)
    let leftPanelWidth                      : CGFloat = 200
    let defaultWindowWidth                  : CGFloat = 1280
    let defaultWindowHeight                 : CGFloat = 800
    #else
    let leftPanelWidth                      : CGFloat = 250
    let defaultWindowWidth                  : CGFloat = 0
    let defaultWindowHeight                 : CGFloat = 0
    #endif

    private var editorBackgroundColor: Color {
        deviceColorScheme == .dark
        ? Color(red: 0.153, green: 0.157, blue: 0.137)
        : Color(red: 0.984, green: 0.984, blue: 0.984)
    }
    
    var body: some View {
        
        HStack() {
            NavigationView() {

                ParameterListView(document: document, updateView: $updateView)
                    .frame(minWidth: leftPanelWidth, idealWidth: leftPanelWidth, maxWidth: leftPanelWidth)
                
                GeometryReader { geometry in
                    ZStack(alignment: .topTrailing) {

                        VStack(spacing: 2) {
                            
                            if editingState == .Source || editingState == .Both {
                                GeometryReader { geometry in
                                    ScrollView {

                                        if document.core.assetFolder.assets.isEmpty == false {
                                            ZStack {
                                                editorBackgroundColor
                                                WebView(document.core, deviceColorScheme).tabItem {
                                                }
                                            }
                                                .frame(height: geometry.size.height)
                                                .tag(1)
                                                .background(editorBackgroundColor)
                                                .compositingGroup()
                                                .transition(.opacity)
                                                .animation(.default, value: editorAnimationTick)
                                                .animation(.default, value: editingState)
                                                .animation(.default, value: document.updated)
                                                .animation(.default, value: updateView)
                                                .animation(.default, value: deviceColorScheme)
                                                .onChange(of: deviceColorScheme) { _, newValue in
                                                    document.core.scriptEditor?.setTheme(newValue)
                                                }
                                        }
                                    }
                                    .zIndex(0)
                                    .frame(maxWidth: .infinity)
                                    .layoutPriority(2)
                                    .animation(.default, value: editingState)
                                    .animation(.default, value: document.updated)
                                    .animation(.default, value: updateView)
                                    .animation(.default, value: editorAnimationTick)
                                    .onAppear {
                                        withAnimation(.default) {
                                            editorAnimationTick.toggle()
                                        }
                                    }

                                    .onReceive(self.document.core.contentChanged) { state in
                                        withAnimation(.default) {
                                            document.updated.toggle()
                                            editorAnimationTick.toggle()
                                        }
                                    }
                                    .onReceive(self.document.core.selectionChanged) { _ in
                                        withAnimation(.default) {
                                            editorAnimationTick.toggle()
                                        }
                                    }
                                }
                            }
                                                    
                            if editingState == .Nodes || editingState == .Both {
                                MetalView(document.core, .Nodes)
                                    .zIndex(0)
                                    .animation(.default, value: editingState)
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
                            .animation(.default, value: helpIsVisible)
                            .animation(.default, value: document.core.state)
                            .animation(.default, value: document.core.previewOpacity)
                            .animation(.default, value: document.core.previewFactor)
                            .allowsHitTesting(false)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    
                    toolNodeMenu
                        .fixedSize()
                    
                    toolPreviewMenu
                    
                    // Core Controls
                    Button(action: {
                        document.core.stop()
                        document.core.start()
                        withAnimation(.default) {
                            helpIsVisible = false
                        }
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
                        withAnimation(.easeInOut) {
                            showLibrary.toggle()
                        }
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
                    self.document.core.scriptEditor?.activateHelpSession()
                } else {
                    if let asset = document.core.assetFolder.current {
                        self.document.core.assetFolder.select(asset.id)
                    }
                }
                withAnimation(.default) {
                    self.helpIsVisible.toggle()
                }
            }
            
            .onReceive(self.document.exportImage) { value in
                exportingImage = true
            }
            
            .onReceive(self.document.core.updateUI) { value in
                updateView.toggle()
            }
                
            if showLibrary == true {
                LibraryView(document: document, updateView: $updateView)
                    .frame(minWidth: 220, idealWidth: 220, maxWidth: 220)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(.easeInOut, value: showLibrary)
            }
        }
        .animation(.easeInOut, value: showLibrary)
        .onAppear {
            document.core.nodesWidget.undoManager = undoManager
        }
        #if os(macOS)
        .frame(minWidth: defaultWindowWidth, minHeight: defaultWindowHeight)
        #endif
    }
    
    // tool bar menus

    private func deleteCurrentNode()
    {
        guard let asset = document.core.nodesWidget.currentNode else {
            return
        }

        document.core.nodesWidget.deleteNodeWithUndo(asset, undoManager: undoManager)
        updateView.toggle()
    }

    private func addShaderNode()
    {
        if let asset = document.core.assetFolder.addShader("New Shader") {
            document.core.nodesWidget.selectNode(asset)
            document.core.nodesWidget.compileAndUpdatePreview(asset)
            document.core.nodesWidget.update()
            document.core.contentChanged.send()
            document.core.nodesWidget.registerAddedNodeUndo(asset, undoManager: undoManager, actionName: "Add Shader")
            updateView.toggle()
        }
    }

    private func addImageNode(from selectedFile: URL)
    {
        document.core.assetFolder.addImages("New", [selectedFile])
        if let asset = document.core.assetFolder.current {
            document.core.nodesWidget.setNodeName(asset, to: selectedFile.deletingPathExtension().lastPathComponent)
            document.core.nodesWidget.selectNode(asset)
            document.core.nodesWidget.update()
            document.core.contentChanged.send()
            document.core.nodesWidget.registerAddedNodeUndo(asset, undoManager: undoManager, actionName: "Add Image")
            updateView.toggle()
        }
    }

    private func setCustomResolutionFromFields()
    {
        guard let width = Int(customResWidth), width > 0,
              let height = Int(customResHeight), height > 0 else {
            return
        }

        document.core.nodesWidget.setCustomSize(SIMD2<Int>(width, height), undoManager: undoManager)
        updateView.toggle()
    }
    
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
                    if changed == false {
                        document.core.nodesWidget.setLibraryName(libraryName, undoManager: undoManager)
                        updateView.toggle()
                    }
                })
                .frame(minWidth: 300)
                
                Text("Shader Description")
                    .foregroundColor(Color.secondary)
                    .padding(.top, 5)
                TextEditor(text: $libraryDescription)
                .onChange(of: libraryDescription) { _, _ in
                    document.core.nodesWidget.setLibraryDescription(libraryDescription, undoManager: undoManager)
                 }
                .frame(minWidth: 300, minHeight: 60)

                Text("Tags")
                    .foregroundColor(Color.secondary)
                    .padding(.top, 5)
                TextField("metal, raymarching, noise", text: $libraryTags, onEditingChanged: { (changed) in
                    if changed == false {
                        document.core.nodesWidget.setLibraryTags(libraryTags, undoManager: undoManager)
                        updateView.toggle()
                    }
                })
                .frame(minWidth: 300)

                Divider()
                
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
                .onChange(of: userDescription) { _, _ in
                    document.core.library.userDescription = userDescription
                 }
                .frame(minWidth: 300, minHeight: 60)
                
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
                    addShaderNode()
                })
                .keyboardShortcut("2")
            }
            Section(header: Text("Edit Node")) {
                Button("Rename", action: {
                    if let node = document.core.nodesWidget.currentNode {
                        assetName = node.name
                        showAssetNamePopover = true
                    }
                })
                Button("Delete", action: {
                    deleteCurrentNode()
                })
                .keyboardShortcut(.delete, modifiers: [])
            }
            Section(header: Text("Show")) {
                Button("Source Only", action: {
                    withAnimation(.default) {
                        editingState = .Source
                        editingStateText = "Source Only"
                    }
                })
                .keyboardShortcut("3")
                Button("Nodes Only", action: {
                    withAnimation(.default) {
                        editingState = .Nodes
                        editingStateText = "Nodes Only"
                    }
                })
                .keyboardShortcut("4")
                Button("Source & Nodes", action: {
                    withAnimation(.default) {
                        editingState = .Both
                        editingStateText = "Source & Nodes"
                    }
                })
                .keyboardShortcut("5")
            }
            Section(header: Text("Font Size")) {
                Button("Bigger", action: {
                    document.core.scriptEditor?.increaseFontSize()
                })
                .keyboardShortcut("+")
                Button("Smaller", action: {
                    document.core.scriptEditor?.decreaseFontSize()
                })
                .keyboardShortcut("-")
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
                    if changed == false, let node = document.core.nodesWidget.currentNode {
                        document.core.nodesWidget.setNodeName(node, to: assetName, undoManager: undoManager)
                        updateView.toggle()
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

                if let selectedFile = selectedFiles.first {
                    addImageNode(from: selectedFile)
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
                    withAnimation(.default) {
                        document.core.previewFactor = 4
                        updateView.toggle()
                    }
                })
                .keyboardShortcut("6")
                Button("Medium", action: {
                    withAnimation(.default) {
                        document.core.previewFactor = 2
                        updateView.toggle()
                    }
                })
                .keyboardShortcut("7")
                Button("Large", action: {
                    withAnimation(.default) {
                        document.core.previewFactor = 1
                        updateView.toggle()
                    }
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
                    document.core.nodesWidget.setCustomSize(nil, undoManager: undoManager)
                    updateView.toggle()
                })
            }
            Section(header: Text("Opacity")) {
                Button("Opacity Off", action: {
                    withAnimation(.default) {
                        document.core.previewOpacity = 0
                        updateView.toggle()
                    }
                })
                Button("Opacity Half", action: {
                    withAnimation(.default) {
                        document.core.previewOpacity = 0.5
                        updateView.toggle()
                    }
                })
                Button("Opacity Full", action: {
                    withAnimation(.default) {
                        document.core.previewOpacity = 1.0
                        updateView.toggle()
                    }
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
            if let project = document.core.project {
                Text("\(project.size.x) x \(project.size.y)")
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
                    if let asset = core.nodesWidget.currentNode {
                        if let texture = project.render(assetFolder: core.assetFolder, device: core.device, time: 0, frame: 0, viewSize: SIMD2<Int>(Int(core.view.frame.width), Int(core.view.frame.height)), forAsset: asset) {
                            
                            project.stopDrawing(syncTexture: texture, waitUntilCompleted: true)
                            
                            if let cgiTexture = project.makeCGIImage(core.device, core.metalStates.getComputeState(state: .MakeCGIImage), texture) {
                                if let image = makeCGIImage(texture: cgiTexture, forImage: true) {
                                    if let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
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
        // Custom Resolution Popover
        .popover(isPresented: self.$showCustomResPopover,
                 arrowEdge: .top
        ) {
            VStack(alignment: .leading) {
                Text("Resolution:")
                TextField("Width", text: $customResWidth, onEditingChanged: { (changed) in
                    if changed == false {
                        setCustomResolutionFromFields()
                    }
                })
                TextField("Height", text: $customResHeight, onEditingChanged: { (changed) in
                    if changed == false {
                        setCustomResolutionFromFields()
                    }
                })
                .frame(minWidth: 200)
            }.padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(ShaderManiaDocument()), storeManager: StoreManager())
    }
}
