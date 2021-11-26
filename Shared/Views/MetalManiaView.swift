//
//  MetalManiaView.swift
//  ShaderMania
//
//  Created by Markus Moenig on 25/11/21.
//

import SwiftUI
import MetalKit

#if os(OSX)
struct MetalManiaView: NSViewRepresentable {
    
    var core                    : Core!

    init(_ core: Core) {
        self.core = core
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: NSViewRepresentableContext<MetalManiaView>) -> MTKView {
        let view = MMView()
        core.setupNodesView(view)
        
        return view
    }
    
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalManiaView>) {
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        var parent              : MetalManiaView
        var metalDevice         : MTLDevice!
        var metalCommandQueue   : MTLCommandQueue!
        
        init(_ parent: MetalManiaView) {
            self.parent = parent
            
            /*
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
             */

            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        func draw(in view: MTKView) {
        }
    }
}
#else
struct MetalView: UIViewRepresentable {
    typealias UIViewType = MTKView
    var core             : Core!

    var viewType            : DMTKView.MetalViewType

    init(_ core: Core,_ viewType: DMTKView.MetalViewType)
    {
        self.core = core
        self.viewType = viewType
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<MetalView>) -> MTKView {
        let mtkView = DMTKView()
        mtkView.core = core
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
                
        if viewType == .Main {
            core.setupView(mtkView)
        } else
        if viewType == .Nodes {
            core.setupNodesView(mtkView)
        }
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<MetalView>) {
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: MetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        
        init(_ parent: MetalView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        func draw(in view: MTKView) {
            if parent.viewType == .Main {
                parent.core.draw()
            } else
            if parent.viewType == .Nodes {
                parent.core.nodesWidget.draw()
            }
        }
    }
}
#endif
