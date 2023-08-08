//
//  ProjectView.swift
//  ShaderMania
//
//  Created by Markus Moenig on 29/11/21.
//

import SwiftUI

struct ProjectView: View {
    
    @Environment(\.managedObjectContext) var managedObjectContext

    let model                                   : Model

    @State private var showProjectNamePopover   : Bool = false
    @State private var projectName              : String = ""

    @State private var showAssetNamePopover     : Bool = false
    @State private var assetName                : String = ""

    @State private var selected                 : SceneNode? = nil
    @State private var selectedAsset            : AssetData? = nil

    @State var updateView                       : Bool = false
    
    @State private var importingImage           : Bool = false

    #if os(macOS)
    let TopRowPadding                           : CGFloat = 2
    #else
    let TopRowPadding                           : CGFloat = 5
    #endif

    init(_ model: Model)
    {
        self.model = model
        _selected = State(initialValue: model.selectedScene)
    }
    
    var body: some View {
        
        ZStack(alignment: .bottomLeading) {

            List {
                Section(header: Text("Scenes")) {
                    
                    ForEach(model.project.scenes, id: \.uuid) { object in

                        Button(action: {
                            /*
                            let object = model.project.main
                            selected = object.id
                            model.selectedObject = object
                            model.codeEditor?.setSession(value: object.getCode(), session: object.session)
                            if model.codeEditorMode != .project {
                                model.codeEditorMode = .project
                                model.selectionChanged.send()
                            }
                             */
                            selected = object
                        })
                        {
                            Label(object.name, systemImage: selected === object ? "s.square.fill" :  "s.square")
                                .foregroundColor(selected == nil ? .accentColor : .primary)
                        }
                        .contextMenu {
                            Button("Rename", action: {
                                projectName = object.name
                                showProjectNamePopover = true
                            })
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                Section(header: Text("Assets")) {
                    
                    ForEach(model.project.assets, id: \.uuid) { object in

                        Button(action: {
                            selectedAsset = object
                        })
                        {
                            Label(object.name, systemImage: selected === object ? "s.square.fill" :  "s.square")
                                .foregroundColor(selected == nil ? .accentColor : .primary)
                        }
                        .contextMenu {
                            Button("Rename", action: {
                                assetName = object.name
                                showAssetNamePopover = true
                            })
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

            }
            
            // Edit object name
            .popover(isPresented: self.$showProjectNamePopover,
                     arrowEdge: .top
            ) {
                VStack(alignment: .leading) {
                    Text("Name:")
                    TextField("Name", text: $projectName, onEditingChanged: { (changed) in
                        if let selected = selected {
                            let select = selected
                            self.selected = nil
                            self.selected = select
                            self.selected!.name = projectName
                        }
                    })
                    .frame(minWidth: 200)
                }.padding()
            }
            
            // Edit asset name
            .popover(isPresented: self.$showAssetNamePopover,
                     arrowEdge: .top
            ) {
                VStack(alignment: .leading) {
                    Text("Name:")
                    TextField("Name", text: $assetName, onEditingChanged: { (changed) in
                        if let selected = selectedAsset {
                            let select = selected
                            self.selectedAsset = nil
                            self.selectedAsset = select
                            self.selectedAsset!.name = assetName
                            assetName = ""
                        }
                    })
                    .frame(minWidth: 200)
                }.padding()
            }
            
            HStack {
                Menu {
                    
                    Button("Image", action: {
                        importingImage = true
                        /*
                        let object = SignedObject("New Object")
                        object.code = "-- Object\n\nfunction buildObject(index, bbox, options)\n\nend\n\n-- Used for preview\nfunction defaultSize()\n    return vec3(1, 1, 1)\nend\n".data(using: .utf8)
                        model.project.objects.append(object)
                        selected = object.id
                        model.codeEditor?.setSession(value: object.getCode(), session: object.session)
                        projectName = object.name
                        showProjectNamePopover = true*/
                    })

                }
                label: {
                    Label("Add", systemImage: "plus")
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .padding(.leading, 10)
                .padding(.bottom, 6)
                Spacer()
            }
            // Import Image
            .fileImporter(
                isPresented: $importingImage,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                do {
                    let selectedFiles = try result.get()
                    
                    if let imageData: Data = try? Data(contentsOf: selectedFiles[0]) {
                        let asset = AssetData(type: .Image, name: selectedFiles[0].deletingPathExtension().lastPathComponent, data: imageData)
                        model.project.assets.append(asset)
                    }
                    
                    /*
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
                    }*/
                } catch {
                    // Handle failure.
                }
            }
             
            /*
            .onReceive(model.selectionChanged) { _ in
                if model.codeEditorMode != .project && model.codeEditorMode != .module {
                    selected = nil
                }
            }*/
        }
    }
}
