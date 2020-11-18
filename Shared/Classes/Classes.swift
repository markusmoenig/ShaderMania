//
//  Classes.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import Foundation

class Float4
{
    var x           : Float = 1
    var y           : Float = 1
    var z           : Float = 1
    var w           : Float = 1

    init(_ x: Float = 1,_ y: Float = 1,_ z: Float = 1,_ w: Float = 1)
    {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    func toSIMD() -> SIMD4<Float>
    {
        return SIMD4<Float>(x, y, z, w)
    }
    
    subscript(index: Int) -> Float {
        get {
            if index == 1 {
                return y
            } else
            if index == 2 {
                return z
            } else
            if index == 3 {
                return w
            } else {
                return x
            }
        }
    }
}

class Float3
{
    var x           : Float = 1
    var y           : Float = 1
    var z           : Float = 1

    init(_ x: Float = 1,_ y: Float = 1,_ z: Float = 1)
    {
        self.x = x
        self.y = y
        self.z = z
    }
    
    func toSIMD() -> SIMD3<Float>
    {
        return SIMD3<Float>(x, y, z)
    }
    
    subscript(index: Int) -> Float {
        get {
            if index == 1 {
                return y
            } else
            if index == 2 {
                return z
            } else {
                return x
            }
        }
    }
}

class Float2
{
    var x           : Float = 0
    var y           : Float = 0

    init(_ x: Float = 0,_ y: Float = 0)
    {
        self.x = x
        self.y = y
    }
    
    func toSIMD() -> SIMD2<Float>
    {
        return SIMD2<Float>(x, y)
    }
    
    subscript(index: Int) -> Float {
        get {
            if index == 1 {
                return y
            } else {
                return x
            }
        }
    }
}

class Float1
{
    var x           : Float = 0

    init(_ x: Float = 0)
    {
        self.x = x
    }
    
    func toSIMD() -> Float
    {
        return x
    }
}

class Int1
{
    var x           : Int = 0

    init(_ x: Int = 0)
    {
        self.x = x
    }
    
    func toSIMD() -> Int
    {
        return x
    }
}

class Bool1
{
    var x           : Bool = false

    init(_ x: Bool = false)
    {
        self.x = x
    }
    
    func toSIMD() -> Bool
    {
        return x
    }
}

class TextRef
{
    var text        : String? = nil

    var f1          : Float1? = nil
    var f2          : Float2? = nil
    var f3          : Float3? = nil
    var f4          : Float4? = nil

    var i1          : Int1? = nil
    
    var font        : Font? = nil
    var fontSize    : Float = 10
    
    var digits      : Int1? = nil

    init(_ text: String? = nil)
    {
        self.text = text
    }
}

class Rect2D
{
    var x               : Float = 0
    var y               : Float = 0
    var width           : Float = 0
    var height          : Float = 0

    init(_ x: Float = 0,_ y: Float = 0,_ width: Float = 0,_ height:Float = 0)
    {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
