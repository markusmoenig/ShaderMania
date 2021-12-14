//
//  NodeBrowserView.swift
//  ShaderMania
//
//  Created by Markus Moenig on 13/12/21.
//

import SwiftUI

struct NodeBrowserView: View {
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var deviceColorScheme: ColorScheme

    @FetchRequest(
      entity: ShaderEntity.entity(),
      sortDescriptors: [
        NSSortDescriptor(keyPath: \ShaderEntity.name, ascending: true)
      ]
    ) var shaders: FetchedResults<ShaderEntity>
    
    enum FolderType {
        case root, inbuilt, shaders, scripts
    }
    
    var model                                   : Model

    @State private var folderType                : FolderType = .root
    
    @State private var selectedShader           : ShaderEntity? = nil
    @State private var IconSize                 : CGFloat = 80

    @State private var selectedName             : String = ""
    @State private var showAssetNamePopover     = false
    
    var body: some View {

        let columns = [
            GridItem(.adaptive(minimum: 90))
        ]
        
        if folderType == .root {

            let rootFolders = ["Core", "Shaders", "Scripts"]
            let rootNodes = ["Tree"]

            ScrollView {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(rootFolders, id: \.self) { folder in
                        
                        VStack(alignment: .center, spacing: 0) {
                            
                            Image(systemName: selectedName == folder ? "folder.fill" : "folder")
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .padding(.bottom, 0)
                                .frame(width: IconSize, height: IconSize)
                                //.padding(.bottom, 15)
                                .onTapGesture(count: 2, perform: {
                                    folderType = .inbuilt
                                })
                                .onTapGesture(perform: {
                                    selectedName = folder
                                })
                            
                            Text(folder)
                                .onTapGesture(perform: {
                                    selectedName = folder
                                })
                        }
                    }
                    
                    ForEach(rootNodes, id: \.self) { node in
                        
                        VStack(alignment: .center, spacing: 0) {
                            
                            Image(systemName: selectedName == node ? "cylinder.fill" : "cylinder")
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .padding(.bottom, 0)
                                .frame(width: IconSize, height: IconSize)
                                //.padding(.bottom, 15)
                                .onTapGesture(count: 2, perform: {
                                    folderType = .inbuilt
                                })
                                .onTapGesture(perform: {
                                    selectedName = node
                                })
                                .onDrag {
                                    selectedName = node
                                    return NSItemProvider(object: URL(string: "node://" + selectedName)! as NSURL)
                                }

                            
                            Text(node)
                                .onTapGesture(perform: {
                                    selectedName = node
                                })
                        }
                    }
                }
            }
            .background(deviceColorScheme == .light ? Color.gray : Color.black)

        } else {
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(shaders, id: \.self) { shader in
                        
                        //if searchResults.contains(object.name!) {
                        ZStack(alignment: .center) {
                            
                            //if shader.type == 0 {
                                if let data = shader.data {
                                 
                                    #if os(OSX)
                                    if let nsImage = NSImage(data: data) {
                                        Image(nsImage: nsImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: IconSize, height: IconSize)
                                            .onTapGesture(perform: {
                                                selectedShader = shader
                                                selectedName = shader.name!
                                            })
                                            .contextMenu {
                                                
                                                /*
                                                Button("Add to Project") {
                                                    let object = CarthageObject(type: .Geometry, name: object.name!, libraryName: object.name!)

                                                    document.model.addToProject(object: object)
                                                }*/
                                                
                                                Button("Rename") {
                                                    showAssetNamePopover = true
                                                }
                                                
                                                Button("Remove") {
                                                    managedObjectContext.delete(shader)
                                                    do {
                                                        try managedObjectContext.save()
                                                    } catch {}
                                                }
                                            }
                                    }
                                    #endif
                                }
                                /*
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: IconSize * 0.8, height: IconSize * 0.8)
                                    .padding(.bottom, 15)
                                    .onTapGesture(perform: {
                                        selected = object.name!
                                    })
                                    .contextMenu {
                                        
                                        /*
                                        Button("Add to Project") {
                                            let object = CarthageObject(type: .Geometry, name: object.name!, libraryName: object.name!)

                                            document.model.addToProject(object: object)
                                        }*/
                                        
                                        Button("Remove") {
                                            managedObjectContext.delete(object)
                                            do {
                                                try managedObjectContext.save()
                                            } catch {}
                                        }
                                    }*/
                            }
                            
                            /*
                            if let image = shape.icon {
                                Image(image, scale: 1.0, label: Text(item))
                                    .onTapGesture(perform: {

                                    })
                            } else {
                                Rectangle()
                                    .fill(Color.secondary)
                                    .frame(width: CGFloat(IconSize), height: CGFloat(IconSize))
                                    .onTapGesture(perform: {

                                    })
                                    .contextMenu {
                                        Button("Add to Project") {
                                            
                                            let object = CarthageObject(type: .Geometry, name: object.name!, assetName: object.name!)

                                            document.model.addToProject(object: object)
                                        }
                                        
                                        Button("Remove") {
                                            managedObjectContext.delete(object)
                                            try! managedObjectContext.save()
                                        }
                                    }
                            }*/
                            
                            if shader === selectedShader {
                                Rectangle()
                                    .stroke(Color.accentColor, lineWidth: 2)
                                    .frame(width: CGFloat(IconSize), height: CGFloat(IconSize))
                                    .allowsHitTesting(false)
                            }
                            
                            /*
                            Rectangle()
                                .fill(.black)
                                .opacity(0.4)
                                .frame(width: CGFloat(IconSize - (object.name == selected ? 2 : 0)), height: CGFloat(20 - (object.name == selected ? 1 : 0)))
                                .padding(.top, CGFloat(IconSize - (20 + (object.name == selected ? 1 : 0))))
                            */
                            /*
                            object.name.map(Text.init)
                            //Text(item.name)
                                .padding(.top, CGFloat(IconSize - 20))
                                .allowsHitTesting(false)
                                .foregroundColor(.white)
                             */
                        //}
                        //}
                    }
                }
                .padding()
                .padding(.top, 0)
            }
        }
    }
}

