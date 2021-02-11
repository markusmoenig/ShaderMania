//
//  Views.swift
//  ShaderMania
//
//  Created by Markus Moenig on 7/1/21.
//

import SwiftUI

/// ParameterView
struct ParameterView: View {
    @State var document                     : ShaderManiaDocument
    @State var currentNode                  : Asset? = nil
    
    @Binding var updateView                 : Bool

    var body: some View {
        VStack {
            if let node = currentNode {
                Text("Parameters for \(node.name)")
            }
            
            Divider()
            Spacer()
        }
        
        .onReceive(self.document.core.selectionChanged) { asset in
            currentNode = asset
        }
    }
}

/// The left panel
struct LeftPanelView: View {
    @State var document                     : ShaderManiaDocument
    @Binding var updateView                 : Bool
    
    @Binding var showAssetNamePopover       : Bool
    @Binding var assetName                  : String
    
    @Binding var showDeleteAssetAlert       : Bool
    
    @State private var showTextureItems     : Bool = true
    @State private var showBufferItems      : Bool = true

    var body: some View {
        VStack {
            HStack {

                Button(action: {
                    //importingImages = true
                    document.core.assetFolder.addTexture("New Texture")
                    assetName = document.core.assetFolder.current!.name
                    showAssetNamePopover = true
                    updateView.toggle()
                })
                {
                    Label("", systemImage: "checkerboard.rectangle")
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 10)
                .padding(.bottom, 1)
                
                /*
                Button(action: {
                    document.core.assetFolder.addBuffer("New Shader")
                    assetName = document.core.assetFolder.current!.name
                    showAssetNamePopover = true
                    document.core.assetFolder.assetCompile(document.core.assetFolder.current!)
                    updateView.toggle()
                })
                {
                    Label("", systemImage: "fx")
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 1)
                Spacer()*/
            }
            // Edit Asset name
            .popover(isPresented: self.$showAssetNamePopover,
                     arrowEdge: .top
            ) {
                VStack(alignment: .leading) {
                    Text("Name:")
                    TextField("Name", text: $assetName, onEditingChanged: { (changed) in
                        if let asset = document.core.assetFolder.current {
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
                    ForEach(document.core.assetFolder.assets, id: \.id) { asset in
                        if asset.type == .Texture {
                            Button(action: {
                                document.core.assetFolder.select(asset.id)
                                document.core.createPreview(asset)
                                updateView.toggle()
                            })
                            {
                                Label(asset.name, systemImage: asset.data.isEmpty ? "checkerboard.rectangle" : "photo")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .contextMenu {
                                Button(action: {
                                    document.core.assetFolder.select(asset.id)
                                    assetName = asset.name
                                    showAssetNamePopover = true
                                })
                                {
                                    Label("Rename", systemImage: "pencil")
                                }
                                
                                Button(action: {
                                    document.core.assetFolder.select(asset.id)
                                    showDeleteAssetAlert = true
                                })
                                {
                                    Label("Remove", systemImage: "minus")
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowBackground(Group {
                                if document.core.assetFolder.current!.id == asset.id {
                                    Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                                } else { Color.clear }
                            })
                        }
                    }
                    // Drag and drop
                    .onMove { indexSet, newOffset in
                        document.core.assetFolder.assets.move(fromOffsets: indexSet, toOffset: newOffset)
                        updateView.toggle()
                    }
                }
                DisclosureGroup("Shaders", isExpanded: $showBufferItems) {
                    ForEach(document.core.assetFolder.assets, id: \.id) { asset in
                        if asset.type == .Shader {
                            Button(action: {
                                document.core.assetFolder.select(asset.id)
                                document.core.createPreview(asset)
                                updateView.toggle()
                            })
                            {
                                Label(asset.name, systemImage: "fx")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .contextMenu {
                                Button(action: {
                                    document.core.assetFolder.select(asset.id)
                                    assetName = asset.name
                                    showAssetNamePopover = true
                                })
                                {
                                    Label("Rename", systemImage: "pencil")
                                }
                                
                                Button(action: {
                                    document.core.assetFolder.select(asset.id)
                                    showDeleteAssetAlert = true
                                })
                                {
                                    Label("Remove", systemImage: "minus")
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowBackground(Group {
                                if document.core.assetFolder.current!.id == asset.id {
                                    Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                                } else { Color.clear }
                            })
                        }
                    }
                    // Drag and drop
                    .onMove { indexSet, newOffset in
                        document.core.assetFolder.assets.move(fromOffsets: indexSet, toOffset: newOffset)
                        updateView.toggle()
                    }
                }
                #if os(macOS)
                Divider()
                #endif
                ForEach(document.core.assetFolder.assets, id: \.id) { asset in
                    if asset.type == .Shader || asset.type == .Common {
                        Button(action: {
                            document.core.assetFolder.select(asset.id)
                            document.core.createPreview(asset)
                            updateView.toggle()
                        })
                        {
                            Label(asset.name, systemImage: asset.type == .Shader ? "fx" : "fx")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Group {
                            if document.core.assetFolder.current!.id == asset.id {
                                Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                            } else { Color.clear }
                        })
                    }
                }
            }
            .layoutPriority(0)
        }
    }
}

/// View for displaying the shader input buffers
struct BufferInputsView: View {
    @State var document     : ShaderManiaDocument
    @Binding var updateView : Bool

    var body: some View {
        if let asset = document.core.assetFolder.current {
            Section(header: Text("Inputs")) {
                // Slot 0
                Menu {
                    Button("Black", action: {
                        asset.slots[0] = nil
                        updateView.toggle()
                        document.core.createPreview.send()
                    })
                    ForEach(document.core.assetFolder.assets, id: \.id) { textureAsset in
                        if textureAsset.type == .Texture {
                            Button(textureAsset.name, action: {
                                asset.slots[0] = textureAsset.id
                                updateView.toggle()
                                document.core.createPreview.send()
                            })
                        }
                    }
                }
                label: {
                    Text("Slot 0: \(document.core.assetFolder.getSlotName(asset, 0))")
                }

                // Slot1
                Menu {
                    Button("Black", action: {
                        asset.slots[1] = nil
                        updateView.toggle()
                        document.core.createPreview.send()
                    })
                    ForEach(document.core.assetFolder.assets, id: \.id) { textureAsset in
                        if textureAsset.type == .Texture {
                            Button(textureAsset.name, action: {
                                asset.slots[1] = textureAsset.id
                                updateView.toggle()
                                document.core.createPreview.send()
                            })
                        }
                    }
                }
                label: {
                    Text("Slot 1: \(document.core.assetFolder.getSlotName(asset, 1))")
                }

                // Slot2
                Menu {
                    Button("Black", action: {
                        asset.slots[2] = nil
                        updateView.toggle()
                        document.core.createPreview.send()
                    })
                    ForEach(document.core.assetFolder.assets, id: \.id) { textureAsset in
                        if textureAsset.type == .Texture {
                            Button(textureAsset.name, action: {
                                asset.slots[2] = textureAsset.id
                                updateView.toggle()
                                document.core.createPreview.send()
                            })
                        }
                    }
                }
                label: {
                    Text("Slot 2: \(document.core.assetFolder.getSlotName(asset, 2))")
                }

                // Slot3
                Menu {
                    Button("Black", action: {
                        asset.slots[3] = nil
                        updateView.toggle()
                        document.core.createPreview.send()
                    })
                    ForEach(document.core.assetFolder.assets, id: \.id) { textureAsset in
                        if textureAsset.type == .Texture {
                            Button(textureAsset.name, action: {
                                asset.slots[3] = textureAsset.id
                                updateView.toggle()
                                document.core.createPreview.send()
                            })
                        }
                    }
                }
                label: {
                    Text("Slot 3: \(document.core.assetFolder.getSlotName(asset, 3))")
                }
            }
            .padding(4)
            .padding(.top, 5)
        }
    }
}

/// View for displaying the shader output buffers
struct BufferOutputView: View {
    @State var document     : ShaderManiaDocument
    @Binding var updateView : Bool

    var body: some View {
        if let asset = document.core.assetFolder.current {
            Section(header: Text("Output")) {
                Menu {
                    Button("None", action: {
                        asset.output = nil
                        updateView.toggle()
                        document.core.createPreview.send()
                    })
                    
                    ForEach(document.core.assetFolder.assets, id: \.id) { textureAsset in
                        
                        if textureAsset.type == .Texture && textureAsset.data.count == 0 {
                            Button(textureAsset.name, action: {
                                asset.output = textureAsset.id
                                updateView.toggle()
                                document.core.createPreview.send()
                            })
                        }
                    }
                }
                label: {
                    Text("Output: \(document.core.assetFolder.getOutputName(asset))")
                }
            }
            .padding(4)
            .padding(.top, 5)
        }
    }
}
