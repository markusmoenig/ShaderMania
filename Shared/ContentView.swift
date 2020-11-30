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

struct BufferInputsView: View {
    @State var document     : ShaderManiaDocument
    @Binding var updateView : Bool

    var body: some View {
        if let asset = document.game.assetFolder.current {
            Section(header: Text("Inputs")) {
                // Slot 0
                Menu {
                    Button("Black", action: {
                        asset.slots[0] = nil
                        updateView.toggle()
                        document.game.createPreview.send()
                    })
                    ForEach(document.game.assetFolder.assets, id: \.id) { textureAsset in
                        if textureAsset.type == .Texture {
                            Button(textureAsset.name, action: {
                                asset.slots[0] = textureAsset.id
                                updateView.toggle()
                                document.game.createPreview.send()
                            })
                        }
                    }
                }
                label: {
                    Text("Slot 0: \(document.game.assetFolder.getSlotName(asset, 0))")
                }

                // Slot1
                Menu {
                    Button("Black", action: {
                        asset.slots[1] = nil
                        updateView.toggle()
                        document.game.createPreview.send()
                    })
                    ForEach(document.game.assetFolder.assets, id: \.id) { textureAsset in
                        if textureAsset.type == .Texture {
                            Button(textureAsset.name, action: {
                                asset.slots[1] = textureAsset.id
                                updateView.toggle()
                                document.game.createPreview.send()
                            })
                        }
                    }
                }
                label: {
                    Text("Slot 1: \(document.game.assetFolder.getSlotName(asset, 1))")
                }

                // Slot2
                Menu {
                    Button("Black", action: {
                        asset.slots[2] = nil
                        updateView.toggle()
                        document.game.createPreview.send()
                    })
                    ForEach(document.game.assetFolder.assets, id: \.id) { textureAsset in
                        if textureAsset.type == .Texture {
                            Button(textureAsset.name, action: {
                                asset.slots[2] = textureAsset.id
                                updateView.toggle()
                                document.game.createPreview.send()
                            })
                        }
                    }
                }
                label: {
                    Text("Slot 2: \(document.game.assetFolder.getSlotName(asset, 2))")
                }

                // Slot3
                Menu {
                    Button("Black", action: {
                        asset.slots[3] = nil
                        updateView.toggle()
                        document.game.createPreview.send()
                    })
                    ForEach(document.game.assetFolder.assets, id: \.id) { textureAsset in
                        if textureAsset.type == .Texture {
                            Button(textureAsset.name, action: {
                                asset.slots[3] = textureAsset.id
                                updateView.toggle()
                                document.game.createPreview.send()
                            })
                        }
                    }
                }
                label: {
                    Text("Slot 3: \(document.game.assetFolder.getSlotName(asset, 3))")
                }
            }
            .padding(4)
            .padding(.top, 5)
        }
    }
}

struct BufferOutputView: View {
    @State var document     : ShaderManiaDocument
    @Binding var updateView : Bool

    var body: some View {
        if let asset = document.game.assetFolder.current {
            Section(header: Text("Output")) {
                Menu {
                    Button("None", action: {
                        asset.output = nil
                        updateView.toggle()
                        document.game.createPreview.send()
                    })
                    
                    ForEach(document.game.assetFolder.assets, id: \.id) { textureAsset in
                        
                        if textureAsset.type == .Texture && textureAsset.data.count == 0 {
                            Button(textureAsset.name, action: {
                                asset.output = textureAsset.id
                                updateView.toggle()
                                document.game.createPreview.send()
                            })
                        }
                    }
                }
                label: {
                    Text("Output: \(document.game.assetFolder.getOutputName(asset))")
                }
            }
            .padding(4)
            .padding(.top, 5)
        }
    }
}

struct ContentView: View {
    @Binding var document                   : ShaderManiaDocument

    @State private var showAssetNamePopover : Bool = false
    @State private var assetName            : String = ""
    
    @State private var showCustomResPopover : Bool = false
    @State private var customResWidth       : String = ""
    @State private var customResHeight      : String = ""

    @State private var rightSideBarIsVisible: Bool = true
    
    @State private var showTextureItems     : Bool = true
    @State private var showBufferItems      : Bool = true
    @State private var updateView           : Bool = false

    @State private var helpIsVisible        : Bool = false
    
    @State private var importingImage       : Bool = false
    @State private var exportingImage       : Bool = false


    @Environment(\.colorScheme) var deviceColorScheme: ColorScheme

