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
        
        self._value = State(initialValue: Color(.sRGB, red: Double(parameter.defaultValue.x), green: Double(parameter.defaultValue.y), blue: Double(parameter.defaultValue.z)))
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
                                if let shader = node.shader {
                                    shader.paramData[parameter.index].x = v.x
                                    shader.paramData[parameter.index].y = v.y
                                    shader.paramData[parameter.index].z = v.z
                                }
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
        
        self._value = State(initialValue: Double(parameter.defaultValue.x))
        self._valueText = State(initialValue: String(format: "%.02f", parameter.defaultValue.x))
    }

    var body: some View {

        VStack(alignment: .leading) {
            Text(parameter.name)
            HStack {
                Slider(value: Binding<Double>(get: {value}, set: { v in
                    value = v
                    valueText = String(format: "%.02f", v)

                    if let node = document.core.nodesWidget.currentNode {
                        if let shader = node.shader {
                            shader.paramData[parameter.index].x = Float(v)
                            document.core.nodesWidget.update()
                        }
                    }
                }), in: Double(parameter.min)...Double(parameter.max))//, step: Double(parameter.step))
                Text(valueText)
                    .frame(maxWidth: 40)
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
                            }
                        }
                    
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
