
open class Userdata: StoredValue {
    
    open func userdataPointer<T>() -> UnsafeMutablePointer<T> {
        push(vm)
        let ptr = lua_touserdata(vm.vm, -1)
        vm.pop()
        return (ptr?.assumingMemoryBound(to: T.self))!
    }

    open func toCustomType<T: CustomTypeInstance>() -> T {
        return userdataPointer().pointee
    }
    
    open func toAny() -> Any {
        return userdataPointer().pointee
    }
    
    override open func kind() -> Kind { return .userdata }
    
}

open class LightUserdata: StoredValue {
    
    override open func kind() -> Kind { return .lightUserdata }
    
    override open class func arg(_ vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .lightUserdata { return "light userdata" }
        return nil
    }
    
}

public protocol CustomTypeInstance {
    
    static func luaTypeName() -> String
    
}

open class CustomType<T: CustomTypeInstance>: Table {
    
    override open class func arg(_ vm: VirtualMachine, value: Value) -> String? {
        value.push(vm)
        let isLegit = luaL_testudata(vm.vm, -1, (T.luaTypeName() as NSString).utf8String) != nil
        vm.pop()
        if !isLegit { return T.luaTypeName() }
        return nil
    }
    
    override internal init(_ vm: VirtualMachine) {
        super.init(vm)
    }
    
    open var gc: ((T) -> Void)?
    open var eq: ((T, T) -> Bool)?
    
    public func createMethod(_ typeCheckers: [TypeChecker], _ fn: @escaping (T, Arguments) -> SwiftReturnValue) -> Function {
        var typeCheckers = typeCheckers
        typeCheckers.insert(CustomType<T>.arg, at: 0)
        return vm.createFunction(typeCheckers) { (args: Arguments) in
            if args.values.count > 0 {
                let o: T = args.customType()
                return fn(o, args)
            } else {
                return .nothing
            }
        }
    }
    
}
