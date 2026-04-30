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
    struct RemovedConnection {
        let asset: Asset
        let slot: Int
        let connectedNodeId: UUID
    }

    struct DeletedNodeSnapshot {
        let asset: Asset
        let index: Int
        let previousCurrentId: UUID?
        let removedConnections: [RemovedConnection]
    }

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

    var graphZoom           : Float = 0.8
    var graphOffset         = float2(0, 0)

    var dragStart           = float2(0, 0)
    var dragOriginalNodeData: float4? = nil
    var mouseMovedPos       : float2? = nil

    var undoManager         : UndoManager? = nil
    var receivesKeyboardCommands = false
    private var connectedOutputNodeIds = Set<UUID>()
    private var assetById: [UUID: Asset] = [:]
    private var didWarmUpShaders = false
    
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

            if let currentNode = currentNode {
                selectNode(currentNode)
            }
            warmUpShadersForOpenDocument()
            firstDraw = false
        }
        
        if let _ = drawables.encodeStart() {
            
            drawables.drawBoxPattern(position: float2(0,0), size: drawables.viewSize, fillColor: float4(0.12, 0.12, 0.12, 1), borderColor: float4(0.14, 0.14, 0.14, 1))

            let skin = NodeSkin(drawables.font, fontScale: 0.4, graphZoom: graphZoom)
            //drawables.drawDisk(position: float2(0,0), radius: 50)
            //drawables.drawBox(position: float2(100,100), size: float2(100, 50))

            if let assets = core.assetFolder?.assets {
                connectedOutputNodeIds = Set(assets.flatMap { Array($0.slots.values) })
                assetById = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0) })

                for asset in assets {
                    
                    //print(asset.type, asset.name)
                    drawNode(asset, asset === currentNode, skin)
                }
            } else {
                connectedOutputNodeIds.removeAll()
                assetById.removeAll()
            }
            
            if action == .Connecting {
                if let id = currentTerminalId, let currentNode = currentNode {
                    let rect = getTerminal(currentNode, id: id)
                    
                    if let mousePos = mouseMovedPos {
                        drawables.drawLine(startPos: rect.middle(), endPos: mousePos, radius: 0.6, fillColor: skin.selectedTerminalColor)
                    }
                }
            }
            
            // Draw Connections
            if let assets = core.assetFolder?.assets {
                for asset in assets {
                    
                    for (index, nodeUUID) in asset.slots {
                        if let connTo = assetById[nodeUUID] {
                            let dRect = getTerminal(connTo, id: -1)
                            let sRect = getTerminal(asset, id: index)
                            
                            if sRect.x != 0.0 && sRect.y != 0.0 {
                                drawables.drawLine(startPos: sRect.middle(), endPos: dRect.middle(), radius: 0.6, fillColor: skin.selectedTerminalColor)
                            }
                        }
                    }
                }
            }
            
            drawables.encodeEnd()
        }
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

                if connectedOutputNodeIds.contains(node.id) {
                    fillColor = skin.selectedTerminalColor
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
            guard node.type == .Shader || node.type == .Common else {
                core.contentChanged.send()
                update(preview: false)
                return
            }
            node.shader = nil
            compileAndUpdatePreview(node)
        }
    }
    
    /// Compile and update the project for a given node
    func compileAndUpdatePreview(_ node: Asset)
    {
        guard let project = core.project, let assetFolder = core.assetFolder else {
            return
        }

        project.compileAssets(assetFolder: assetFolder, forAsset: node, compiler: core.shaderCompiler, finished: { () in
            
            self.core.scriptEditor?.setErrors(node.errors)
            self.core.selectionChanged.send(node)
            self.update()
        })
    }

    private func warmUpShadersForOpenDocument()
    {
        guard didWarmUpShaders == false,
              let project = core.project,
              let assetFolder = core.assetFolder else {
            return
        }

        didWarmUpShaders = true

        for asset in assetFolder.assets where asset.type == .Shader && asset.shader == nil {
            project.compileAssets(assetFolder: assetFolder, forAsset: asset, compiler: core.shaderCompiler) { [weak self, weak asset] in
                guard let self = self else {
                    return
                }

                DispatchQueue.main.async {
                    if asset === self.currentNode {
                        self.core.scriptEditor?.setErrors(asset?.errors ?? [])
                    }
                    self.update()
                }
            }
        }
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
                        }
                    }
                }
            }
        }
    }

    func makeDeletionSnapshot(for node: Asset) -> DeletedNodeSnapshot?
    {
        guard let assetFolder = core.assetFolder,
              let index = assetFolder.assets.firstIndex(of: node) else {
            return nil
        }

        var removedConnections: [RemovedConnection] = []
        for asset in assetFolder.assets where asset !== node {
            for (slot, nodeUUID) in asset.slots where nodeUUID == node.id {
                removedConnections.append(RemovedConnection(asset: asset, slot: slot, connectedNodeId: nodeUUID))
            }
        }

        return DeletedNodeSnapshot(
            asset: node,
            index: index,
            previousCurrentId: assetFolder.currentId,
            removedConnections: removedConnections
        )
    }

    func deleteNode(_ node: Asset) -> DeletedNodeSnapshot?
    {
        guard let snapshot = makeDeletionSnapshot(for: node),
              let assetFolder = core.assetFolder else {
            return nil
        }

        nodeIsAboutToBeDeleted(node)
        assetFolder.removeAsset(node)

        if assetFolder.assets.isEmpty {
            currentNode = nil
            assetFolder.current = nil
            assetFolder.currentId = nil
        } else if let current = assetFolder.current {
            selectNode(current)
        }

        core.contentChanged.send()
        update()
        return snapshot
    }

    func restoreDeletedNode(_ snapshot: DeletedNodeSnapshot)
    {
        guard let assetFolder = core.assetFolder else {
            return
        }

        if assetFolder.assets.contains(snapshot.asset) == false {
            let insertionIndex = min(snapshot.index, assetFolder.assets.count)
            assetFolder.assets.insert(snapshot.asset, at: insertionIndex)
        }

        for connection in snapshot.removedConnections {
            connection.asset.slots[connection.slot] = connection.connectedNodeId
        }

        selectNode(snapshot.asset)
        core.contentChanged.send()
        update()
    }

    func registerAddedNodesUndo(_ nodes: [Asset], undoManager: UndoManager?, actionName: String)
    {
        guard nodes.isEmpty == false else {
            return
        }

        undoManager?.registerUndo(withTarget: self) { widget in
            let snapshots = nodes.compactMap { widget.deleteNode($0) }
            widget.registerRestoreNodesUndo(for: snapshots, undoManager: undoManager)
        }
        undoManager?.setActionName(actionName)
    }

    func registerAddedNodeUndo(_ node: Asset, undoManager: UndoManager?, actionName: String)
    {
        registerAddedNodesUndo([node], undoManager: undoManager, actionName: actionName)
    }

    private func registerRestoreNodesUndo(for snapshots: [DeletedNodeSnapshot], undoManager: UndoManager?)
    {
        undoManager?.registerUndo(withTarget: self) { widget in
            for snapshot in snapshots.sorted(by: { $0.index < $1.index }) {
                widget.restoreDeletedNode(snapshot)
            }
            widget.registerAddedNodesUndo(snapshots.map { $0.asset }, undoManager: undoManager, actionName: "Add Node")
        }
    }

    func deleteNodeWithUndo(_ node: Asset, undoManager: UndoManager?)
    {
        guard let snapshot = deleteNode(node) else {
            return
        }

        registerRestoreUndo(for: snapshot, undoManager: undoManager)
        undoManager?.setActionName("Delete Node")
    }

    func deleteCurrentNodeWithUndo()
    {
        guard let currentNode = currentNode else {
            return
        }

        deleteNodeWithUndo(currentNode, undoManager: undoManager)
    }

    private func registerRestoreUndo(for snapshot: DeletedNodeSnapshot, undoManager: UndoManager?)
    {
        undoManager?.registerUndo(withTarget: self) { widget in
            widget.restoreDeletedNode(snapshot)
            widget.registerDeleteUndo(for: snapshot, undoManager: undoManager)
        }
    }

    private func registerDeleteUndo(for snapshot: DeletedNodeSnapshot, undoManager: UndoManager?)
    {
        undoManager?.registerUndo(withTarget: self) { widget in
            if let currentSnapshot = widget.deleteNode(snapshot.asset) {
                widget.registerRestoreUndo(for: currentSnapshot, undoManager: undoManager)
            }
        }
    }

    func setNodeName(_ node: Asset, to name: String, undoManager: UndoManager? = nil)
    {
        let oldName = node.name
        guard oldName != name else {
            return
        }

        applyNodeName(node, name)
        registerNodeNameUndo(node, oldName: oldName, newName: name, undoManager: undoManager)
        undoManager?.setActionName("Rename Node")
    }

    private func applyNodeName(_ node: Asset, _ name: String)
    {
        node.name = name
        core.contentChanged.send()
        update(preview: false)
    }

    private func registerNodeNameUndo(_ node: Asset, oldName: String, newName: String, undoManager: UndoManager?)
    {
        undoManager?.registerUndo(withTarget: self) { widget in
            widget.applyNodeName(node, oldName)
            widget.registerNodeNameUndo(node, oldName: newName, newName: oldName, undoManager: undoManager)
        }
    }

    func setNodePosition(_ node: Asset, to nodeData: float4, undoManager: UndoManager? = nil)
    {
        let oldNodeData = node.nodeData
        guard oldNodeData != nodeData else {
            return
        }

        applyNodePosition(node, nodeData)
        registerNodePositionUndo(node, oldNodeData: oldNodeData, newNodeData: nodeData, undoManager: undoManager)
        undoManager?.setActionName("Move Node")
    }

    private func applyNodePosition(_ node: Asset, _ nodeData: float4)
    {
        node.nodeData = nodeData
        core.contentChanged.send()
        update(preview: false)
    }

    private func registerNodePositionUndo(_ node: Asset, oldNodeData: float4, newNodeData: float4, undoManager: UndoManager?)
    {
        undoManager?.registerUndo(withTarget: self) { widget in
            widget.applyNodePosition(node, oldNodeData)
            widget.registerNodePositionUndo(node, oldNodeData: newNodeData, newNodeData: oldNodeData, undoManager: undoManager)
        }
    }

    func setSlot(_ node: Asset, slot: Int, to connectedNodeId: UUID?, undoManager: UndoManager? = nil, actionName: String = "Edit Connection")
    {
        let oldConnectedNodeId = node.slots[slot]
        guard oldConnectedNodeId != connectedNodeId else {
            return
        }

        applySlot(node, slot: slot, connectedNodeId: connectedNodeId)
        registerSlotUndo(node, slot: slot, oldConnectedNodeId: oldConnectedNodeId, newConnectedNodeId: connectedNodeId, undoManager: undoManager)
        undoManager?.setActionName(actionName)
    }

    private func applySlot(_ node: Asset, slot: Int, connectedNodeId: UUID?)
    {
        node.slots[slot] = connectedNodeId
        core.contentChanged.send()
        update()
    }

    private func registerSlotUndo(_ node: Asset, slot: Int, oldConnectedNodeId: UUID?, newConnectedNodeId: UUID?, undoManager: UndoManager?)
    {
        undoManager?.registerUndo(withTarget: self) { widget in
            widget.applySlot(node, slot: slot, connectedNodeId: oldConnectedNodeId)
            widget.registerSlotUndo(node, slot: slot, oldConnectedNodeId: newConnectedNodeId, newConnectedNodeId: oldConnectedNodeId, undoManager: undoManager)
        }
    }

    func setShaderParameter(_ node: Asset, index: Int, to value: float4, undoManager: UndoManager? = nil)
    {
        guard index >= 0 && index < node.shaderData.count else {
            return
        }

        let oldValue = node.shaderData[index]
        guard oldValue != value else {
            return
        }

        applyShaderParameter(node, index: index, value: value)
        registerShaderParameterUndo(node, index: index, oldValue: oldValue, newValue: value, undoManager: undoManager)
        undoManager?.setActionName("Change Parameter")
    }

    private func applyShaderParameter(_ node: Asset, index: Int, value: float4)
    {
        guard index >= 0 && index < node.shaderData.count else {
            return
        }

        node.shaderData[index] = value
        core.contentChanged.send()
        update()
    }

    private func registerShaderParameterUndo(_ node: Asset, index: Int, oldValue: float4, newValue: float4, undoManager: UndoManager?)
    {
        undoManager?.registerUndo(withTarget: self) { widget in
            widget.applyShaderParameter(node, index: index, value: oldValue)
            widget.registerShaderParameterUndo(node, index: index, oldValue: newValue, newValue: oldValue, undoManager: undoManager)
        }
    }

    func setCustomSize(_ customSize: SIMD2<Int>?, undoManager: UndoManager?)
    {
        let oldCustomSize = core.assetFolder.customSize
        guard oldCustomSize != customSize else {
            return
        }

        applyCustomSize(customSize)
        registerCustomSizeUndo(oldCustomSize: oldCustomSize, newCustomSize: customSize, undoManager: undoManager)
        undoManager?.setActionName("Change Resolution")
    }

    private func applyCustomSize(_ customSize: SIMD2<Int>?)
    {
        core.assetFolder.customSize = customSize
        if let asset = core.assetFolder.current {
            core.createPreview(asset)
        }
        core.contentChanged.send()
        update()
    }

    private func registerCustomSizeUndo(oldCustomSize: SIMD2<Int>?, newCustomSize: SIMD2<Int>?, undoManager: UndoManager?)
    {
        undoManager?.registerUndo(withTarget: self) { widget in
            widget.applyCustomSize(oldCustomSize)
            widget.registerCustomSizeUndo(oldCustomSize: newCustomSize, newCustomSize: oldCustomSize, undoManager: undoManager)
        }
    }

    func setLibraryName(_ name: String, undoManager: UndoManager?)
    {
        let oldName = core.assetFolder.libraryName
        guard oldName != name else {
            return
        }

        applyLibraryName(name)
        registerLibraryNameUndo(oldName: oldName, newName: name, undoManager: undoManager)
        undoManager?.setActionName("Change Library Name")
    }

    private func applyLibraryName(_ name: String)
    {
        core.assetFolder.libraryName = name
        core.contentChanged.send()
    }

    private func registerLibraryNameUndo(oldName: String, newName: String, undoManager: UndoManager?)
    {
        undoManager?.registerUndo(withTarget: self) { widget in
            widget.applyLibraryName(oldName)
            widget.registerLibraryNameUndo(oldName: newName, newName: oldName, undoManager: undoManager)
        }
    }

    func setLibraryTags(_ tags: String, undoManager: UndoManager?)
    {
        let oldTags = core.assetFolder.libraryTags
        guard oldTags != tags else {
            return
        }

        applyLibraryTags(tags)
        registerLibraryTagsUndo(oldTags: oldTags, newTags: tags, undoManager: undoManager)
        undoManager?.setActionName("Change Library Tags")
    }

    private func applyLibraryTags(_ tags: String)
    {
        core.assetFolder.libraryTags = tags
        core.contentChanged.send()
    }

    private func registerLibraryTagsUndo(oldTags: String, newTags: String, undoManager: UndoManager?)
    {
        undoManager?.registerUndo(withTarget: self) { widget in
            widget.applyLibraryTags(oldTags)
            widget.registerLibraryTagsUndo(oldTags: newTags, newTags: oldTags, undoManager: undoManager)
        }
    }

    func setLibraryDescription(_ description: String, undoManager: UndoManager?)
    {
        let oldDescription = core.assetFolder.libraryDescription
        guard oldDescription != description else {
            return
        }

        applyLibraryDescription(description)
        registerLibraryDescriptionUndo(oldDescription: oldDescription, newDescription: description, undoManager: undoManager)
        undoManager?.setActionName("Change Library Description")
    }

    private func applyLibraryDescription(_ description: String)
    {
        core.assetFolder.libraryDescription = description
        core.contentChanged.send()
    }

    private func registerLibraryDescriptionUndo(oldDescription: String, newDescription: String, undoManager: UndoManager?)
    {
        undoManager?.registerUndo(withTarget: self) { widget in
            widget.applyLibraryDescription(oldDescription)
            widget.registerLibraryDescriptionUndo(oldDescription: newDescription, newDescription: oldDescription, undoManager: undoManager)
        }
    }
    
    /// Check if there is a terminal the given position
    func checkForNodeTerminal(_ node: Asset, at: float2) -> Int?
    {
        let inputCount = min(node.shader?.inputs.count ?? 0, node.nodeIn.count)
        for index in 0..<inputCount {
            let slot = node.nodeIn[index]
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
        core.assetFolder?.current = asset
        core.assetFolder?.currentId = asset.id
        core.selectionChanged.send(asset)

        if asset.type == .Shader || asset.type == .Common {
            core.scriptEditor?.setErrors(asset.errors)
        } else {
            core.scriptEditor?.clearAnnotations()
        }

        if asset.type == .Shader && asset.shader == nil {
            compileAndUpdatePreview(asset)
        } else {
            core.createPreview(asset)
        }
    }
    
    func touchDown(_ pos: float2)
    {
        receivesKeyboardCommands = true

        action = .None
        currentTerminalId = nil
        connectingNode = nil
        connectingTerminalId = nil
        dragOriginalNodeData = nil

        guard let assets = core.assetFolder?.assets else {
            drawables.update()
            return
        }

        for asset in assets.reversed() {
            if let t = checkForNodeTerminal(asset, at: pos) {
                if currentNode !== asset {
                    selectNode(asset)
                }

                if t != -1 && asset.slots[t] != nil {
                    setSlot(asset, slot: t, to: nil, undoManager: undoManager, actionName: "Disconnect Node")
                }

                currentTerminalId = t
                action = .Connecting
                drawables.update()
                return
            }
        }

        for asset in assets.reversed() {
            if asset.nodeRect.contains(pos.x, pos.y) {
                if currentNode !== asset {
                    selectNode(asset)
                }

                action = .DragNode
                dragStart = pos
                dragOriginalNodeData = asset.nodeData
                drawables.update()
                return
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
                update(preview: false)
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
            update(preview: false)
        }
    }

    func touchUp(_ pos: float2)
    {
        if action == .DragNode,
           let node = currentNode,
           let originalNodeData = dragOriginalNodeData,
           originalNodeData != node.nodeData {
            let newNodeData = node.nodeData
            node.nodeData = originalNodeData
            setNodePosition(node, to: newNodeData, undoManager: undoManager)
        } else
        if action == .Connecting,
           let connectingNode = connectingNode,
           let currentNode = currentNode,
           let currentTerminalId = currentTerminalId {
            // Create Connection
            
            if connectingNode.id != currentNode.id {
                if currentTerminalId != -1 {
                    setSlot(currentNode, slot: currentTerminalId, to: connectingNode.id, undoManager: undoManager, actionName: "Connect Node")
                } else if let connectingTerminalId = connectingTerminalId {
                    setSlot(connectingNode, slot: connectingTerminalId, to: currentNode.id, undoManager: undoManager, actionName: "Connect Node")
                }
            }
        }

        action = .None
        currentTerminalId = nil
        dragOriginalNodeData = nil
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
        
        update(preview: false)
    }
    
    var scaleBuffer : Float = 0
    func pinchGesture(_ scale: Float,_ firstTouch: Bool)
    {
        if firstTouch == true {
            scaleBuffer = graphZoom
        }
        
        graphZoom = max(0.2, scaleBuffer * scale)
        graphZoom = min(1, graphZoom)
        update(preview: false)
    }
    
    func update(preview: Bool = true) {

        if preview, let node = currentNode {
            core.createPreview(node)
        }

        if preview {
            core.updateNodePreview()
        }
        if preview, let node = currentNode {
            if node.type == .Shader || node.type == .Common {
                core.scriptEditor?.setErrors(node.errors)
            } else {
                core.scriptEditor?.clearAnnotations()
            }
        }
        drawables.update()
    }
}
