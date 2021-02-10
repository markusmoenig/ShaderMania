//
//  MetalDrawables.swift
//  ShaderMania
//
//  Created by Markus Moenig on 10/2/21.
//

import MetalKit

class MetalDrawables
{
    let metalView       : DMTKView
    
    let device          : MTLDevice
    let commandQueue    : MTLCommandQueue
    
    var pipelineState   : MTLRenderPipelineState!
    
    init(_ metalView: DMTKView)
    {
        self.metalView = metalView
        device = metalView.device!
        
        commandQueue = device.makeCommandQueue()!
    }
}
