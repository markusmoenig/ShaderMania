//
//  Model.swift
//  ShaderMania
//
//  Created by Markus Moenig on 28/11/21.
//

import Metal
import Combine

class Model {
    
    /// The project itself
    var project                             : Project
    
    var metalStates                         : MetalStates!
    
    // MetalMania based Node system
    var nodeView                            : MMView!
    var nodeGraph                           : NodeGraph!
    var nodeRegion                          : MMRegion!
    
    var device                              : MTLDevice!
    
    /// The currently selected shader tree
    var selectedTree                        : Node? = nil

    let selectedObjectChanged               = PassthroughSubject<Node?, Never>()
    let selectedNodeChanged                 = PassthroughSubject<Node?, Never>()
    
    /// The script editor
    var scriptEditor                        : ScriptEditor? = nil
    
    var compiler                            : ShaderCompiler!
    
    let browserIsMaximized                  = PassthroughSubject<Bool, Never>()
    
    init() {
        project = Project()
        project.model = self
        
        selectedTree = project.objects[0]

        compiler = ShaderCompiler(self)
    }
    
    /// Loaded from document
    func setProject(_ project: Project) {
        self.project = project
        self.project.model = self
        
        selectedTree = project.objects[0]
        nodeGraph?.updateNodes()
    }
    
    /// Sets up the NodeGraph from the MetalManiaView
    func setupNodeView(_ view: MMView)
    {
        view.startup()
        view.platformInit()

        nodeView = view
        
        nodeGraph = NodeGraph(model: self)
        nodeGraph.setup()
        nodeGraph.setCurrentTree(node: selectedTree)
        nodeGraph.updateNodes()
        
        nodeRegion = EditorRegion(view, model: self)
        
        view.editorRegion = nodeRegion
        device = view.device!
        
        metalStates = MetalStates(self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            view.update()
        }
    }
    
    /// Build the project, that means:
    /// 1.Compiling all uncompiled or changed shaders in the project
    func build() {
        
        if let shaderTree = selectedTree {
            project.compileTree(tree: shaderTree, compiler: compiler, finished: { () in
        
                self.nodeView.update()
                print("finished compiling")
                
            })
        }
    }
    
    /// Add the node identified by the node type name, called after DnD
    func addNodeByName(_ nodeType: String) {
        
        var brand : Node.Brand = .Tree
        var name = ""
                
        if nodeType == "Tree" {
            brand = .Tree
            name = "New ShaderTree"
        }
        
        let tree = Node(brand: brand)
        tree.children = []

        tree.name = name
        //tree.sequences.append( MMTlSequence() )
        //tree.currentSequence = object.sequences[0]
        tree.setupTerminals()
        tree.setupUI(mmView: nodeView)
        if let selectedTree = selectedTree {
            selectedTree.children?.append(tree)
        }
        DispatchQueue.main.async {
            self.nodeView.update()
        }
    }
}
