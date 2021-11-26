//
//  MMColorWidget.swift
//  Framework
//
//  Created by Markus Moenig on 04/7/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import MetalKit
import simd

class MMColorPopupWidget : MMWidget
{
    var value       : float4
    var mouseIsDown : Bool = false
    
    var changed     : ((_ value: float4, _ continuous: Bool)->())?
    
    var h           : Float = 0
    var s           : Float = 0
    var l           : Float = 0
    
    var ls1Pt       : float2 = float2(0,0)
    var ls2Pt       : float2 = float2(0,0)
    var ls3Pt       : float2 = float2(0,0)

    var hueDot      : float2 = float2(0,0)
    var slDot       : float2 = float2(0,0)
    
    var insideOp    : Bool = false
    
    let hexLabel    : MMTextLabel
    var hexHover    : Bool = false

    init(_ view: MMView, value: float4 = float4(0.5, 0.5, 0.5, 1))
    {
        self.value = value
        
        hexLabel = MMTextLabel(view, font: view.openSans, text: toHex(SIMD3<Float>(value.x, value.y, value.z)), scale: 0.4)

        super.init(view)
        
        name = "MMColorWidget"
        
        rect.width = 30
        rect.height = 28

        setValue(color: SIMD3<Float>(value.x, value.y, value.z))
    }
    
    func setState(_ state: MMWidgetStates)
    {
        if state == .Closed {
            rect.width = 30
            rect.height = 28
            removeState(.Opened)
        } else {
            rect.width = 230
            rect.height = 170 + 30
            addState(.Opened)
        }
    }
    
    func setValue(color: SIMD3<Float>)
    {
        self.value = SIMD4<Float>(color.x, color.y, color.z, 1)

        let hsl = toHSL(color.x, color.y, color.z)
        h = hsl.0 * 360
        s = hsl.1
        l = hsl.2

        computePoints()
        hexLabel.setText(toHex(SIMD3(value.x, value.y, value.z)))
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        if hexHover {
            let oldValue = hexLabel.text
            getStringDialog(view: mmView, title: "Color Value", message: "Enter new value", defaultValue: hexLabel.text, cb: { (string) -> Void in
                self.setValue(color: fromHex(hexString: string))
                self.mmView.update()
                if oldValue != string {
                    self.changed!(self.value, false)
                }
            } )
            return
        }
        mouseIsDown = true
        
        calcColor(event, true, true)
        
        mmView.lockFramerate()
        mmView.mouseTrackWidget = self
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
        if mouseIsDown {
            mouseIsDown = false
            
            calcColor(event, false)

            mmView.unlockFramerate()
            mmView.mouseTrackWidget = nil
        }
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
        let oldHexHover = hexHover
        if hexLabel.rect.contains(event.x, event.y) {
            hexHover = true
        } else {
            hexHover = false
        }
        if oldHexHover != hexHover {
            mmView.update()
        }
        
        if mouseIsDown {
            calcColor(event, true)
        }
    }
    
    func computePoints()
    {
        let circleSize : Float = 150
        
        let center : float2 = float2(circleSize/2,circleSize/2)
        var angle : Float = (h - 180) * Float.pi / 180
        var dir : float2 = float2(sin(angle), cos(angle))

        dir = simd_normalize(dir)
        
        var ldir : float2 = dir
        ldir *= circleSize/2 - 10
        
        hueDot = center + ldir
        
        ldir = dir
        ldir *= circleSize/2 - 20
        
        ls2Pt = center + ldir
        
        angle = (h - 180 - 120) * Float.pi / 180
        dir = float2(sin(angle), cos(angle))
        dir = simd_normalize(dir)
        dir *= circleSize/2 - 20
        ls1Pt = center + dir

        angle = (h - 180 + 120) * Float.pi / 180
        dir = float2(sin(angle), cos(angle))
        dir = simd_normalize(dir)
        dir *= circleSize/2 - 20
        ls3Pt = center + dir
        
        let base : float2 = (ls3Pt - ls1Pt) * l
        let up : float2 = ((ls3Pt + ls1Pt) * -0.5) + ls2Pt
        let temp : Float = ((l < 0.5 ? l : 1 - l) * 2.0 * s )
        slDot = base + up * temp + ls1Pt
    }
    
