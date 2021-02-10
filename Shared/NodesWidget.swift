//
//  NodesWidget.swift
//  ShaderMania
//
//  Created by Markus Moenig on 10/2/21.
//

import Foundation

import MetalKit
import Combine

public class NodesWidget    : ObservableObject
{
    var core                : Core
    var view                : DMTKView!
    
    let drawables           : MetalDrawables
    var cmdQueue            : MTLCommandQueue? = nil
    var cmdBuffer           : MTLCommandBuffer? = nil

    init(_ core: Core)
    {
        self.core = core
        view = core.nodesView
        drawables = MetalDrawables(core.nodesView)
    }
    
    public func draw()
    {
        guard let drawable = view.currentDrawable else {
            return
        }
        
        startDrawing()
        let renderPassDescriptor = view.currentRenderPassDescriptor
        renderPassDescriptor?.colorAttachments[0].loadAction = .load
        let renderEncoder = cmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
        
        
        renderEncoder?.endEncoding()
        cmdBuffer!.present(drawable)
        stopDrawing()
    }
    
    func startDrawing()
    {
        if cmdQueue == nil {
            cmdQueue = view.device!.makeCommandQueue()
        }
        cmdBuffer = cmdQueue!.makeCommandBuffer()
    }
    
    func stopDrawing(deleteQueue: Bool = false, syncTexture: MTLTexture? = nil, waitUntilCompleted: Bool = false)
    {
        #if os(OSX)
        if let texture = syncTexture {
            let blitEncoder = cmdBuffer!.makeBlitCommandEncoder()!
            blitEncoder.synchronize(texture: texture, slice: 0, level: 0)
            blitEncoder.endEncoding()
        }
        #endif
        cmdBuffer?.commit()
        if waitUntilCompleted {
            cmdBuffer?.waitUntilCompleted()
        }
        if deleteQueue {
            cmdQueue = nil
        }
        cmdBuffer = nil
    }
}
