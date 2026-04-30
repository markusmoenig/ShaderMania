//
//  Views.swift
//  ShaderMania
//
//  Created by Markus Moenig on 7/1/21.
//

import SwiftUI

/// Float3ColorParameterView
struct Float3ColorParameterView: View {
    @State var document                     : ShaderManiaDocument
    @State var parameter                    : ShaderParameter

    @State private var value                = Color.white

    @Binding var updateView                 : Bool
    @Environment(\.undoManager) private var undoManager

    init(document: ShaderManiaDocument, parameter: ShaderParameter, updateView: Binding<Bool>)
    {
        self._document = State(initialValue: document)
        self._parameter = State(initialValue: parameter)
        self._updateView = updateView
        
        if let node = document.core.nodesWidget.currentNode {
            self._value = State(initialValue: Color(.sRGB, red: Double(node.shaderData[parameter.index].x), green: Double(node.shaderData[parameter.index].y), blue: Double(node.shaderData[parameter.index].z)))
        }
    }

    var body: some View {

        VStack(alignment: .leading) {
            Text(parameter.name)
            HStack {
                ColorPicker("", selection: $value, supportsOpacity: false)
                Spacer()
                    .onChange(of: value) { _, newValue in
                        if let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                           let cgColor = newValue.cgColor?.converted(to: colorSpace, intent: .defaultIntent, options: nil),
                           let components = cgColor.components,
                           components.count >= 3 {
                            let v = float3(Float(components[0]), Float(components[1]), Float(components[2]))
                            if let node = document.core.nodesWidget.currentNode {
                                var shaderValue = node.shaderData[parameter.index]
                                shaderValue.x = v.x
                                shaderValue.y = v.y
                                shaderValue.z = v.z
                                document.core.nodesWidget.setShaderParameter(node, index: parameter.index, to: shaderValue, undoManager: undoManager)
                            }
                        }
                    }
            }
        }
    }
}

/// FloatSliderParameterView
struct FloatSliderParameterView: View {
    @State var document                     : ShaderManiaDocument
    @State var parameter                    : ShaderParameter
    @State var value                        : Double = 0
    @State var valueText                    : String = ""
    @State private var editingStartValue    : Double? = nil

    @Binding var updateView                 : Bool
    @Environment(\.undoManager) private var undoManager

    init(document: ShaderManiaDocument, parameter: ShaderParameter, updateView: Binding<Bool>)
    {
        self._document = State(initialValue: document)
        self._parameter = State(initialValue: parameter)
        self._updateView = updateView
        
        if let node = document.core.nodesWidget.currentNode {
            self._value = State(initialValue: Double(node.shaderData[parameter.index].x))
            self._valueText = State(initialValue: String(format: "%.02f", node.shaderData[parameter.index].x))
        }
    }

    var body: some View {

        VStack(alignment: .leading) {
            Text(parameter.name)
            HStack {
                Slider(value: Binding<Double>(get: {value}, set: { v in
                    value = v
                    valueText = String(format: "%.02f", v)

                    if let node = document.core.nodesWidget.currentNode {
                        node.shaderData[parameter.index].x = Float(v)
                        document.core.nodesWidget.update()
                    }
                }), in: Double(parameter.min)...Double(parameter.max), onEditingChanged: { editing in
                    if editing {
                        editingStartValue = value
                    } else if let node = document.core.nodesWidget.currentNode {
                        var oldShaderValue = node.shaderData[parameter.index]
                        oldShaderValue.x = Float(editingStartValue ?? value)
                        let newShaderValue = node.shaderData[parameter.index]

                        node.shaderData[parameter.index] = oldShaderValue
                        document.core.nodesWidget.setShaderParameter(node, index: parameter.index, to: newShaderValue, undoManager: undoManager)
                        editingStartValue = nil
                    }
                })//, step: Double(parameter.step))
                Text(valueText)
                    .frame(maxWidth: 40)
            }
        }
    }
}

