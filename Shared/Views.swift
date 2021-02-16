//
//  Views.swift
//  ShaderMania
//
//  Created by Markus Moenig on 7/1/21.
//

import SwiftUI

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
                Text("Parameters for \(node.name)")
                Divider()

                if let shader = node.shader {
                    ForEach(shader.parameters, id: \.id) { parameter in
                        if parameter.uiType == .Slider {
                            FloatSliderParameterView(document: document, parameter: parameter, updateView: $updateView)
                                .padding(4)
                        }
                    }
                }
            }
            
            Spacer()
        }
        
        .onReceive(self.document.core.selectionChanged) { asset in
            currentNode = asset
        }
    }
}
