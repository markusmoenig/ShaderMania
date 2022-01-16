//
//  LuaCompiler.swift
//  ShaderMania
//
//  Created by Markus Moenig on 15/12/21.
//

import Foundation

class LuaCompiler
{
    let model               : Model
    
    init(_ model: Model) {
        self.model = model
    }
    
    func compile(node: Node, cb: @escaping (VirtualMachine?, [CompileError]) -> ())
    {
        let code =  node.getCode()
        
        let vm = VirtualMachine()
        var parseErrors : [CompileError] = []

        switch vm.eval(code, args: []) {
        case let .values(values):
            if values.isEmpty == false {
                print(values.first!)
            }
        case let .error(e):
            print("error", e)
            /*
            self.model.infoText += e + "\n"
            self.context.hasErrors = true
            DispatchQueue.main.async {
                self.model.infoChanged.send()
            }*/
        }
            
        cb(vm, parseErrors)
    }
}
