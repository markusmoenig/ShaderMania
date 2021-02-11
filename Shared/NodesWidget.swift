//
//  NodesWidget.swift
//  ShaderMania
//
//  Created by Markus Moenig on 10/2/21.
//

import Foundation

import MetalKit
import Combine

class NodeSkin {
    
    //let normalInteriorColor     = SIMD4<Float>(0,0,0,0)
    let normalInteriorColor     = SIMD4<Float>(0.227, 0.231, 0.235, 1.000)
    let normalBorderColor       = SIMD4<Float>(0.5,0.5,0.5,1)
    let normalTextColor         = SIMD4<Float>(0.8,0.8,0.8,1)
    let selectedTextColor       = SIMD4<Float>(0.212,0.173,0.137,1)
    
    let selectedItemColor       = SIMD4<Float>(0.4,0.4,0.4,1)

    let selectedBorderColor     = SIMD4<Float>(0.976, 0.980, 0.984, 1.000)

    let normalTerminalColor     = SIMD4<Float>(0.835, 0.773, 0.525, 1)
    let selectedTerminalColor   = SIMD4<Float>(0.835, 0.773, 0.525, 1.000)
    
    let renderColor             = SIMD4<Float>(0.325, 0.576, 0.761, 1.000)
    let worldColor              = SIMD4<Float>(0.396, 0.749, 0.282, 1.000)
    let groundColor             = SIMD4<Float>(0.631, 0.278, 0.506, 1.000)
    let objectColor             = SIMD4<Float>(0.765, 0.600, 0.365, 1.000)
    let variablesColor          = SIMD4<Float>(0.714, 0.349, 0.271, 1.000)
    let postFXColor             = SIMD4<Float>(0.275, 0.439, 0.353, 1.000)
    let lightColor              = SIMD4<Float>(0.494, 0.455, 0.188, 1.000)

    let tempRect                = MMRect()
    let fontScale               : Float
    let font                    : Font
    let lineHeight              : Float
    let itemHeight              : Float = 30
    let margin                  : Float = 20
    
    let tSize                   : Float = 15
    let tHalfSize               : Float = 15 / 2
    
    let itemListWidth           : Float
        
    init(_ font: Font, fontScale: Float = 0.4, graphZoom: Float) {
        self.font = font
        self.fontScale = fontScale
        self.lineHeight = font.getLineHeight(fontScale)
        
        itemListWidth = 140 * graphZoom
    }
}

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
    
    var graphZoom           : Float = 0.63
    var graphOffset         = float2(0, 0)

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
        
        let skin = NodeSkin(drawables.font, fontScale: 0.4, graphZoom: graphZoom)
        //drawables.drawDisk(position: float2(0,0), radius: 50)
        //drawables.drawBox(position: float2(100,100), size: float2(100, 50))
        
        if let assets = core.assetFolder?.assets {
            for asset in assets {
                
                //print(asset.type, asset.name)
                drawNode(asset, asset === currentNode, skin)
            }
        }
        
        drawables.encodeEnd()
    }
    
    func drawNode(_ node: Asset,_ selected: Bool,_ skin: NodeSkin)
    {
        let rect = MMRect()
                
        rect.x = drawables.viewSize.x / 2 + node.nodeData.x * graphZoom
        rect.y = drawables.viewSize.y / 2 + node.nodeData.y * graphZoom
        rect.width = 120 * graphZoom
        rect.height = 120 * graphZoom
        
        rect.x -= rect.width / 2
        rect.y -= rect.height / 2

        node.nodeRect.copy(rect)

        rect.x += graphOffset.x
        rect.y += graphOffset.y

        //drawables.drawBox.draw(x: rect.x + item.rect.x, y: rect.y + item.rect.y, width: item.rect.width, height: item.rect.height, round: 12 * graphZoom, borderSize: 1, fillColor: skin.normalInteriorColor, borderColor: selected ? skin.selectedBorderColor : skin.normalInteriorColor)
        drawables.drawBox(position: rect.position(), size: rect.size(), rounding: 8 * graphZoom, borderSize: 1, fillColor: skin.normalInteriorColor, borderColor: selected ? skin.selectedBorderColor : skin.normalInteriorColor)
        drawables.drawText(position: rect.position() + float2(8, 4) * graphZoom, text: node.name, size: 15 * graphZoom, color: skin.normalTextColor)
        
        drawables.drawLine(startPos: rect.position() + float2(6,24) * graphZoom, endPos: rect.position() + float2(rect.width - 8 * graphZoom, 24 * graphZoom), radius: 0.6, fillColor: skin.normalBorderColor)
        
        var x = rect.x - 7 * graphZoom
        var y = rect.y + 32 * graphZoom
        for i in 0..<4 {
            
            drawables.drawDisk(position: float2(x, y), radius: 7 * graphZoom, borderSize: 1, fillColor: skin.normalInteriorColor, borderColor: selected ? skin.selectedBorderColor : skin.normalBorderColor)
            node.nodeIn[i].set(x, y, 14 * graphZoom, 14 * graphZoom)

            y += 20 * graphZoom
        }
        
        x = rect.x + rect.width - 7 * graphZoom
        y = rect.y + 32 * graphZoom
        
        node.nodeOut.set(x, y, 14 * graphZoom, 14 * graphZoom)
        drawables.drawBox(position: float2(x, y), size: float2(14 * graphZoom, 14 * graphZoom), borderSize: 1, fillColor: skin.normalInteriorColor, borderColor: selected ? skin.selectedBorderColor : skin.normalBorderColor)
    }
    
    /// The source for a node has been changed
    func nodeChanged()
    {
        if let node = currentNode {
            print("updared", node.name)
        }
    }
    
    func touchDown(_ pos: float2)
    {
        if let assets = core.assetFolder?.assets {
            for asset in assets {
                if asset.nodeRect.contains(pos.x - graphOffset.x, pos.y - graphOffset.y) {
                    print("hit", asset.name)
                    action = .DragNode
                    dragStart = pos
                    
                    if currentNode !== asset {
                        core.scriptEditor?.setAssetSession(asset)
                        currentNode = asset
                        core.selectionChanged.send(asset)
                    }
                    break
                }
            }
        }
        drawables.update()
    }
    
    func touchMoved(_ pos: float2)
    {
        if action == .DragNode {
            if let node = currentNode {
                node.nodeData.x += (pos.x - dragStart.x) / graphZoom
                node.nodeData.y += (pos.y - dragStart.y) / graphZoom
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
        if view.commandIsDown == false {
            graphOffset.x += delta.x
            graphOffset.y += delta.y
        } else {
            graphZoom += delta.y * 0.003
            graphZoom = max(0.2, graphZoom)
            graphZoom = min(1, graphZoom)
        }
        
        drawables.update()
    }
}
