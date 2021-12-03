//
//  BrowserView.swift
//  ShaderMania
//
//  Created by Markus Moenig on 23/11/21.
//

import SwiftUI

struct BrowserView: View {
    
    enum Mode {
        case editor, browser, timeline
    }

    @Environment(\.colorScheme) var deviceColorScheme: ColorScheme
    @Environment(\.managedObjectContext) var managedObjectContext

    @FetchRequest(
      entity: ShaderEntity.entity(),
      sortDescriptors: [
        NSSortDescriptor(keyPath: \ShaderEntity.name, ascending: true)
      ]
    ) var shaders: FetchedResults<ShaderEntity>
    
    var document                        : ShaderManiaDocument
    var size                            : Binding<SIMD2<Int>>

    @State var sizeBuffer               : SIMD2<Int>

    @State private var mode             : Mode = .editor
    
    @State private var IconSize         : CGFloat = 80
        
    @State private var importing        : Bool = false
    
    //@State private var selected         : UUID? = ""
    @State private var selectedShader   : ShaderEntity? = nil
    
    @State private var searchResults    : [String] = []
    
    @State private var selectedName     : String = ""

    @State private var showAssetNamePopover = false
    
    @State private var browserIsMaximized   = false

    init(_ document: ShaderManiaDocument, size: Binding<SIMD2<Int>>) {
        self.document = document
        self.size = size
        _sizeBuffer = State(initialValue: SIMD2<Int>(self.size.wrappedValue.x, self.size.wrappedValue.y))
    }
    
    var body: some View {
            
        VStack(alignment: .center, spacing: 0) {

            HStack(alignment: .center, spacing: 8) {
                
                Button(action: {
                    mode = .editor
                    /*
                    if let node = document.model.nodeGraph.currentNode {
                        document.model.scriptEditor?.setSession(node)
                    }*/
                })
                {
                    Image(systemName: mode == .editor ? "e.square.fill" : "e.square")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
                .keyboardShortcut("1")

                Button(action: {
                    mode = .browser
                })
                {
                    Image(systemName: mode == .browser ? "b.square.fill" : "b.square")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("2")

                Button(action: {
                    mode = .timeline
                })
                {
                    Image(systemName: mode == .timeline ? "t.square.fill" : "t.square")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("3")

                Divider()

                Text(selectedName)
                    .frame(height: 20, alignment: .leading)
                
                Spacer()
                
                Button(action: {
                    browserIsMaximized.toggle()
                    document.model.browserIsMaximized.send(browserIsMaximized)
                })
                {
                    Image(systemName: browserIsMaximized == false ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                
                Divider()

                Button(action: {
                })
                {
                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                .disabled(browserIsMaximized)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged({ info in
                            let deltaX = Int(info.location.x - info.startLocation.x)
                            let deltaY = Int(info.startLocation.y - info.location.y)
                            
                            if self.size.wrappedValue.x + deltaX > 200 {
                                self.size.wrappedValue.x += deltaX
                            }
                            
                            if self.size.wrappedValue.y + deltaY > 100 {
                                self.size.wrappedValue.y += deltaY
                            }
                        })
                        .onEnded({ info in
                            sizeBuffer = SIMD2<Int>(self.size.wrappedValue.x, self.size.wrappedValue.y)
                        })
                )
            }
            .frame(height: 25)
            .background(Color.accentColor)
            
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
            
            ZStack(alignment: .topLeading) {
                
                WebView(document.model, deviceColorScheme)
                    //.animation(.default)
                    .onChange(of: deviceColorScheme) { newValue in
                        document.core.scriptEditor?.setTheme(newValue)
                    }
                    .opacity(mode == .editor ? 1 : 0)

                
                let columns = [
                    GridItem(.adaptive(minimum: 90))
                ]
                
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
                .opacity(mode == .browser ? 1 : 0)
            }

            //.onReceive(document.model.searchResultsChanged) { results in
            //    searchResults = results
            //}
        //}
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
