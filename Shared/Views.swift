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
                    .onChange(of: value) { newValue in
                        if let cgColor = newValue.cgColor {
                            let v = float3(Float(cgColor.components![0]), Float(cgColor.components![1]), Float(cgColor.components![2]))
                            if let node = document.core.nodesWidget.currentNode {
                                node.shaderData[parameter.index].x = v.x
                                node.shaderData[parameter.index].y = v.y
                                node.shaderData[parameter.index].z = v.z
                            }
                            document.core.nodesWidget.update()
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

    @Binding var updateView                 : Bool

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
                }), in: Double(parameter.min)...Double(parameter.max))//, step: Double(parameter.step))
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
struct ShaderList: View {
    @State var document                     : ShaderManiaDocument
    
    @Binding var updateView                 : Bool
    @Binding var shaders                    : LibraryShaderList?

    @State var detailedShader               : LibraryShader? = nil
    @State var authorOfShader               : LibraryShader? = nil

    var body: some View {
        if let authorOfShader = authorOfShader {
            VStack(alignment: .center) {
                HStack() {
                    Button(action: {
                        self.authorOfShader = nil
                    })
                    {
                        Label("Back to Shader", systemImage: "arrowshape.turn.up.backward")
                    }
                    
                    Spacer()
                }
                
                if let userRecord = authorOfShader.userRecord {
                    Text((userRecord["nickName"] as! String))
                        .padding(.top, 5)
                    Text((userRecord["description"] as! String))
                        .padding(.top, 4)
                }
                
                HStack {
                    Text("Shaders")
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    Spacer()
                }
                
                ScrollView {
                    VStack {
                        if let shaders = self.shaders {
                            ForEach(shaders.shaders, id: \.id) { shader in
                                    
                                Button(action: {
                                    detailedShader = shader
                                    self.authorOfShader = nil
                                })
                                {
                                    VStack(alignment: .center, spacing: 2) {
                                        Image(shader.cgiImage!, scale: 1.0, label: Text(shader.name))
                                        Text(shader.name)
                                    }

                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
        } else
        if let detailedShader = detailedShader {
        
            VStack(alignment: .center) {
                HStack() {
                    Button(action: {
                        self.detailedShader = nil
                    })
                    {
                        Label("Back to List", systemImage: "arrowshape.turn.up.backward")
                    }
                    
                    Spacer()
                }
                                    
                Image(detailedShader.cgiImage!, scale: 1.0, label: Text(detailedShader.name))
                    .padding(.top, 10)
                Text(detailedShader.name)
                
                if let userRecord = detailedShader.userRecord {
                    Button(action: {
                        authorOfShader = detailedShader
                        document.core.library.requestShadersOfShaderAuthor(detailedShader)
                    })
                    {
                        Text("Author: " + (userRecord["nickName"] as! String))
                    }
                }
                
                HStack {
                    Text("Description")
                        .foregroundColor(Color.secondary)
                    Spacer()
                }
                .padding(.top, 5)
                HStack {
                    Text(detailedShader.description)
                    Spacer()
                }
                .padding(.top, 2)
                
                Button(action: {
                    document.core.library.addShaderToProject(detailedShader)
                })
                {
                    Text("Add to Project")
                }
                .padding(.top, 5)
            }
            
        } else {
            ScrollView {
                VStack {
                    if let shaders = self.shaders {
                        ForEach(shaders.shaders, id: \.id) { shader in
                                
                            Button(action: {
                                detailedShader = shader
                            })
                            {
                                VStack(alignment: .center, spacing: 2) {
                                    Image(shader.cgiImage!, scale: 1.0, label: Text(shader.name))
                                    Text(shader.name)
                                }

                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
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
    
    var body: some View {
        VStack {
            
            Text("Shader Library")
            
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search", text: $searchTerm, onEditingChanged: { (changed) in
                    document.core.library.requestShaders(searchTerm)
                })
                if searchTerm != "" {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.medium)
                        .foregroundColor(.secondary)
                        .padding(3)
                        .onTapGesture {
                            withAnimation {
                                searchTerm = ""
                                document.core.library.requestShaders(searchTerm)
                              }
                        }
                }
            }
            .padding(2)
            Divider()
            
            ShaderList(document: document, updateView: $updateView, shaders: $shaders)
            
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
            updateView.toggle()
        }
    }
}