    func calcColor(_ event: MMMouseEvent, _ continuous: Bool, _ newOp : Bool = false)
    {
        if newOp {
            let x : Float = event.x - rect.x - 10
            let y : Float = event.y - rect.y - 10
            
            //if x < 0 || x > 150 { return }
            //if y < 0 || y > 150 { return }
            
            let circleSize : Float = 150
            
            let center : float2 = float2(circleSize/2,circleSize/2)
            
            let dist = simd_distance(center, float2(x,y))
            if dist >= 55 {
                insideOp = false
            } else {
                insideOp = true
            }
        }
        
        if !insideOp {
            getHueAt(event, continuous)
            computePoints()
        } else {
            getSLAt(event, continuous)
            computePoints()
        }
    }
    
    func getSLAt(_ event: MMMouseEvent, _ continuous: Bool)
    {
        let x : Float = event.x - rect.x - 10
        let y : Float = event.y - rect.y - 10
        
        if x < 0 || x > 150 { return }
        if y < 0 || y > 150 { return }
        
        func signOf(_ p1 : float2,_ p2 : float2,_ p3 : float2) -> Float
        {
            return (p2.x-p1.x) * (p3.y-p1.y) - (p2.y-p1.y) * (p3.x-p1.x);
        }
        
        func limit(_ v : Float) -> Float
        {
            if v<0 { return 0 }
            if v>1 { return 1 }
            return v
        }
        
        var ev : float2 = float2(x,y)
        
        let b1 : Bool = signOf(ev, ls1Pt, ls2Pt) <= 0
        let b2 : Bool = signOf(ev, ls2Pt, ls3Pt) <= 0
        let b3 : Bool = signOf(ev, ls3Pt, ls1Pt) <= 0
        
        var fail : Bool = false
        // in this case coordinate axis is clockwise
        if b1 && b2 && b3 { // inside triangle
            ev -= ls1Pt
        } else if(b2 && b3) {
            let line = ls2Pt - ls1Pt
            ev -= ls1Pt
            ev = line * limit(dot(line,ev)/(length(line)*length(line)))
        } else
        if b1 && b2 {
            let line = ls3Pt - ls1Pt
            ev -= ls1Pt
            ev = line * limit(dot(line,ev)/(length(line)*length(line)))
        } else
        if b1 && b3 {
            let line = ls2Pt - ls3Pt
            ev -= ls3Pt
            ev = line * limit(dot(line,ev)/(length(line)*length(line)))
            ev += ls3Pt - ls1Pt
        } else {
            fail = true
        }

        if !fail {
            let p3 : float2 = ls3Pt - ls1Pt
            let side : Float = length(p3)
            l = dot(ev, p3) / (side * side)
            if l > 0.01 && l < 0.99 {
                let up : float2 = ((ls3Pt + ls1Pt) * -0.5) + ls2Pt
                let temp : Float = l < 0.5 ? l : 1 - l
                s = dot(ev, up) / length(up) / length(up) * 0.5 / temp
            }
            let rgb = toRGB(h, s, l)
            value.x = rgb.0
            value.y = rgb.1
            value.z = rgb.2
            hexLabel.setText(toHex(SIMD3(value.x, value.y, value.z)))
            if changed != nil {
                changed!(value,continuous)
            }
        }
    }
    