/// UrlParameterView
struct UrlParameterView: View {
    @State var document                     : ShaderManiaDocument
    @State var parameter                    : ShaderParameter

    @Binding var updateView                 : Bool

    init(document: ShaderManiaDocument, parameter: ShaderParameter, updateView: Binding<Bool>)
    {
        self._document = State(initialValue: document)
        self._parameter = State(initialValue: parameter)
        self._updateView = updateView
    }

    var body: some View {

        VStack(alignment: .leading) {
            HStack {
                if let url = parameter.url {
                    Link(parameter.name, destination: url)
                    //Button(parameter.url!.absoluteString) {
                     //   print(url.absoluteString)
                    //    openURL(URL(string: url.absoluteString())!)
                    //}
                }
            }
        }
    }
}

/// ParameterListView
struct ParameterListView: View {
    @State var document                     : ShaderManiaDocument
    @State var currentNode                  : Asset? = nil
    
    @Binding var updateView                 : Bool

    var body: some View {
        VStack {
            if let node = currentNode {
                
                if let shader = node.shader {

                    if shader.parameters.count > 0 {
                        Text("Parameters for \(node.name)")
                            .padding(.top, 2)
                        Divider()

                        ForEach(shader.parameters, id: \.id) { parameter in
                            if parameter.type == .Float && parameter.uiType == .Slider {
                                FloatSliderParameterView(document: document, parameter: parameter, updateView: $updateView)
                                    .padding(2)
                                    .padding(.leading, 6)
                            } else
                            if parameter.type == .Float3 && parameter.uiType == .Color {
                                Float3ColorParameterView(document: document, parameter: parameter, updateView: $updateView)
                                    .padding(2)
                                    .padding(.leading, 6)
                            } else
                            if parameter.type == .Text && parameter.uiType == .Button {
                                UrlParameterView(document: document, parameter: parameter, updateView: $updateView)
                                    .padding(2)
                                    .padding(.leading, 6)
                            }
                        }
                        Divider()
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Compile Time")
                        HStack {
                            Text("\(String(format: "%.02f", shader.compileTime)) ms")
                                .foregroundColor(Color.secondary)
                            Spacer()
                        }
                        .padding(2)
                        .padding(.leading, 10)
                    }
                    .padding(2)
                    .padding(.leading, 6)
                }
            }
            
            Spacer()
        }
        
        .onReceive(self.document.core.selectionChanged) { asset in
            currentNode = nil
            currentNode = asset
        }
    }
}

/// ShaderList
struct LibraryShaderThumbnail: View {
    let shader: LibraryShader
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)

            if let image = shader.cgiImage {
                Image(image, scale: 1.0, label: Text(shader.name))
                    .interpolation(.high)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                ProgressView()
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
        )
    }
}

struct LibraryShaderCard: View {
    let shader: LibraryShader

