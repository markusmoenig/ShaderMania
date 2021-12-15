
open class Nil: Value, Equatable {
    
    open func push(_ vm: VirtualMachine) {
        lua_pushnil(vm.vm)
    }
    
    open func kind() -> Kind { return .nil }
    
    open class func arg(_ vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .nil { return "nil" }
        return nil
    }
    
}

public func ==(lhs: Nil, rhs: Nil) -> Bool {
    return true
}
