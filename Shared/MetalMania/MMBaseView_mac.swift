//
//  MMBaseView_mac.swift
//  Framework
//
//  Created by Markus Moenig on 10/1/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit

public class MMBaseView : MTKView
{
    var trackingArea    : NSTrackingArea?

    var widgets         = [MMWidget]()
    var hoverWidget     : MMWidget?
    var focusWidget     : MMWidget?
    
    var dialog          : MMDialog? = nil
    var widgetsBackup   : [MMWidget] = []
    var dialogXPos      : Float = 0
    var dialogYPos      : Float = 0

    var scaleFactor     : Float!
    
    var mousePos        : float2 = float2()
    
    var mouseTrackWidget: MMWidget? = nil

    // --- Drag And Drop
    var dragSource      : MMDragSource? = nil
    
    // --- Key States
    var shiftIsDown     : Bool = false
    var commandIsDown   : Bool = false
    
    var keysDown        : [Float] = []
    
    // For pinch gesture
    var zoom            : Float = 1

    func update()
    {
        let rect : NSRect = NSRect()
        setNeedsDisplay(rect)
    }
    
    func platformInit()
    {
        scaleFactor = Float(NSScreen.main!.backingScaleFactor)
    }
    
    override public var acceptsFirstResponder: Bool { return true }