    func getHueAt(_ event: MMMouseEvent, _ continuous: Bool)
    {
        let x : Float = event.x - rect.x - 10
        let y : Float = event.y - rect.y - 10
        
        //if x < 0 || x > 150 { return }
        //if y < 0 || y > 150 { return }
        
        let hsv = toHSL(value.x, value.y, value.z)
        
        let circleSize : Float = 150
        
        let center : float2 = float2(circleSize/2,circleSize/2)
        var mouse : float2 = float2(x - center.x, y - center.y)
        
        mouse = simd_normalize(mouse)
        
        mouse *= circleSize/2 - (circleSize*0.75)/2
        let v : float2 = center + mouse
        let angle : Float = atan2(v.x - center.x, v.y - center.y) * 180 / Float.pi
        let rgb = toRGB(angle + 180, hsv.1, hsv.2)
        h = angle + 180
        value.x = rgb.0
        value.y = rgb.1
        value.z = rgb.2
        hexLabel.setText(toHex(SIMD3(value.x, value.y, value.z)))
        if changed != nil {
            changed!(value,continuous)
        }
    }
    
    override func draw(xOffset: Float = 0, yOffset: Float = 0)
    {
        if !states.contains(.Opened) {
            mmView.drawBox.draw(x: rect.x, y: rect.y, width: rect.width, height: rect.height, round: 2, borderSize: 2, fillColor: value, borderColor: float4(0, 0, 0, 1))
        } else {
            mmView.drawBox.draw(x: rect.x, y: rect.y, width: rect.width, height: rect.height, round: 2, borderSize: 2, fillColor: float4(0.145, 0.145, 0.145, 1), borderColor: float4(0, 0, 0, 1))
            
            mmView.drawColorWheel.draw(x: rect.x + 10, y: rect.y + 10, width: 150, height: 150, color: float4(h,s,l,1))
            
            mmView.drawBox.draw(x: rect.x + rect.width - 60, y: rect.y + 10, width: 50, height: rect.height - 20, round: 2, borderSize: 2, fillColor: value, borderColor: float4(0, 0, 0, 1))
            
            mmView.drawSphere.draw(x: rect.x + hueDot.x + 5, y: rect.y + hueDot.y + 5, radius: 6, borderSize: 0, fillColor: float4(0, 0, 0, 1), borderColor: float4(0, 0, 0, 0))
            
            mmView.drawSphere.draw(x: rect.x + slDot.x + 5, y: rect.y + slDot.y + 5, radius: 6, borderSize: 0, fillColor: float4(0, 0, 0, 1), borderColor: float4(0, 0, 0, 0))
            
            hexLabel.rect.x = rect.x + 15
            hexLabel.rect.y = rect.y + rect.height - 28
            hexLabel.color = hexHover ? SIMD4<Float>(1,1,1,1) : SIMD4<Float>(0.8,0.8,0.8,1)
            hexLabel.draw()
        }
    }
}


class MMColorWidget : MMWidget
{
    var value       : SIMD3<Float>
    var mouseIsDown : Bool = false
    
    var changed     : ((_ value: SIMD3<Float>, _ continuous: Bool)->())?
    
    var h           : Float = 0
    var s           : Float = 0
    var l           : Float = 0
    
    var ls1Pt       : float2 = float2(0,0)
    var ls2Pt       : float2 = float2(0,0)
    var ls3Pt       : float2 = float2(0,0)
    
    var hueDot      : float2 = float2(0,0)
    var slDot       : float2 = float2(0,0)
    
    var dotSize     : Float = 0
    var insideOp    : Bool = false
    
    var lastSize    : float2 = float2(0,0)
    
    init(_ view: MMView, value: SIMD3<Float> = SIMD3<Float>(0.5, 0.5, 0.5))
    {
        self.value = value
        super.init(view)
        
        let hsl = toHSL(value.x, value.y, value.z)
        h = hsl.0 * 360
        s = hsl.1
        l = hsl.2
        
        name = "MMColorWidget"
        
        computePoints()
    }
    
    func setValue(color: SIMD3<Float>)
    {
        self.value = color

        let hsl = toHSL(color.x, color.y, color.z)
        h = hsl.0 * 360
        s = hsl.1
        l = hsl.2

        computePoints()
    }
    
