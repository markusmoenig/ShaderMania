//
//  MUIView.swift
//  Framework
//
//  Created by Markus Moenig on 03.01.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

public class MMView : MMBaseView {

    var renderer        : MMRenderer!
    var textureLoader   : MTKTextureLoader!
    
    // --- Regions
    var leftRegion      : MMRegion?
    var topRegion       : MMRegion?
    var rightRegion     : MMRegion?
    var bottomRegion    : MMRegion?
    var editorRegion    : MMRegion?

    // --- Drawables
    var drawSphere      : MMDrawSphere!
    var drawBox         : MMDrawBox!
    var drawBoxPattern  : MMDrawBoxPattern!
    var drawBoxGradient : MMDrawBoxGradient!
    var drawBoxedMenu   : MMDrawBoxedMenu!
    var drawBoxedShape  : MMDrawBoxedShape!
    var drawTexture     : MMDrawTexture!
    var drawText        : MMDrawText!
    var drawCustomState : MMDrawCustomState!
    var drawLine        : MMDrawLine!
    var drawSpline      : MMDrawSpline!
    var drawColorWheel  : MMDrawColorWheel!
    var drawArc         : MMDrawArc!

    // --- Fonts
    var openSans        : MMFont!
    var gameCuben       : MMFont!
    var square          : MMFont!

    var defaultFont     : MMFont!

    // --- Skin
    var skin            : MMSkin!
    
    // --- Animations
    var animate         : [MMAnimate] = []
    
    // --- Widget References
    var widgetIdCounter : Int!

    var maxFramerateLocks: Int = 0
    var maxHardLocks    : Int = 0
    
    // --- Drawing
    
    var delayedDraws    : [MMWidget] = []
    var icons           : [String:MTLTexture] = [:]

    // ---
    
    func startup() {
        animate = []
        //super.init()
        
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
//        print("My GPU is: \(defaultDevice)")
        device = defaultDevice
        platformInit()

        guard let tempRenderer = MMRenderer( self ) else {
            print("MMRenderer failed to initialize")
            return
        }
        
        enableSetNeedsDisplay = true
        isPaused = true
        
        renderer = tempRenderer
        textureLoader = MTKTextureLoader( device: defaultDevice )
        delegate = renderer
        
        hoverWidget = nil
        focusWidget = nil
        widgetIdCounter = 0
        skin = MMSkin()
        
        // Fonts
        openSans = MMFont( self, name: "OpenSans" )
        //gameCuben = MMFont( self, name: "GameCuben" )
        //square = MMFont( self, name: "Square" )
        
        defaultFont = square

        // --- Drawables
        drawSphere = MMDrawSphere( renderer )
        drawBox = MMDrawBox( renderer )
        drawBoxPattern = MMDrawBoxPattern( renderer )
        drawBoxGradient = MMDrawBoxGradient( renderer )
        drawBoxedMenu = MMDrawBoxedMenu( renderer )
        drawBoxedShape = MMDrawBoxedShape( renderer )
        drawTexture = MMDrawTexture( renderer )
        drawText = MMDrawText( renderer )
        drawCustomState = MMDrawCustomState( renderer )
        drawLine = MMDrawLine( renderer )
        drawSpline = MMDrawSpline( renderer )
        drawColorWheel = MMDrawColorWheel( renderer )
        drawArc = MMDrawArc( renderer )
    }
    
    /// Build the user interface for this view. Called for each frame inside the renderer.
    func build()
    {
        // --- Animations
        
        var newAnimate : [MMAnimate] = []
        for anim in animate {
            anim.tick()
            if !anim.finished {
                newAnimate.append( anim )
            } else {
                unlockFramerate()
            }
        }
        animate = newAnimate
        
        // ---
        
//        print( renderer.cWidth, renderer.cHeight )
        delayedDraws = []
        let rect = MMRect( 1, 0, renderer.cWidth - 1, renderer.cHeight )
        if let region = topRegion {
            region.rect.x = 0
            region.rect.y = 0
            region.rect.width = renderer.cWidth
            region.build()
            
            rect.y += region.rect.height
            rect.height -= region.rect.height + 1
        }
        
        if let region = leftRegion {
            region.rect.x = rect.x
            region.rect.y = rect.y
            region.rect.height = rect.height
            region.build()
            
            rect.x += region.rect.width
            rect.width -= region.rect.width
        }
        
        if let region = bottomRegion {
            region.rect.x = rect.x
            region.rect.y = rect.y
            region.rect.width = rect.width
            region.build()
            
            rect.height -= region.rect.height + 1
        }

        if let region = rightRegion {
            region.rect.copy( rect )
            region.build()
            
            rect.width -= region.rect.width
        }
        
        if let region = editorRegion {
            region.rect.copy( rect )
            region.build()
        }
        
        // --- Drag and drop ?
        if dragSource != nil {
            if let widget = dragSource!.previewWidget {
                widget.rect.x = mousePos.x - dragSource!.pWidgetOffset!.x
                widget.rect.y = mousePos.y - dragSource!.pWidgetOffset!.y
                widget.draw()
            }
        }
        
        // --- Dialog
        
        if let dialog = self.dialog {
            dialog.rect.x = dialogXPos
            dialog.rect.y = dialogYPos
            dialog.draw()
        }
        
        // --- Delayed Draws
        for widget in delayedDraws {
            widget.draw()
        }
    }
    