    private var authorName: String? {
        shader.userRecord?["nickName"] as? String
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LibraryShaderThumbnail(shader: shader, width: 176, height: 117)

            Text(shader.name)
                .font(.headline)
                .lineLimit(1)

            if let authorName = authorName, authorName.isEmpty == false {
                Text(authorName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}

struct ShaderList: View {
    @State var document                     : ShaderManiaDocument
    
    @Binding var updateView                 : Bool
    @Binding var shaders                    : LibraryShaderList?
    var isLoading                           : Bool = false
    var searchTerm                          : String = ""

    @State var detailedShader               : LibraryShader? = nil
    @State var authorOfShader               : LibraryShader? = nil
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        if let authorOfShader = authorOfShader {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button(action: {
                        self.authorOfShader = nil
                    })
                    {
                        Label("Back", systemImage: "chevron.left")
                    }
                    
                    Spacer()
                }
                
                if let userRecord = authorOfShader.userRecord {
                    Text((userRecord["nickName"] as? String) ?? "Unknown Author")
                        .font(.headline)
                    Text((userRecord["description"] as? String) ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("Shaders")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ScrollView {
                    LazyVStack(spacing: 10) {
                        if let shaders = self.shaders {
                            ForEach(shaders.shaders, id: \.id) { shader in

                                Button(action: {
                                    detailedShader = shader
                                    self.authorOfShader = nil
                                })
                                {
                                    LibraryShaderCard(shader: shader)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        } else
        if let detailedShader = detailedShader {
        
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button(action: {
                        self.detailedShader = nil
                    })
                    {
                        Label("Back", systemImage: "chevron.left")
                    }
                    
                    Spacer()
                }
                                    
                LibraryShaderThumbnail(shader: detailedShader, width: 188, height: 125)

                Text(detailedShader.name)
                    .font(.headline)
                    .lineLimit(2)
                
                if let userRecord = detailedShader.userRecord {
                    Button(action: {
                        authorOfShader = detailedShader
                        document.core.library.requestShadersOfShaderAuthor(detailedShader)
                    })
                    {
                        Label((userRecord["nickName"] as? String) ?? "Unknown Author", systemImage: "person.crop.circle")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(Color.secondary)

                    Text(detailedShader.description.isEmpty ? "No description." : detailedShader.description)
                        .font(.body)
                        .foregroundColor(detailedShader.description.isEmpty ? .secondary : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Button(action: {
                    let importedAssets = document.core.library.addShaderToProject(detailedShader)
                    document.core.nodesWidget.registerAddedNodesUndo(importedAssets, undoManager: undoManager, actionName: "Add Shader")
                    updateView.toggle()
                })
                {
                    Label("Add to Project", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()
            }
            .padding(.horizontal, 8)
            
        } else {
            if isLoading && shaders == nil {
                VStack(spacing: 10) {
                    Spacer()
                    ProgressView()
                    Text("Loading shaders")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if let shaders = shaders, shaders.shaders.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: searchTerm.isEmpty ? "tray" : "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(searchTerm.isEmpty ? "No shaders available" : "No matches")
                        .font(.headline)
                    Text(searchTerm.isEmpty ? "The public library did not return any displayable shaders." : "Try another search term.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if let shaders = self.shaders {
                            ForEach(shaders.shaders, id: \.id) { shader in

                                Button(action: {
                                    detailedShader = shader
                                })
                                {
                                    LibraryShaderCard(shader: shader)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button("Add to Project") {
                                        let importedAssets = document.core.library.addShaderToProject(shader)
                                        document.core.nodesWidget.registerAddedNodesUndo(importedAssets, undoManager: undoManager, actionName: "Add Shader")
                                        updateView.toggle()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }
            }
        }
    }
}

/// LibraryView
struct LibraryView: View {
    @State var document                     : ShaderManiaDocument
    
    @Binding var updateView                 : Bool

    @State var shaders                      : LibraryShaderList? = nil
    
    @State var searchTerm                   : String = ""
    @State var isLoading                    : Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            
            Text("Shader Library")
                .font(.headline)
                .padding(.top, 2)
            
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search", text: $searchTerm)
                    .textFieldStyle(.plain)
                    .onChange(of: searchTerm) { _, _ in
                        requestShaders()
                    }
                if searchTerm != "" {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.medium)
                        .foregroundColor(.secondary)
                        .padding(3)
                        .onTapGesture {
                            withAnimation {
                                searchTerm = ""
                                requestShaders()
                              }
                        }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 8)
            Divider()
            
            ShaderList(document: document, updateView: $updateView, shaders: $shaders, isLoading: isLoading, searchTerm: searchTerm)
            
            Spacer()
        }
        
        .onAppear(perform: {
            shaders = nil
            shaders = self.document.core.library.currentList
            updateView.toggle()
        })

        .onReceive(self.document.core.libraryChanged) { list in
            shaders = nil
            shaders = list
            isLoading = false
            updateView.toggle()
        }
    }

    private func requestShaders()
    {
        isLoading = true
        shaders = nil
        document.core.library.requestShaders(searchTerm)
    }
}
