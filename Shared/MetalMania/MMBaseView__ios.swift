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
    var widgets         = [MMWidget]()
    var hoverWidget     : MMWidget?
    var focusWidget     : MMWidget?
    
    var dialog          : MMDialog? = nil
    var widgetsBackup   : [MMWidget] = []
    var dialogXPos      : Float = 0
    var dialogYPos      : Float = 0

    var widgetForMouse  : MMWidget? = nil
    
    var lastX, lastY    : Float?
    
    var scaleFactor     : Float!
    
    var mousePos        : SIMD2<Float> = SIMD2<Float>()
    var mouseDownPos    : SIMD2<Float>!
    
    var mouseTrackWidget: MMWidget? = nil

    // --- Drag And Drop
    var dragSource      : MMDragSource? = nil

    // --- Key States
    var shiftIsDown     : Bool = false
    
    var firstTouch      : Bool = false
    var pinchCenter     : SIMD2<Float> = SIMD2<Float>(0,0)

    func update()
    {
        setNeedsDisplay()
    }
    
    func platformInit()
    {
        scaleFactor = Float(UIScreen.main.scale)
        mouseDownPos = SIMD2<Float>()
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action:(#selector(self.handlePanGesture(_:))))
        addGestureRecognizer(panRecognizer)
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:(#selector(self.handlePinchGesture(_:))))
        addGestureRecognizer(pinchRecognizer)
    }
    
    @objc func handlePinchGesture(_ recognizer: UIPinchGestureRecognizer)
    {
        if let hover = hoverWidget {
            hover.pinchGesture(Float(recognizer.scale), firstTouch)
            
            if let view = recognizer.view {
                if recognizer.state == .changed {
                    pinchCenter = SIMD2<Float>(Float(recognizer.location(in: view).x), Float(recognizer.location(in: view).y) )
                }
            }
            
            firstTouch = false
        }
    }
    
    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer)
    {
        let translation = recognizer.translation(in: self)
//        print( translation )
        
        if ( recognizer.state == .began ) {
            lastX = 0
            lastY = 0
        }
        
        let event = MMMouseEvent(Float(translation.x) + mouseDownPos.x, Float(translation.y) + mouseDownPos.y)
        
        let mmView : MMView = self as! MMView
        event.x /= Float(bounds.width) / mmView.renderer.cWidth
        event.y /= Float(bounds.height) / mmView.renderer.cHeight
        
        mousePos.x = event.x
        mousePos.y = event.y
        
        if mouseTrackWidget != nil {
            mouseTrackWidget!.mouseMoved(event)
        } else
        if hoverWidget != nil && dragSource == nil {
            
            if widgetForMouse == nil {
                widgetForMouse = hoverWidget
            }
            
            if widgetForMouse === hoverWidget {
            
                event.deltaX = Float(translation.x) - lastX!
                event.deltaY = Float(translation.y) - lastY!
                event.deltaZ = 0
                
                hoverWidget?.mouseScrolled(event)
                
                if recognizer.numberOfTouches > 1 {
                    // Only scroll when using with more than 1 finger
                    lastX = Float(translation.x)
                    lastY = Float(translation.y)
                    return
                }
            }
        }
        
        if ( recognizer.state == .ended ) {
            /*
            // 1
            let velocity = recognizer.velocity(in: self)
            let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
            let slideMultiplier = magnitude / 200
            print("magnitude: \(magnitude), slideMultiplier: \(slideMultiplier)")
            
            // 2
            let slideFactor = 0.1 * slideMultiplier     //Increase for more of a slide
            // 3
            var finalPoint = CGPoint(x:recognizer.view!.center.x + (velocity.x * slideFactor),
                                     y:recognizer.view!.center.y + (velocity.y * slideFactor))
            // 4
            finalPoint.x = min(max(finalPoint.x, 0), self.bounds.size.width)
            finalPoint.y = min(max(finalPoint.y, 0), self.bounds.size.height)
            */
            // 5
            /*
            UIView.animate(withDuration: Double(slideFactor * 2),
                           delay: 0,
                           // 6
                options: UIViewAnimationOptions.curveEaseOut,
                animations: {recognizer.view!.center = finalPoint },
                completion: nil)
            */
            
            // --- Drag and Drop
            if hoverWidget != nil && dragSource != nil {
                if hoverWidget!.dropTargets.contains(dragSource!.id) {
                    hoverWidget!.dragEnded(event: event, dragSource: dragSource!)
                    update()
                }
            }
            
            if dragSource != nil {
                dragSource!.sourceWidget?.dragTerminated()
                dragSource = nil
                update()
                if focusWidget != nil {
                    focusWidget!.removeState( .Clicked )
                }
                return
            }
            // ---
            
            if mouseTrackWidget != nil {
                mouseTrackWidget!.mouseUp(event)
            } else
            if focusWidget != nil {
                focusWidget!.removeState( .Clicked )
                focusWidget!.mouseUp(event)
            }
            
            hoverWidget = nil
            focusWidget = nil
        } else {
            /// Mouse Move event
        
            hoverWidget = nil
            for widget in widgets {
                if widget.rect.contains( event.x, event.y ) {
                    hoverWidget = widget
                    hoverWidget!.mouseMoved(event)
                    break;
                }
            }
            
            if focusWidget != nil {
                focusWidget!.mouseMoved(event)
            }
        }
        
        lastX = Float(translation.x)
        lastY = Float(translation.y)
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            let event = MMMouseEvent( Float(point.x), Float(point.y) )
            
            firstTouch = true
            
            let mmView : MMView = self as! MMView
            event.x /= Float(bounds.width) / mmView.renderer.cWidth
            event.y /= Float(bounds.height) / mmView.renderer.cHeight
            
            mouseDownPos.x = event.x
            mouseDownPos.y = event.y

            if hoverWidget != nil {
                hoverWidget!.removeState(.Hover)
            }
            
            if mouseTrackWidget != nil {
                mouseTrackWidget!.mouseDown(event)
            } else {
                widgetForMouse = nil
                for widget in widgets {
                    //            print( x, y, widget.rect.x, widget.rect.y, widget.rect.width, widget.rect.height )
                    if widget.rect.contains( event.x, event.y ) {
                        hoverWidget = widget
                        hoverWidget?.mouseDown(event)
    //                    hoverWidget!.addState(.Hover)
                        break;
                    }
                }
            }
            
            // ---
            
            if hoverWidget != nil {
                
                if focusWidget != nil {
                    focusWidget!.removeState( .Focus )
                }
                
                focusWidget = hoverWidget
                focusWidget!.addState( .Clicked )
//                focusWidget!.addState( .Focus )
                //focusWidget!._clicked(event)
                update()
            }
            
//            hoverWidget = nil
//            focusWidget = nil
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
//        if let touch = touches.first {
//            let currentPoint = touch.location(in: self)
//        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            let event = MMMouseEvent( Float(point.x), Float(point.y) )
            
            let mmView : MMView = self as! MMView
            event.x /= Float(bounds.width) / mmView.renderer.cWidth
            event.y /= Float(bounds.height) / mmView.renderer.cHeight
            
//            let x : Float = Float(currentPoint.x)
//            let y : Float = Float(currentPoint.y)
            
            // --- Drag and Drop
            if hoverWidget != nil && dragSource != nil {
                if hoverWidget!.dropTargets.contains(dragSource!.id) {
                    hoverWidget!.dragEnded(event: event, dragSource: dragSource!)
                }
            }
            
            if dragSource != nil {
                dragSource!.sourceWidget?.dragTerminated()
                dragSource = nil
            }
            // ---
            
            if mouseTrackWidget != nil {
                mouseTrackWidget!.mouseUp(event)
            } else
            if focusWidget != nil {
                focusWidget!.removeState( .Clicked )
                focusWidget!.mouseUp(event)
                focusWidget!._clicked(event)
            }
            hoverWidget = nil
            focusWidget = nil
        }
    }
}