    override func mouseDown(_ event: MMMouseEvent)
    {
        mouseIsDown = true
        
        calcColor(event, true, true)
        
        mmView.lockFramerate()
        mmView.mouseTrackWidget = self
    }
    
    override func mouseUp(_ event: MMMouseEvent)
    {
        if mouseIsDown {
            mouseIsDown = false
            
            calcColor(event, false)
            
            mmView.unlockFramerate()
            mmView.mouseTrackWidget = nil
        }
    }
    
    override func mouseMoved(_ event: MMMouseEvent)
    {
        if mouseIsDown {
            calcColor(event, true)
        }
    }
    
    func computePoints()
    {
        let circleSize : Float = rect.width
        
        let center : float2 = float2(circleSize/2,circleSize/2)
        var angle : Float = (h - 180) * Float.pi / 180
        var dir : float2 = float2(sin(angle), cos(angle))
        
        dir = simd_normalize(dir)
        
        let sub : Float = dotSize * 1.4
        
        var ldir : float2 = dir
        ldir *= circleSize/2 - dotSize * 1.4
        
        hueDot = center + ldir - dotSize
        
        ldir = dir
        ldir *= circleSize/2 - sub * 2
        
        ls2Pt = center + ldir - dotSize
        
        angle = (h - 180 - 120) * Float.pi / 180
        dir = float2(sin(angle), cos(angle))
        dir = simd_normalize(dir)
        dir *= circleSize/2 - sub * 2
        ls1Pt = center + dir - dotSize
        
        angle = (h - 180 + 120) * Float.pi / 180
        dir = float2(sin(angle), cos(angle))
        dir = simd_normalize(dir)
        dir *= circleSize/2 - sub * 2
        ls3Pt = center + dir - dotSize
        
        let base : float2 = (ls3Pt - ls1Pt) * l
        let up : float2 = ((ls3Pt + ls1Pt) * -0.5) + ls2Pt
        let temp : Float = ((l < 0.5 ? l : 1 - l) * 2.0 * s )
        slDot = base + up * temp + ls1Pt
    }
    
    func calcColor(_ event: MMMouseEvent, _ continuous: Bool, _ newOp : Bool = false)
    {
        if newOp {
            let x : Float = event.x - rect.x
            let y : Float = event.y - rect.y
            
            //if x < 0 || x > 150 { return }
            //if y < 0 || y > 150 { return }
            
            let circleSize : Float = rect.width
            
            let center : float2 = float2(circleSize/2,circleSize/2)
            
            let dist = simd_distance(center, float2(x,y))
            if dist >= (rect.width * 0.75) / 2 {
                insideOp = false
            } else {
                insideOp = true
            }
        }
        
        if !insideOp {
            getHueAt(event, continuous)
            computePoints()
        } else {
            getSLAt(event, continuous)
            computePoints()
        }
    }
    
