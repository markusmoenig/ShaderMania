//
//  MMAnimate.swift
//  Shape-Z
//
//  Created by Markus Moenig on 25/1/19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation
import simd

class MMAnimate
{
    let startValue  : Float
    let endValue    : Float
    let duration    : Float

    let cb          : (Float, Bool)->()
    
    var finished    : Bool
    
    let startTime   : Double

    init(startValue: Float, endValue: Float, duration: Float, cb: @escaping (Float, Bool)->())
    {
        self.startValue = startValue
        self.endValue = endValue
        self.duration = duration
        self.cb = cb
        
        finished = false
        
        startTime = Double(Date().timeIntervalSince1970 * 1000)
    }
    
    func tick()
    {
        let currTime = getCurrentMs()
        let delta : Float = Float(currTime - startTime)
        
        if delta >= duration {
            finished = true
            cb( endValue, true)
        } else {
//            let value : Float = startValue + ((endValue-startValue) / duration) * delta
//            let delta = nextValue - prevValue; value = delta ? prevValue + delta * smoothstep( prevValue, nextValue, prevValue + ( delta / frameDur ) * frameOff ) : 0;

            let deltaValue = endValue-startValue
            let value : Float = deltaValue != 0 ? startValue + deltaValue * simd_smoothstep( startValue, endValue, startValue + ( deltaValue / duration ) * delta ) : 0;

            
            cb(value, false)
        }
    }
    
    /// Get the current time in ms
    func getCurrentMs()->Double {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
}