func getStringDialog(view: MMView, title: String, message: String, defaultValue: String, cb: @escaping (String)->())
{
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    alert.addTextField(configurationHandler: { (textField) -> Void in
        textField.text = defaultValue
    })
    
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (action) -> Void in
        let textField = alert!.textFields![0] as UITextField
        //print("Text field: \(textField.text)")
        cb( textField.text! )
    }))
    
    if var topController = UIApplication.shared.keyWindow?.rootViewController {
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }

        topController.present(alert, animated: true, completion: nil)
    }
}

func getNumberDialog(view: MMView, title: String, message: String, defaultValue: Float, cb: @escaping (Float)->())
{
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    alert.addTextField(configurationHandler: { (textField) -> Void in
        textField.text = String(format: "%.02f", defaultValue)
        textField.keyboardType = UIKeyboardType.numberPad
    })
    
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (action) -> Void in
        let textField = alert!.textFields![0] as UITextField
        let number : Float? = Float(textField.text!)
        if number != nil {
            cb( number! )
        }
    }))
    
    if var topController = UIApplication.shared.keyWindow?.rootViewController {
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        topController.present(alert, animated: true, completion: nil)
    }
}

func getSampleProject(view: MMView, title: String, message: String, sampleProjects: [String], cb: @escaping (Int)->())
{
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
    for project in sampleProjects {
        alert.addAction(UIAlertAction(title: project, style: .default, handler: { (action) -> Void in
            cb( 0 )
        }))
    }
        
    if var topController = UIApplication.shared.keyWindow?.rootViewController {
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        topController.present(alert, animated: true, completion: nil)
    }
}

func askUserToSave(view: MMView, cb: @escaping (Bool)->())
{
    let alertController = UIAlertController(title: NSLocalizedString("You have unsaved changes. Continue anyway?", comment: "Continue without saves error question message"), message: NSLocalizedString("Continuing now will lose any changes you have made since the last successful save", comment: "Continue without saves error question info"), preferredStyle: UIAlertController.Style.alert)
    
    let continueButton = NSLocalizedString("Continue", comment: "Continue button title")
    let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
    
    let cancelAction: UIAlertAction = UIAlertAction(title: cancelButton,
                                                    style: .cancel,
                                                    handler: { (_) in
                                                        cb(false)
    } )
    
    let successAction: UIAlertAction = UIAlertAction(title: continueButton,
                                                     style: .default,
                                                     handler: { (_) in
                                                        cb(true)
    } )
    
    alertController.addAction(cancelAction)
    alertController.addAction(successAction)
    
    if var topController = UIApplication.shared.keyWindow?.rootViewController {
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        topController.present(alertController, animated: true, completion: nil)
    }
}

/// Open help in browser
func showHelp(_ urlString: String? = nil)
{
    if urlString != nil {
        guard let url = URL(string: urlString!) else { return }
        UIApplication.shared.open(url)
    } else {
        guard let url = URL(string: "https://moenig.atlassian.net/wiki/spaces/SHAPEZ/pages/5406721/Getting+Started") else { return }
        UIApplication.shared.open(url)
    }
}