    override public func updateTrackingAreas()
    {
        if trackingArea != nil {
            self.removeTrackingArea(trackingArea!)
        }
        let options : NSTrackingArea.Options =
            [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow]
        trackingArea = NSTrackingArea(rect: self.bounds, options: options,
                                      owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }
    
    /// Mouse has been clicked
    override public func mouseDown(with event: NSEvent) {
        var location = event.locationInWindow
        
        location.y = location.y - CGFloat(frame.height)
        location = convert(location, from: nil)
        
        mousePos.x = Float(location.x)
        mousePos.y = -Float(location.y)
        
        let event = MMMouseEvent(mousePos.x, mousePos.y)
        
        if mouseTrackWidget != nil {
            mouseTrackWidget!.mouseDown(event)
        } else
        if hoverWidget != nil {
            
            if focusWidget != nil {
                focusWidget!.removeState( .Focus )
            }
            
            focusWidget = hoverWidget
            focusWidget!.addState( .Clicked )
            focusWidget!.addState( .Focus )
            focusWidget!._clicked(event)
            focusWidget!.mouseDown(event)
        }
    }
    
    override public func mouseUp(with event: NSEvent) {
        var location = event.locationInWindow
        
        location.y = location.y - CGFloat(frame.height)
        location = convert(location, from: nil)
        
        mousePos.x = Float(location.x)
        mousePos.y = -Float(location.y)
        
        let event = MMMouseEvent(mousePos.x, mousePos.y)

        if mouseTrackWidget != nil {
            mouseTrackWidget!.mouseUp(event)
        }
        
        // --- Drag and Drop
        if hoverWidget != nil && dragSource != nil {
            if hoverWidget!.dropTargets.contains(dragSource!.id) {
                hoverWidget!.dragEnded(event: event, dragSource: dragSource!)
                focusWidget = hoverWidget
                update()
            }
        }
        
        if dragSource != nil {
            dragSource!.sourceWidget?.dragTerminated()
            dragSource = nil
            update()
            if let widget = focusWidget {
                widget.removeState( .Clicked )
            }
            return // To prevent mouseUp event
        }
        // ---
        
        if let widget = focusWidget {
            widget.removeState( .Clicked )
            widget.mouseUp(event)
        }
    }
    
    /// Mouse has moved
    override public func mouseMoved(with event: NSEvent) {
        
        var location = event.locationInWindow
        
        location.y = location.y - CGFloat(frame.height)
        location = convert(location, from: nil)
        
        mousePos.x = Float(location.x)
        mousePos.y = -Float(location.y)
        
        let event = MMMouseEvent(mousePos.x, mousePos.y)
                
        //mousePos.x = event.x
        //mousePos.y = event.y
        
        print(mousePos.x, mousePos.y)
        
//        if hoverWidget != nil {
//            hoverWidget!.removeState(.Hover)
//            hoverWidget!.mouseLeave(event)
//        }
        
        if let mouseTrackWidget = mouseTrackWidget {
            mouseTrackWidget.mouseMoved(event)
        } else {
            let oldHoverWidget = hoverWidget
            hoverWidget = nil

            for widget in widgets {
                if widget.rect.contains( event.x, event.y ) {
                    hoverWidget = widget
                    if hoverWidget !== oldHoverWidget {
                        hoverWidget!.addState(.Hover)
                        hoverWidget!.mouseEnter(event)
                    }
                    hoverWidget!.mouseMoved(event)
                    break;
                }
            }
            
            if oldHoverWidget !== hoverWidget {
                if oldHoverWidget != nil {
                    oldHoverWidget!.removeState(.Hover)
                    oldHoverWidget!.mouseLeave(event)
                }
            }
        }
    }
    
    override public func mouseDragged(with event: NSEvent) {
        mouseMoved(with: event)
    }
    
    // Mouse scroll wheel
    override public func scrollWheel(with event: NSEvent) {
        var location = event.locationInWindow
        
        location.y = location.y - CGFloat(frame.height)
        location = convert(location, from: nil)
        
        let mousePosX = Float(location.x)
        let mousePosY = -Float(location.y)
        
        let scrollEvent = MMMouseEvent(mousePosX, mousePosY)
        scrollEvent.deltaX = Float(event.deltaX)
        scrollEvent.deltaY = Float(event.deltaY)
        scrollEvent.deltaZ = Float(event.deltaZ)
                
        if let widget = hoverWidget {
            widget.mouseScrolled(scrollEvent)
        }
    }
    
    /// Zoom
    override public func magnify(with event: NSEvent) {
        if let hover = hoverWidget {
            if(event.phase == .changed) {
                zoom += Float(event.magnification)
            } else
            if(event.phase == .began) {
                zoom = 1
            }
            hover.pinchGesture(zoom, true)
        }
    }
    
    // Currently only used for checking modifier keys
    
    override public func keyDown(with event: NSEvent)
    {
        keysDown.append(Float(event.keyCode))
        if focusWidget != nil {
            let keyEvent = MMKeyEvent(event.characters, event.keyCode)
            focusWidget!.keyDown(keyEvent)
        }
        //super.keyDown(with: event)
    }
    
    override public func keyUp(with event: NSEvent)
    {
        keysDown.removeAll{$0 == Float(event.keyCode)}
        if focusWidget != nil {
            let keyEvent = MMKeyEvent(event.characters, event.keyCode)
            focusWidget!.keyUp(keyEvent)
        }
        //super.keyUp(with: event)
    }
    
    override public func flagsChanged(with event: NSEvent) {
        //https://stackoverflow.com/questions/9268045/how-can-i-detect-that-the-shift-key-has-been-pressed
        if event.modifierFlags.contains(.shift) {
            shiftIsDown = true
        } else {
            shiftIsDown = false
        }
        
        if event.modifierFlags.contains(.command) {
            commandIsDown = true
        } else {
            commandIsDown = false
        }
    }
}

func getStringDialog(view: MMView, title: String, message: String, defaultValue: String, cb: @escaping (String)->())
{
    let msg = NSAlert()
    msg.addButton(withTitle: "OK")      // 1st button
    msg.addButton(withTitle: "Cancel")  // 2nd button
    msg.messageText = title
    msg.informativeText = message
    
    let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    txt.stringValue = defaultValue
    
    msg.window.initialFirstResponder = txt
    msg.accessoryView = txt
//    let response: NSApplication.ModalResponse = msg.runModal()
    
//    if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
//        cb( txt.stringValue )
//    }
    
    msg.beginSheetModal(for: view.window!, completionHandler: { (modalResponse) -> Void in
        if modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn {
            cb(txt.stringValue)
        }
    })
}

func getNumberDialog(view: MMView, title: String, message: String, defaultValue: Float, cb: @escaping (Float)->())
{
    let msg = NSAlert()
    msg.addButton(withTitle: "OK")      // 1st button
    msg.addButton(withTitle: "Cancel")  // 2nd button
    msg.messageText = title
    msg.informativeText = message
    
    func roundTo(value: Float, places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (Double(value) * divisor).rounded() / divisor
    }
    
    let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    txt.doubleValue = roundTo(value: defaultValue, places: 2)
    
    msg.window.initialFirstResponder = txt
    msg.accessoryView = txt
    //    let response: NSApplication.ModalResponse = msg.runModal()
    
    //    if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
    //        cb( txt.stringValue )
    //    }
    
    msg.beginSheetModal(for: view.window!, completionHandler: { (modalResponse) -> Void in
        if modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn {
            cb(Float(txt.doubleValue))
        }
    })
}

func getSampleProject(view: MMView, title: String, message: String, sampleProjects: [String], cb: @escaping (Int)->())
{
    let msg = NSAlert()
    msg.addButton(withTitle: "OK")      // 1st button
    msg.messageText = title
    msg.informativeText = message
    
    let popUp = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
//    txt.stringValue = defaultValue
    popUp.addItems(withTitles: sampleProjects)
    
    msg.window.initialFirstResponder = popUp
    msg.accessoryView = popUp
    //    let response: NSApplication.ModalResponse = msg.runModal()
    
    //    if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
    //        cb( txt.stringValue )
    //    }
    
    msg.beginSheetModal(for: view.window!, completionHandler: { (modalResponse) -> Void in
        if modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn {
            cb(popUp.indexOfSelectedItem)
        }
    })
}

func askUserToSave(view: MMView, cb: @escaping (Bool)->())
{
    let question = NSLocalizedString("You have unsaved changes. Continue anyway?", comment: "Quit without saves error question message")
    let info = NSLocalizedString("Continuing now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
    let continueButton = NSLocalizedString("Continue", comment: "Continue button title")
    let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
    let alert = NSAlert()
    alert.messageText = question
    alert.informativeText = info
    alert.addButton(withTitle: continueButton)
    alert.addButton(withTitle: cancelButton)
    
    let answer = alert.runModal()
    if answer == .alertSecondButtonReturn {
        cb(false)
        return
    }
    cb(true)
}

/// Show help window
func showHelp(_ urlString: String? = nil)
{
    /*
    let appDelegate = (NSApplication.shared.delegate as! AppDelegate)
    
    appDelegate.helpWindowController.showWindow(appDelegate)
    appDelegate.helpWindowController.window!.makeKeyAndOrderFront(appDelegate)
    
    let url = urlString != nil ? URL(string: urlString!) : URL(string: "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/5406721/Getting+Started")
    
    if appDelegate.webView.url != url {
        let request = URLRequest(url:url!)
        appDelegate.webView.load(request)
    }
     */
}