    func getSLAt(_ event: MMMouseEvent, _ continuous: Bool)
    {
        let x : Float = event.x - rect.x
        let y : Float = event.y - rect.y
        
        if x < 0 || x > rect.width { return }
        if y < 0 || y > rect.width { return }
        
        func signOf(_ p1 : float2,_ p2 : float2,_ p3 : float2) -> Float
        {
            return (p2.x-p1.x) * (p3.y-p1.y) - (p2.y-p1.y) * (p3.x-p1.x);
        }
        
        func limit(_ v : Float) -> Float
        {
            if v<0 { return 0 }
            if v>1 { return 1 }
            return v
        }
        
        var ev : float2 = float2(x,y)
        
        let b1 : Bool = signOf(ev, ls1Pt, ls2Pt) <= 0
        let b2 : Bool = signOf(ev, ls2Pt, ls3Pt) <= 0
        let b3 : Bool = signOf(ev, ls3Pt, ls1Pt) <= 0
        
        var fail : Bool = false
        // in this case coordinate axis is clockwise
        if b1 && b2 && b3 { // inside triangle
            ev -= ls1Pt
        } else if(b2 && b3) {
            let line = ls2Pt - ls1Pt
            ev -= ls1Pt
            ev = line * limit(dot(line,ev)/(length(line)*length(line)))
        } else
            if b1 && b2 {
                let line = ls3Pt - ls1Pt
                ev -= ls1Pt
                ev = line * limit(dot(line,ev)/(length(line)*length(line)))
            } else
                if b1 && b3 {
                    let line = ls2Pt - ls3Pt
                    ev -= ls3Pt
                    ev = line * limit(dot(line,ev)/(length(line)*length(line)))
                    ev += ls3Pt - ls1Pt
                } else {
                    fail = true
        }
        
        if !fail {
            let p3 : float2 = ls3Pt - ls1Pt
            let side : Float = length(p3)
            l = dot(ev, p3) / (side * side)
            if l > 0.01 && l < 0.99 {
                let up : float2 = ((ls3Pt + ls1Pt) * -0.5) + ls2Pt
                let temp : Float = l < 0.5 ? l : 1 - l
                s = dot(ev, up) / length(up) / length(up) * 0.5 / temp
            }
            let rgb = toRGB(h, s, l)
            value.x = rgb.0
            value.y = rgb.1
            value.z = rgb.2
            if changed != nil {
                changed!(value,continuous)
            }
        }
    }
    
    func getHueAt(_ event: MMMouseEvent, _ continuous: Bool)
    {
        let x : Float = event.x - rect.x
        let y : Float = event.y - rect.y
        
        //if x < 0 || x > 150 { return }
        //if y < 0 || y > 150 { return }
        
        let hsv = toHSL(value.x, value.y, value.z)
        
        let circleSize : Float = rect.width
        
        let center : float2 = float2(circleSize/2,circleSize/2)
        var mouse : float2 = float2(x - center.x, y - center.y)
        
        mouse = simd_normalize(mouse)
        
        mouse *= circleSize/2 - (circleSize*0.75)/2
        let v : float2 = center + mouse
        let angle : Float = atan2(v.x - center.x, v.y - center.y) * 180 / Float.pi
        let rgb = toRGB(angle + 180, hsv.1, hsv.2)
        h = angle + 180
        value.x = rgb.0
        value.y = rgb.1
        value.z = rgb.2
        if changed != nil {
            changed!(value,continuous)
        }
    }
    
    override func draw(xOffset: Float = 0, yOffset: Float = 0)
    {
        dotSize = rect.width / 20
        if lastSize.x != rect.width || lastSize.y != rect.height {
            lastSize.x = rect.width
            lastSize.y = rect.height
            computePoints()
        }
        mmView.drawColorWheel.draw(x: rect.x, y: rect.y, width: rect.width, height: rect.height, color: float4(h,s,l, isDisabled ? mmView.skin.disabledAlpha : 1))
        
        if !isDisabled {
            mmView.drawSphere.draw(x: rect.x + hueDot.x, y: rect.y + hueDot.y, radius: dotSize, borderSize: 0, fillColor: float4(0, 0, 0, 1), borderColor: float4(0, 0, 0, 0))
            mmView.drawSphere.draw(x: rect.x + slDot.x, y: rect.y + slDot.y, radius: dotSize, borderSize: 0, fillColor: float4(0, 0, 0, 1), borderColor: float4(0, 0, 0, 0))
        } else {
            mmView.drawSphere.draw(x: rect.x + hueDot.x, y: rect.y + hueDot.y, radius: dotSize, borderSize: 0, fillColor: float4(0, 0, 0, mmView.skin.disabledAlpha), borderColor: float4(0, 0, 0, 0))
            mmView.drawSphere.draw(x: rect.x + slDot.x, y: rect.y + slDot.y, radius: dotSize, borderSize: 0, fillColor: float4(0, 0, 0, mmView.skin.disabledAlpha), borderColor: float4(0, 0, 0, 0))
        }
    }
}

