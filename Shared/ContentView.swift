//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 18/11/20.
//

import SwiftUI

struct ContentView: View {
    @Binding var document                   : ShaderManiaDocument

    @State private var showAssetNamePopover : Bool = false
    @State private var assetName            : String    = ""
    
    @State private var rightSideBarIsVisible: Bool = true
    
    @State private var showImageItems       : Bool = true
    @State private var showBufferItems      : Bool = true
    @State private var showShaderItems      : Bool = true
    @State private var updateView           : Bool = false

    @State private var helpIsVisible        : Bool = false
    
    @State private var importingImages      : Bool = false

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
                            importingImages = true
                        })
                        {
                            Label("", systemImage: "checkerboard.rectangle")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.leading, 10)
                        .padding(.bottom, 1)
                        
                        Button(action: {
                            document.game.assetFolder.addBuffer("New Buffer")
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
                    // Import Images
                    .fileImporter(
                        isPresented: $importingImages,
                        allowedContentTypes: [.item],
                        allowsMultipleSelection: true
                    ) { result in
                        do {
                            let selectedFiles = try result.get()
                            if selectedFiles.count > 0 {
                                document.game.assetFolder.addImages(selectedFiles[0].deletingPathExtension().lastPathComponent, selectedFiles)
                                assetName = document.game.assetFolder.current!.name
                                showAssetNamePopover = true
                                updateView.toggle()
                            }
                        } catch {
                            // Handle failure.
                        }
                    }
                    Divider()
                    List() {
                        DisclosureGroup("Textures", isExpanded: $showImageItems) {
                            ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                                if asset.type == .Image {
                                    Button(action: {
                                        document.game.assetFolder.select(asset.id)
                                        document.game.createPreview(asset)
                                        updateView.toggle()
                                    })
                                    {
                                        Label(asset.name, systemImage: "checkerboard.rectangle")
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
                        DisclosureGroup("Buffers", isExpanded: $showBufferItems) {
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
                        //DisclosureGroup("Final", isExpanded: $showShaderItems) {
                            ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                                if asset.type == .Shader {
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
                        //}
                    }
                    .layoutPriority(0)
                }
                
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
                        updateView.toggle()
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                    }.keyboardShortcut("t")
                    .disabled(document.game.state == .Idle)
                    
                    Divider()
                        .padding(.horizontal, 20)
                        .opacity(0)
                    
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
                    }
                    label: {
                        //Text("Preview")
                        Label("View", systemImage: "viewfinder")
                    }
                    
                    Divider()
                        .padding(.horizontal, 20)
                        .opacity(0)

                    Button(action: {
                        helpIsVisible.toggle()
                    }) {
                        //Text(!helpIsVisible ? "Help" : "Hide")
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
                            if asset.type == .Image || asset.type == .Buffer {
                                Text("Channel")
                                
                                Menu {
                                    Button("Channel 0", action: {
                                    })
                                    Button("Channel 1", action: {
                                    })
                                    Button("Channel 2", action: {
                                    })
                                    Button("Channel 3", action: {
                                    })
                                }
                                label: {
                                    Label("Channel", systemImage: "plus")
                                }
                            }
                        }
                    }
                    .frame(minWidth: 160, idealWidth: 160, maxWidth: 160)
                    .layoutPriority(0)
                    .animation(.easeInOut)
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
