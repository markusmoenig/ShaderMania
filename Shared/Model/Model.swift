//
//  Model.swift
//  ShaderMania
//
//  Created by Markus Moenig on 28/11/21.
//

import Foundation
import Metal

class Model {
    
    /// The project itself
    var project                             : Project
    
    // MetalMania based Node system
    var nodeView                            : MMView!
    var nodeGraph                           : NodeGraph!
    var nodeRegion                          : MMRegion!
    
    var device                              : MTLDevice!
    
    /// The currently selected shader tree
    var selectedTree                        : Node? = nil
    
    /// The script editor
    var scriptEditor                        : ScriptEditor? = nil
    
    var compiler                            : ShaderCompiler!
    
    init() {
        project = Project()
        selectedTree = project.trees[0]

        compiler = ShaderCompiler(self)
    }
    
    /// Loaded from document
    func setProject(_ project: Project) {
        self.project = project
    }
    
    /// Sets up the NodeGraph from the MetalManiaView
    func setupNodeView(_ view: MMView)
    {
        view.startup()
        view.platformInit()

        nodeView = view
        
        nodeGraph = NodeGraph(model: self)
        nodeGraph.setup()
        nodeGraph.setcurrentRoot(node: selectedTree)
        
        nodeRegion = EditorRegion(view, model: self)
        
        view.editorRegion = nodeRegion
        device = view.device
    }
    
    /// Build the project, that means:
    /// 1.Compiling all uncompiled or changed shaders in the project
    func build() {
        
        if let shaderTree = selectedTree {
            project.compileTree(tree: shaderTree, compiler: compiler, finished: { () in
        
                print("finished compiling")
                
            })
        }
    }
}