    /// Register the widget to the view
    func registerWidget(_ widget : MMWidget)
    {
        var found: Bool = false
        for w in widgets {
            if w === widget {
                found = true
                break
            }
        }
        
        if found == false {
            widgets.append( widget )
        }
    }
    
    /// Register the widget to the view at a given position
    func registerWidgetAt(_ widget : MMWidget, at: Int = 0)
    {
        var found: Bool = false
        for w in widgets {
            if w === widget {
                found = true
                break
            }
        }
        
        if found == false {
            widgets.insert(widget, at: at)
        }
    }
    
    func registerWidgets( widgets: MMWidget... )
    {
        for widget in widgets {
            registerWidget(widget)
        }
    }
    
    /// Deregister the widget from the view
    func deregisterWidget(_ widget : MMWidget)
    {
        widgets.removeAll(where: { $0 == widget })
    }
    
    func deregisterWidgets( widgets: MMWidget... )
    {
        for widget in widgets {
            deregisterWidget(widget)
        }
    }
    
    /// Gets a uniquge id for your widget
    func getWidgetId() -> Int
    {
        widgetIdCounter += 1
        return widgetIdCounter
    }
    
    /// Creates a MTLTexture from the given resource
    func loadTexture(_ name: String ) -> MTLTexture?
    {
        let path = Bundle.main.path(forResource: name, ofType: "tiff")!
        let data = NSData(contentsOfFile: path)! as Data
        
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : false]
        
        return try? textureLoader.newTexture(data: data, options: options)
    }

    /// Registers an icon texture of the given name in the icons dictionary
    @discardableResult func registerIcon(_ name: String) -> MTLTexture?
    {
        if let texture = loadTexture(name) {
            icons[name] = texture
            return texture
        }
        return nil
    }
    
    /// Initiate a drag operation
    func dragStarted(source: MMDragSource )
    {
        dragSource = source
        lockFramerate()
    }

    /// Increases the counter which locks the framerate at the max
    func lockFramerate(_ hard: Bool = false)
    {
        maxFramerateLocks += 1
        isPaused = false
        if hard {
            maxHardLocks += 1
            print("hard locked")
        }
        print( "max framerate" )
    }
    
    /// Decreases the counter which locks the framerate and sets it back to the default rate when <= 0
    func unlockFramerate(_ hard: Bool = false)
    {
        maxFramerateLocks -= 1
        if hard {
            maxHardLocks -= 1
        }
        if maxFramerateLocks <= 0 && maxHardLocks <= 0 {
            isPaused = true
            maxFramerateLocks = 0
            maxHardLocks = 0
            print( "framerate back to default" )
        }
    }

    /// Start animation
    func startAnimate(startValue: Float, endValue: Float, duration: Float, cb:@escaping (Float, Bool)->())
    {
        let anim = MMAnimate(startValue: startValue, endValue: endValue, duration: duration, cb: cb)
        animate.append(anim)
        lockFramerate()
    }
    
    ///
    func showDialog(_ dialog: MMDialog)
    {
        self.dialog = dialog
        dialogXPos = (renderer.cWidth - dialog.rect.width) / 2
        dialogYPos = -dialog.rect.height
        
        widgetsBackup = widgets
        widgets = dialog.widgets
        
        startAnimate( startValue: dialogYPos, endValue: 0, duration: 500, cb: { (value,finished) in
            self.dialogYPos = value
            if finished {
                dialog.scrolledIn()
            }
        } )
    }
}