    var body: some View {
        
        HStack {
            NavigationView() {

                VStack {
                    HStack {
                        
                        /*
                        Menu {
                            Button("Add Image", action: {
                            })
                        }
                        label: {
                            Label("", systemImage: "plus")
                        }*/

                        Button(action: {
                            //importingImages = true
                            document.game.assetFolder.addTexture("New Texture")
                            assetName = document.game.assetFolder.current!.name
                            showAssetNamePopover = true
                            updateView.toggle()
                        })
                        {
                            Label("", systemImage: "checkerboard.rectangle")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.leading, 10)
                        .padding(.bottom, 1)
                        
                        Button(action: {
                            document.game.assetFolder.addBuffer("New Shader")
                            assetName = document.game.assetFolder.current!.name
                            showAssetNamePopover = true
                            updateView.toggle()
                        })
                        {
                            Label("", systemImage: "fx")
                                //.frame(alignment: .leading)

                            
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 1)
                        Spacer()
                    }
                    // Edit Asset name
                    .popover(isPresented: self.$showAssetNamePopover,
                             arrowEdge: .top
                    ) {
                        VStack(alignment: .leading) {
                            Text("Name:")
                            TextField("Name", text: $assetName, onEditingChanged: { (changed) in
                                if let asset = document.game.assetFolder.current {
                                    asset.name = assetName
                                    self.updateView.toggle()
                                }
                            })
                            .frame(minWidth: 200)
                        }.padding()
                    }
                    Divider()
                    List() {
                        DisclosureGroup("Textures", isExpanded: $showTextureItems) {
                            ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                                if asset.type == .Texture {
                                    Button(action: {
                                        document.game.assetFolder.select(asset.id)
                                        document.game.createPreview(asset)
                                        updateView.toggle()
                                    })
                                    {
                                        Label(asset.name, systemImage: asset.data.isEmpty ? "checkerboard.rectangle" : "photo")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .listRowBackground(Group {
                                        if document.game.assetFolder.current!.id == asset.id {
                                            Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                                        } else { Color.clear }
                                    })
                                }
                            }
                        }
                        DisclosureGroup("Shaders", isExpanded: $showBufferItems) {
                            ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                                if asset.type == .Buffer {
                                    Button(action: {
                                        document.game.assetFolder.select(asset.id)
                                        document.game.createPreview(asset)
                                        updateView.toggle()
                                    })
                                    {
                                        Label(asset.name, systemImage: "fx")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .listRowBackground(Group {
                                        if document.game.assetFolder.current!.id == asset.id {
                                            Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                                        } else { Color.clear }
                                    })
                                }
                            }
                        }
                        Divider()
                            //DisclosureGroup("Final", isExpanded: $showShaderItems) {
                            ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                                if asset.type == .Shader || asset.type == .Common {
                                    Button(action: {
                                        document.game.assetFolder.select(asset.id)
                                        document.game.createPreview(asset)
                                        updateView.toggle()
                                    })
                                    {
                                        Label(asset.name, systemImage: asset.type == .Shader ? "fx" : "")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .listRowBackground(Group {
                                        if document.game.assetFolder.current!.id == asset.id {
                                            Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                                        } else { Color.clear }
                                    })
                                }
                            }
                        //}
                    }
                    .layoutPriority(0)
                }
                .frame(minWidth: 160, idealWidth: 200, maxWidth: 200)
                .layoutPriority(0)
                
                GeometryReader { geometry in
                    ZStack(alignment: .topTrailing) {

                        GeometryReader { geometry in
                            ScrollView {

                                WebView(document.game, deviceColorScheme).tabItem {
                                }
                                    .frame(height: geometry.size.height)
                                    .tag(1)
                                    .onChange(of: deviceColorScheme) { newValue in
                                        document.game.scriptEditor?.setTheme(newValue)
                                    }
                            }
                            .zIndex(0)
                            .frame(maxWidth: .infinity)
                            .layoutPriority(2)
                        }
                        
                        MetalView(document.game)
                            .zIndex(2)
                            .frame(minWidth: 0,
                                   maxWidth: geometry.size.width / document.game.previewFactor,
                                   minHeight: 0,
                                   maxHeight: geometry.size.height / document.game.previewFactor,
                                   alignment: .topTrailing)
                            .opacity(helpIsVisible ? 0 : (document.game.state == .Running ? 1 : document.game.previewOpacity))
                            .animation(.default)
                            .allowsHitTesting(false)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                           
                    /*
                    Text("Time")
                    Text(timeString)
                        .frame(width: 50, alignment: .leading)
                    */
                    
                    Menu {
                        Section(header: Text("Preview")) {
                            Button("Small", action: {
                                document.game.previewFactor = 4
                                updateView.toggle()
                            })
                            .keyboardShortcut("1")
                            Button("Medium", action: {
                                document.game.previewFactor = 2
                                updateView.toggle()
                            })
                            .keyboardShortcut("2")
                            Button("Large", action: {
                                document.game.previewFactor = 1
                                updateView.toggle()
                            })
                            .keyboardShortcut("3")
                            Button("Set Custom", action: {
                                
                                if let project = document.game.project {
                                    customResWidth = String(project.size.x)
                                    customResHeight = String(project.size.y)
                                }
                                
                                showCustomResPopover = true
                                updateView.toggle()
                            })
                            
                            Button("Clear Custom", action: {
                                
                                if let final = document.game.assetFolder.getAsset("Final", .Shader) {
                                    final.size = nil
                                    if let asset = document.game.assetFolder.current {
                                        document.game.createPreview(asset)
                                    }
                                }
                                updateView.toggle()
                            })
                        }
                        Section(header: Text("Opacity")) {
                            Button("Opacity Off", action: {
                                document.game.previewOpacity = 0
                                updateView.toggle()
                            })
                            .keyboardShortcut("4")
                            Button("Opacity Half", action: {
                                document.game.previewOpacity = 0.5
                                updateView.toggle()
                            })
                            .keyboardShortcut("5")
                            Button("Opacity Full", action: {
                                document.game.previewOpacity = 1.0
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
                        Text("\(document.game.project!.size.x) x \(document.game.project!.size.y)")
                        //Label("View", systemImage: "viewfinder")
                    }
                    
                    Divider()
                        .padding(.horizontal, 20)
                        .opacity(0)
                    
                    // Game Controls
                    Button(action: {
                        document.game.stop()
                        document.game.start()
                        helpIsVisible = false
                        updateView.toggle()
                    })
                    {
                        Label("Run", systemImage: "play.fill")
                    }
                    .keyboardShortcut("r")
                    
                    Button(action: {
                        document.game.stop()
                        if let asset = document.game.assetFolder.current {
                            document.game.createPreview(asset)
                        }
                        updateView.toggle()
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                    }.keyboardShortcut("t")
                    .disabled(document.game.state == .Idle)
                    
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
            //.onReceive(self.document.game.timeChanged) { value in
            //    timeString = String(format: "%.02f", value)
            //}
            
            .onReceive(self.document.game.createPreview) { value in
                if let asset = document.game.assetFolder.current {
                    document.game.createPreview(asset)
                }
            }
            
            .onReceive(self.document.help) { value in
                if self.helpIsVisible == false {
                    self.document.game.scriptEditor!.activateHelpSession()
                } else {
                    if let asset = document.game.assetFolder.current {
                        self.document.game.assetFolder.select(asset.id)
                    }
                }
                self.helpIsVisible.toggle()
            }
            
            .onReceive(self.document.exportImage) { value in
                exportingImage = true
            }
            
            .onReceive(self.document.game.updateUI) { value in
                updateView.toggle()
            }
        
            if rightSideBarIsVisible == true {
                if helpIsVisible == true {
                    /*
                    HelpIndexView(document.game)
                        .frame(minWidth: 160, idealWidth: 160, maxWidth: 160)
                        .layoutPriority(0)
                        .animation(.easeInOut)
                    */
                } else {
                    VStack {
                        if let asset = document.game.assetFolder.current {
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
                                        if let final = document.game.assetFolder.getAsset("Final", .Shader) {
                                            final.size = SIMD2<Int>(width, height)
                                            if let asset = document.game.assetFolder.current {
                                                document.game.createPreview(asset)
                                            }
                                        }
                                    }
                                }
                            })
                            TextField("Height", text: $customResHeight, onEditingChanged: { (changed) in
                                if let width = Int(customResWidth), width > 0 {
                                    if let height = Int(customResHeight), height > 0 {
                                        if let final = document.game.assetFolder.getAsset("Final", .Shader) {
                                            final.size = SIMD2<Int>(width, height)
                                            if let asset = document.game.assetFolder.current {
                                                document.game.createPreview(asset)
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
                                if let asset = document.game.assetFolder.current {
                                    document.game.assetFolder.attachImage(asset, selectedFiles[0])
                                    //assetName = document.game.assetFolder.current!.name
                                    //showAssetNamePopover = true
                                    document.game.assetFolder.current = nil
                                    document.game.assetFolder.select(asset.id)
                                    updateView.toggle()
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
                            let game = document.game
                            if let project = game.project {
                                if let texture = project.render(assetFolder: game.assetFolder, device: game.device, time: 0, frame: 0, viewSize: SIMD2<Int>(Int(game.view.frame.width), Int(game.view.frame.height))) {
                                    
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
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(ShaderManiaDocument()))
    }
}
