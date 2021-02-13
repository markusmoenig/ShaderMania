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
        case None, DragNode, Connecting
    }
    
    var action              : Action = .None
    
    var core                : Core
    var view                : DMTKView!
    
    let drawables           : MetalDrawables
    
    var currentNode         : Asset? = nil
    var currentTerminalId   : Int? = nil
    
    // For connecting terminals
    var connectingNode      : Asset? = nil
    var connectingTerminalId: Int? = nil

    var graphZoom           : Float = 0.63
    var graphOffset         = float2(0, 0)

    var dragStart           = float2(0, 0)
    var mouseMovedPos       : float2? = nil
    
    var firstDraw           = true

    init(_ core: Core)
    {
        self.core = core
        view = core.nodesView
        drawables = MetalDrawables(core.nodesView)
    }
    
    public func draw()
    {
        if firstDraw {
            
            currentNode = core.assetFolder.current
            
            if currentNode != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.compileAndUpdatePreview(self.currentNode!)
                }
            }
            
            selectNode(currentNode!)
            firstDraw = false
        }
        
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
        
        if action == .Connecting {
            if let id = currentTerminalId {
                let rect = getTerminal(currentNode!, id: id)
                
                if let mousePos = mouseMovedPos {
                    drawables.drawLine(startPos: rect.middle(), endPos: mousePos, radius: 0.6, fillColor: skin.selectedTerminalColor)
                }
            }
        }
        
        // Draw Connections
        if let assets = core.assetFolder?.assets {
            for asset in assets {
                
                for (index, nodeUUID) in asset.slots {
                    if let connTo = core.assetFolder!.getAssetById(nodeUUID) {
                        let dRect = getTerminal(connTo, id: -1)
                        let sRect = getTerminal(asset, id: index)
                        
                        drawables.drawLine(startPos: sRect.middle(), endPos: dRect.middle(), radius: 0.6, fillColor: skin.selectedTerminalColor)
                    }
                }
            }
        }
        
        drawables.encodeEnd()
    }
    
    func drawNode(_ node: Asset,_ selected: Bool,_ skin: NodeSkin)
    {
        let rect = MMRect()
                
        var extraSpaceForSlots : Float = 0
        if let shader = node.shader {
            extraSpaceForSlots = 20 * Float(shader.inputs.count)
        }
        
        rect.x = drawables.viewSize.x / 2 + node.nodeData.x * graphZoom
        rect.y = drawables.viewSize.y / 2 + node.nodeData.y * graphZoom
        rect.width = 120 * graphZoom
        rect.height = (120 + extraSpaceForSlots) * graphZoom
        
        rect.x -= rect.width / 2
        rect.y -= rect.height / 2

        rect.x += graphOffset.x
        rect.y += graphOffset.y
        
        node.nodeRect.copy(rect)

        //drawables.drawBox.draw(x: rect.x + item.rect.x, y: rect.y + item.rect.y, width: item.rect.width, height: item.rect.height, round: 12 * graphZoom, borderSize: 1, fillColor: skin.normalInteriorColor, borderColor: selected ? skin.selectedBorderColor : skin.normalInteriorColor)
        drawables.drawBox(position: rect.position(), size: rect.size(), rounding: 8 * graphZoom, borderSize: 1, fillColor: skin.normalInteriorColor, borderColor: selected ? skin.selectedBorderColor : skin.normalInteriorColor)
        drawables.drawText(position: rect.position() + float2(9, 5) * graphZoom, text: node.name, size: 15 * graphZoom, color: skin.normalTextColor)
        
        drawables.drawLine(startPos: rect.position() + float2(6,24) * graphZoom, endPos: rect.position() + float2(rect.width - 8 * graphZoom, 24 * graphZoom), radius: 0.6, fillColor: skin.normalBorderColor)
        
        if node.previewTexture != nil {
            drawables.drawBox(position: rect.position() + float2(20,34 + extraSpaceForSlots) * graphZoom, size: float2(80,80) * graphZoom, rounding: 8 * graphZoom, fillColor: skin.normalInteriorColor, texture: node.previewTexture)
        }
        
        /// Get the colors for a terminal
        func terminalColor(_ terminalId: Int) -> (float4, float4)
        {
            var fillColor = skin.normalInteriorColor
            var borderColor = skin.normalBorderColor
            
            if node === currentNode && currentTerminalId == terminalId {
                // Currently pressed
                fillColor = skin.selectedTerminalColor
            } else
            if connectingNode === node && terminalId == connectingTerminalId {
                // Connecting to this terminal
                fillColor = skin.selectedTerminalColor
            } else
            if terminalId != -1 && node.slots[terminalId] != nil {
                // This slot is connected
                fillColor = skin.selectedTerminalColor
            } else
            if terminalId == -1 {
                // Test last possibility, this is an outgoing slot, see if it connects to somewhere
                
                if let assets = core.assetFolder?.assets {
                    for asset in assets {

                        if asset !== node {
                            for (_, nodeUUID) in asset.slots {
                                if nodeUUID == node.id {
                                    fillColor = skin.selectedTerminalColor
                                    break
                                }
                            }
                        }
                    }
                }
            }
            
            if selected {
                borderColor = skin.selectedBorderColor
            }
            
            return (fillColor, borderColor)
        }
        
        var x = rect.x - 7 * graphZoom
        var y = rect.y + 32 * graphZoom
        
        if let shader = node.shader {

            for (i, name) in shader.inputs.enumerated() {
                if i >= 4 {
                    break
                }
                
                let tColors = terminalColor(i)
                drawables.drawDisk(position: float2(x, y), radius: 7 * graphZoom, borderSize: 1, fillColor: tColors.0, borderColor: tColors.1)
                node.nodeIn[i].set(x, y, 14 * graphZoom, 14 * graphZoom)

                drawables.drawText(position: float2(x, y) + float2(20, 1) * graphZoom, text: name, size: 15 * graphZoom, color: skin.normalTextColor)
                
                y += 20 * graphZoom
            }
        }
        
        x = rect.x + rect.width - 7 * graphZoom
        y = rect.y + 32 * graphZoom
        
        node.nodeOut.set(x, y, 14 * graphZoom, 14 * graphZoom)
        let tColors = terminalColor(-1)

        drawables.drawBox(position: float2(x, y), size: float2(14 * graphZoom, 14 * graphZoom), borderSize: 1, fillColor: tColors.0, borderColor: tColors.1)
    }
    
    /// The source for a node has been changed
    func nodeChanged(_ value: String)
    {
        if let node = currentNode {
            node.value = value
            node.shader = nil
            compileAndUpdatePreview(node)
        }
    }
    
    /// Compile and update the project for a given node
    func compileAndUpdatePreview(_ node: Asset)
    {
        core.project!.compileAssets(assetFolder: core.assetFolder!, forAsset: node, compiler: core.shaderCompiler, finished: { () in
            
            self.core.scriptEditor?.setErrors(node.errors)
            self.update()
        })
    }
    
    /// Called before nodes get deleted, make sure to break its connections
    func nodeIsAboutToBeDeleted(_ node: Asset)
    {
        if let assets = core.assetFolder?.assets {
            for asset in assets {
                if asset !== node {
                    for (index, nodeUUID) in asset.slots {
                        if nodeUUID == node.id {
                            asset.slots[index] = nil
                            print("connection deleted")
                        }
                    }
                }
            }
        }
    }
    
    /// Check if there is a terminal the given position
    func checkForNodeTerminal(_ node: Asset, at: float2) -> Int?
    {
        for (index, slot) in node.nodeIn.enumerated() {
            if slot.contains(at.x, at.y) {
                return index
            }
        }
        
        if node.nodeOut.contains(at.x, at.y) {
            return -1
        }
        
        return nil
    }
    
    // Gets the terminal rect for the given node and id
    func getTerminal(_ node: Asset, id: Int) -> MMRect
    {
        if id == -1 {
            return node.nodeOut
        } else {
            return node.nodeIn[id]
        }
    }
    
    func selectNode(_ asset: Asset) {
        core.scriptEditor?.setAssetSession(asset)
        currentNode = asset
        core.assetFolder!.current = asset
        core.assetFolder!.currentId = asset.id
        core.selectionChanged.send(asset)
        core.createPreview(asset)
    }
    
    func touchDown(_ pos: float2)
    {
        if let assets = core.assetFolder?.assets {
            for asset in assets {
                
                if let t = checkForNodeTerminal(asset, at: pos) {
                    if currentNode !== asset {
                        selectNode(asset)
                    }
                    
                    let canConnect = true
                    if t != -1 && asset.slots[t] != nil {
                        //canConnect = false
                        asset.slots[t] = nil
                        // Disconnect instead of not allowing to connect when slot is already taken
                    }
                    
                    if canConnect {
                        currentTerminalId = t
                        action = .Connecting
                    }
                } else
                {
                    var freshlySelectedNode : Asset? = nil
                    if asset.nodeRect.contains(pos.x, pos.y) {
                        action = .DragNode
                        dragStart = pos
                        
                        freshlySelectedNode = asset
                    }
                    if freshlySelectedNode != nil && currentNode !== freshlySelectedNode {
                        selectNode(freshlySelectedNode!)
                    }
                }
            }
        }
        drawables.update()
    }
    
    func touchMoved(_ pos: float2)
    {
        mouseMovedPos = pos
        if action == .DragNode {
            if let node = currentNode {
                node.nodeData.x += (pos.x - dragStart.x) / graphZoom
                node.nodeData.y += (pos.y - dragStart.y) / graphZoom
                dragStart = pos
                update()
            }
        }
        if action == .Connecting {
            connectingNode = nil
            connectingTerminalId = nil
            
            if let assets = core.assetFolder?.assets {
                for asset in assets {
                    if let t = checkForNodeTerminal(asset, at: pos) {
                        if currentNode !== asset {
                            if (t == -1 && currentTerminalId != -1) || (currentTerminalId == -1 && t != -1) {
                                connectingNode = asset
                                connectingTerminalId = t
                            }
                        }
                        break
                    }
                }
            }
            update()
        }
    }

    func touchUp(_ pos: float2)
    {
        if action == .Connecting && connectingNode != nil {
            // Create Connection
            
            if currentTerminalId != -1 {
                currentNode!.slots[currentTerminalId!] = connectingNode!.id
            } else {
                connectingNode!.slots[connectingTerminalId!] = currentNode!.id
            }
        }

        action = .None
        currentTerminalId = nil
        mouseMovedPos = nil
        update()
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
        
        update()
    }
    
    var scaleBuffer : Float = 0
    func pinchGesture(_ scale: Float,_ firstTouch: Bool)
    {
        if firstTouch == true {
            scaleBuffer = graphZoom
        }
        
        graphZoom = max(0.2, scaleBuffer * scale)
        graphZoom = min(1, graphZoom)
        update()
    }
    
    func update() {
        if let node = currentNode {
            core.createPreview(node, updatePreviewTextures: true)
        }
        drawables.update()
    }
}
