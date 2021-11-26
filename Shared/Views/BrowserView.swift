//
//  BrowserView.swift
//  ShaderMania
//
//  Created by Markus Moenig on 23/11/21.
//

import SwiftUI

struct BrowserView: View {
    
    enum Mode {
        case shaderBrowser
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext

    @FetchRequest(
      entity: ShaderEntity.entity(),
      sortDescriptors: [
        NSSortDescriptor(keyPath: \ShaderEntity.name, ascending: true)
      ]
    ) var shaders: FetchedResults<ShaderEntity>
    
    @Binding var document               : ShaderManiaDocument

    @State private var mode             : Mode = .shaderBrowser
    
    @State private var IconSize         : CGFloat = 80
        
    @State private var importing        : Bool = false
    
    //@State private var selected         : UUID? = ""
    @State private var selectedShader   : ShaderEntity? = nil
    
    @State private var searchResults    : [String] = []
    
    @State private var selectedName     : String = ""

    @State private var showAssetNamePopover = false

    var body: some View {
            
        VStack(alignment: .center, spacing: 0) {

            HStack(alignment: .center, spacing: 8) {
                                    
                Button(action: {
                    importing = true
                })
                {
                    Image(systemName: "plus.app")
                        .imageScale(.large)
                }
                .buttonStyle(.borderless)
                .padding(.leading, 8)
                          
                Divider()
                                
                //Spacer()
                
                Button(action: {
                    mode = .shaderBrowser
                })
                {
                    Image(systemName: mode == .shaderBrowser ? "b.square.fill" : "b.square")
                        .imageScale(.large)
                }
                .buttonStyle(.borderless)

                Button(action: {
                    //mode = .log
                })
                {
                    Image(systemName: mode == .shaderBrowser ? "l.square.fill" : "l.square")
                        .imageScale(.large)
                }
                .buttonStyle(.borderless)
                //.padding(.leading, 4)
                    
                //Divider()
                //    .frame(maxHeight: 16)
                        
                Divider()

                Text(selectedName)
                    .frame(height: 20, alignment: .leading)
                
                Spacer()
            }
            //.frame(height: 30)
            // Edit Asset name
            .popover(isPresented: self.$showAssetNamePopover,
                     arrowEdge: .bottom
            ) {
                VStack(alignment: .leading) {
                    Text("Name:")
                    TextField("Name", text: $selectedName, onEditingChanged: { (changed) in
                        if let entity = selectedShader {
                            entity.name = selectedName
                            do {
                                try managedObjectContext.save()
                            } catch {}
                        }
                    })
                    .frame(minWidth: 200)
                }.padding()
            }
                
            Divider()
            
            if mode == .shaderBrowser {
                
                let rows: [GridItem] = Array(repeating: .init(.fixed(70)), count: 1)
                
                let columns = [
                    GridItem(.adaptive(minimum: 90))
                ]
                
                ScrollView(.horizontal) {
                    LazyVGrid(columns: columns, alignment: .center) {
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
                
            //.onReceive(document.model.searchResultsChanged) { results in
            //    searchResults = results
            //}
        }
        }
        //.animation(.default)
    }
    
    func assetEntityToImage(_ entity: ShaderEntity) -> Image? {
        
        if let data = entity.data {
         
            #if os(OSX)
            if let nsImage = NSImage(data: data) {
                return Image(nsImage: nsImage)
            }
            #elseif os(iOS)
            if let _ =  UIImage(contentsOfFile: url.path) { isImage = true }
            #endif
            
        }
        
        return nil
    }
    
    /// Loads an url into a Data
    func urlToData(_ url: URL) -> Data? {
                
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            print(error)
        }
        
        /*
        if var tempURL = document.model.getTempURL() {
            tempURL.appendPathExtension(".usd")
            
            let asset = MDLAsset(url: url)
            
            do {
                try asset.export(to: tempURL)
                let data = try Data(contentsOf: tempURL)
                return data
            } catch {
                print(error)
            }
        }*/
        
        return nil
    }
}
