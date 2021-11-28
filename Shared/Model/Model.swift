//
//  Model.swift
//  ShaderMania
//
//  Created by Markus Moenig on 28/11/21.
//

import Foundation

class Model {
    
    /// The project itself
    var project                             : Project
    
    // MetalMania based Node system
    var nodeView                            : MMView!
    var nodeGraph                           : NodeGraph!
    var nodeRegion                          : MMRegion!
    
    /// The currently selected shader tree
    var selectedTree                        : Node? = nil
    
    /// The script editor
    var scriptEditor                        : ScriptEditor? = nil
    
    init() {
        project = Project()
        
        selectedTree = project.trees[0]
    }
    
    func setupNodeView(_ view: MMView)
    {
        view.startup()
        view.platformInit()

        nodeView = view
        
        nodeGraph = NodeGraph(model: self)
        nodeGraph.setup()
        
        nodeRegion = EditorRegion(view, model: self)
        
        view.editorRegion = nodeRegion
        
        //view.core = self
        //nodesWidget = NodesWidget(self)
    }
}
