//
//  BrowserView.swift
//  ShaderMania
//
//  Created by Markus Moenig on 23/11/21.
//

import SwiftUI

/// Drop
struct URLDropDelegate: DropDelegate {

    var model       : Model
    
    func performDrop(info: DropInfo) -> Bool {
                
        guard info.hasItemsConforming(to: ["public.url"]) else {
            return false
        }

        let items = info.itemProviders(for: ["public.url"])
        
        for item in items {
            _ = item.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    var text = url.absoluteString
                    text = text.replacingOccurrences(of: "node://", with: "")
                    model.addNodeByName(text)
                }
            }
        }

        return true
    }
}

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

    @State private var showNodeNamePopover  = false
    
    @State private var browserIsMaximized   = false
    
    @State private var selectedNode     : Node? = nil

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

                Button(action: {
                    document.model.browserGoUp.send()
                })
                {
                    Image(systemName: "arrowshape.turn.up.backward")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                
                //Divider()

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
            .popover(isPresented: self.$showNodeNamePopover,
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

            ZStack(alignment: .topLeading) {
                
                WebView(document.model, deviceColorScheme)
                    .onChange(of: deviceColorScheme) { newValue in
                        document.core.scriptEditor?.setTheme(newValue)
                    }
                    .opacity(mode == .editor ? 1 : 0)
                    .disabled(selectedNode != nil && (selectedNode!.brand == .Shader || selectedNode!.brand == .LuaScript) ? false : true)
                
                NodeBrowserView(model: document.model)
                    .opacity(mode == .browser ? 1 : 0)
            }
        }
        .onReceive(document.model.selectedNodeChanged) { node in
            selectedNode = node
        }
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
