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
    
    @State private var selected                 : UUID? = nil

    @State var updateView                       : Bool = false
    
    #if os(macOS)
    let TopRowPadding                       : CGFloat = 2
    #else
    let TopRowPadding                       : CGFloat = 5
    #endif

    init(_ model: Model)
    {
        self.model = model
        //_selected = State(initialValue: model.project.main.id)
    }
    
    var body: some View {
        
        ZStack(alignment: .bottomLeading) {

            List {
                Section(header: Text("Objects")) {
                    
                    ForEach(model.project.objects, id: \.uuid) { tree in

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
                        })
                        {
                            Label(tree.name, systemImage: selected == nil ? "s.square.fill" :  "s.square")
                                .foregroundColor(selected == nil ? .accentColor : .primary)
                        }
                        .contextMenu {
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
                            /*
                            if let o = self.model.project.getObject(from: selected) {
                                o.name = projectName
                                self.selected = nil
                                self.selected = o.id
                            }*/
                        }
                    })
                    .frame(minWidth: 200)
                }.padding()
            }
            
            HStack {
                Menu {
                    
                    Button("Object", action: {
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
             
            /*
            .onReceive(model.selectionChanged) { _ in
                if model.codeEditorMode != .project && model.codeEditorMode != .module {
                    selected = nil
                }
            }*/
        }
    }
}
