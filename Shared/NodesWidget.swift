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
    enum Action {
        case None, DragNode
    }
    
    var action              : Action = .None
    
    var core                : Core
    var view                : DMTKView!
    
    let drawables           : MetalDrawables
    
    var currentNode         : Asset? = nil
    
    var scale               : Float = 1
    var offset              = float2(0, 0)

    var dragStart           = float2(0, 0)

    init(_ core: Core)
    {
        self.core = core
        view = core.nodesView
        drawables = MetalDrawables(core.nodesView)
    }
    
    public func draw()
    {        
        drawables.encodeStart()
        //drawables.drawDisk(position: float2(0,0), radius: 50)
        //drawables.drawBox(position: float2(100,100), size: float2(100, 50))
        
        if let assets = core.assetFolder?.assets {
            for asset in assets {
                
                //print(asset.type, asset.name)
                drawNode(asset)
            }
        }
        
        drawables.encodeEnd()
    }
    
    func drawNode(_ node: Asset)
    {
        let rect = MMRect()
                
        rect.x = drawables.viewSize.x / 2 + node.nodeData.x * scale
        rect.y = drawables.viewSize.y / 2 + node.nodeData.y * scale
        rect.width = 80 * scale
        rect.height = 100 * scale
        
        rect.x -= rect.width / 2
        rect.y -= rect.height / 2

        node.nodeRect.copy(rect)

        rect.x += offset.x
        rect.y += offset.y

        drawables.drawBox(position: rect.position(), size: rect.size(), rounding: 5)
        drawables.drawText(position: rect.position(), text: node.name, size: 15, color: float4(1,0,0,1))
    }
    
    func touchDown(_ pos: float2)
    {
        if let assets = core.assetFolder?.assets {
            for asset in assets {
                if asset.nodeRect.contains(pos.x - offset.x, pos.y - offset.y) {
                    print("hit", asset.name)
                    currentNode = asset
                    action = .DragNode
                    dragStart = pos
                    break
                }
            }
        }
    }
    
    func touchMoved(_ pos: float2)
    {
        if action == .DragNode {
            if let node = currentNode {
                node.nodeData.x += pos.x - dragStart.x
                node.nodeData.y += pos.y - dragStart.y
                dragStart = pos
                drawables.update()
            }
        }
    }

    func touchUp(_ pos: float2)
    {
        action = .None
    }
    
    func scrollWheel(_ delta: float3)
    {
        offset.x += delta.x
        offset.y += delta.y
        
        drawables.update()
    }
}
