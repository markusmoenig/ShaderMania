//
//  MetalStates.swift
//  ShaderMania
//
//  Created by Markus Moenig on 30/8/20.
//

import MetalKit

class MetalStates {
    
    enum States : Int {
        case DrawDisc, CopyTexture, DrawTexture, DrawBox, DrawBoxExt, DrawTextChar, DrawBackPattern
    }
    
    enum ComputeStates : Int {
        case MakeCGIImage
    }
    
    var defaultLibrary          : MTLLibrary!

    let pipelineStateDescriptor : MTLRenderPipelineDescriptor
    
    var states                  : [Int:MTLRenderPipelineState] = [:]
    var computeStates           : [Int:MTLComputePipelineState] = [:]

    var game                    : Game
    
    init(_ game: Game)
    {
        self.game = game
        
        if let frameworkId = game.frameworkId {
            for b in Bundle.allFrameworks {
                if b.bundleIdentifier == frameworkId {
                    defaultLibrary = try? game.device.makeDefaultLibrary(bundle: b)
                    break
                }
            }
        } else {
            defaultLibrary = game.device.makeDefaultLibrary()
        }
        
        let vertexFunction = defaultLibrary!.makeFunction( name: "m4mQuadVertexShader" )

        pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexFunction
        //        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm;
        
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        states[States.DrawDisc.rawValue] = createQuadState(name: "m4mDiscDrawable")
        states[States.CopyTexture.rawValue] = createQuadState(name: "m4mCopyTextureDrawable")
        states[States.DrawTexture.rawValue] = createQuadState(name: "m4mTextureDrawable")
        states[States.DrawBox.rawValue] = createQuadState(name: "m4mBoxDrawable")
        states[States.DrawBoxExt.rawValue] = createQuadState(name: "m4mBoxDrawableExt")
        states[States.DrawTextChar.rawValue] = createQuadState(name: "m4mTextDrawable")
        states[States.DrawBackPattern.rawValue] = createQuadState(name: "m4mBoxPatternDrawable")
        
        computeStates[ComputeStates.MakeCGIImage.rawValue] = createComputeState(name: "makeCGIImage")
    }
    
    /// Creates a quad state from an optional library and the function name
    func createQuadState( library: MTLLibrary? = nil, name: String ) -> MTLRenderPipelineState?
    {
        let function : MTLFunction?
            
        if library != nil {
            function = library!.makeFunction( name: name )
        } else {
            function = defaultLibrary!.makeFunction( name: name )
        }
        
        var renderPipelineState : MTLRenderPipelineState?
        
        do {
            //renderPipelineState = try device.makeComputePipelineState( function: function! )
            pipelineStateDescriptor.fragmentFunction = function
            renderPipelineState = try game.device.makeRenderPipelineState( descriptor: pipelineStateDescriptor )
        } catch {
            print( "computePipelineState failed" )
            return nil
        }
        
        return renderPipelineState
    }
    
    /// Creates a compute state from an optional library and the function name
    func createComputeState( library: MTLLibrary? = nil, name: String ) -> MTLComputePipelineState?
    {
        let function : MTLFunction?
            
        if library != nil {
            function = library!.makeFunction( name: name )
        } else {
            function = defaultLibrary!.makeFunction( name: name )
        }
        
        var computePipelineState : MTLComputePipelineState?
        
        if function == nil {
            return nil
        }
        
        do {
            computePipelineState = try game.device.makeComputePipelineState( function: function! )
        } catch {
            print( "computePipelineState failed" )
            return nil
        }

        return computePipelineState
    }
    
    func getState(state: States) -> MTLRenderPipelineState
    {
        return states[state.rawValue]!
    }
    
    func getComputeState(state: ComputeStates) -> MTLComputePipelineState
    {
        return computeStates[state.rawValue]!
    }
}
