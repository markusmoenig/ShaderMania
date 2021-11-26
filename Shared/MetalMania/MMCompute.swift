//
//  MMCompute.swift
//  Framework
//
//  Created by Markus Moenig on 06.01.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

class MMCompute {
    
    let device                  : MTLDevice
    let defaultLibrary          : MTLLibrary?
    var commandQueue            : MTLCommandQueue?
//    var computePipelineState    : MTLComputePipelineState?

    var texture                 : MTLTexture!
    var width, height           : Float
    
    var tWidth, tHeight         : Float
    
    var threadsPerThreadgroup   : MTLSize!
    var threadsPerGrid          : MTLSize!
    var threadgroupsPerGrid     : MTLSize!
    
    var commandBuffer           : MTLCommandBuffer!
    
    init()
    {
        device = MTLCreateSystemDefaultDevice()!
        defaultLibrary = device.makeDefaultLibrary()
        commandQueue = device.makeCommandQueue()
        
        width = 0
        height = 0
        
        tWidth = -1
        tHeight = -1
    }
    
    /// Creates a state from an optional library and the function name
    func createState( library: MTLLibrary? = nil, name: String ) -> MTLComputePipelineState?
    {
        let function : MTLFunction?
            
        if library != nil {
            function = library!.makeFunction( name: name )
        } else {
            function = defaultLibrary!.makeFunction( name: name )
        }
        
        var computePipelineState : MTLComputePipelineState?
        
        do {
            computePipelineState = try device.makeComputePipelineState( function: function! )
        } catch {
            print( "computePipelineState failed" )
            return nil
        }

        return computePipelineState
    }
    
    /// --- Creates a library from the given source
    func createLibraryFromSource( source: String ) -> MTLLibrary?
    {
        var library : MTLLibrary
        do {
            library = try device.makeLibrary( source: source, options: nil )
        } catch
        {
            print( "Make Library Failed" )
            print( error )
            return nil
        }
        return library;
    }
    
    /// Allocate the output texture, optionally can be used to create an arbitray texture by setting output to false
    @discardableResult func allocateTexture( width: Float, height: Float, output: Bool? = true ) -> MTLTexture?
    {
        self.texture = nil
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        textureDescriptor.width = Int(width)
        textureDescriptor.height = Int(height)
        
        textureDescriptor.usage = MTLTextureUsage.unknown

        let texture = device.makeTexture( descriptor: textureDescriptor )
        if output! {
            self.texture = texture
        }
        
        self.width = width
        self.height = height
        
        return texture
    }

    /// Run the given state
    func run(_ state: MTLComputePipelineState?, outTexture: MTLTexture? = nil, inBuffer: MTLBuffer? = nil, inTexture: MTLTexture? = nil )
    {
        commandBuffer = commandQueue!.makeCommandBuffer()!
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        computeEncoder.setComputePipelineState( state! )
        
        let texture = outTexture != nil ? outTexture! : self.texture!
        computeEncoder.setTexture( texture, index: 0 )
        
        if let buffer = inBuffer {
            computeEncoder.setBuffer(buffer, offset: 0, index: 1)
        }
        
        if let texture = inTexture {
            computeEncoder.setTexture(texture, index: 2)
        }
        
        //if outTexture != nil || tWidth != width || tHeight != height {
            calculateThreadGroups(state!, computeEncoder, texture.width, texture.height, store: outTexture == nil)
        //} else {
        /*
            computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        }*/
        computeEncoder.endEncoding()
        commandBuffer.commit()
    }

    /// Run the given state
    func runBuffer(_ state: MTLComputePipelineState?, outBuffer: MTLBuffer, inBuffer: MTLBuffer? = nil, size: float2? = nil, inTexture: MTLTexture? = nil, wait: Bool = true )
    {
        commandBuffer = commandQueue!.makeCommandBuffer()!
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        computeEncoder.setComputePipelineState( state! )
        computeEncoder.setBuffer(outBuffer, offset: 0, index: 0)

        if let buffer = inBuffer {
            computeEncoder.setBuffer(buffer, offset: 0, index: 1)
        }
        
        if inTexture != nil {
            computeEncoder.setTexture(inTexture, index: 2)
        }
        
        if size != nil {
            calculateThreadGroups(state!, computeEncoder, Int(size!.x), Int(size!.y), limitThreads: true)
        } else {
            let numThreadgroups = MTLSize(width: 1, height: 1, depth: 1)
            let threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)
            computeEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
        }
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
        if wait {
            commandBuffer.waitUntilCompleted()
        }
    }
    
    // Compute the threads and thread groups for the given state and texture
    func calculateThreadGroups(_ state: MTLComputePipelineState, _ encoder: MTLComputeCommandEncoder,_ width: Int,_ height: Int, store: Bool = false, limitThreads: Bool = false)
    {
        let w = limitThreads ? 1 : state.threadExecutionWidth
        let h = limitThreads ? 1 : state.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        
        //let threadsPerGrid = MTLSize(width: width, height: height, depth: 1)
        //encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

        let threadgroupsPerGrid = MTLSize(width: (width + w - 1) / w, height: (height + h - 1) / h, depth: 1)
                
        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        /*
        if store {
            self.threadsPerThreadgroup = threadsPerThreadgroup
            self.threadsPerGrid = threadsPerGrid
            self.threadgroupsPerGrid = threadgroupsPerGrid
            
            tWidth = Float(texture.width)
            tHeight = Float(texture.height)
        }*/
    }
}
