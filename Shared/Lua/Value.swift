
public protocol Value {
    func push(_ vm: VirtualMachine)
    func kind() -> Kind
    static func arg(_ vm: VirtualMachine, value: Value) -> String?
}

open class StoredValue: Value, Equatable {
    
    fileprivate let registryLocation: Int
    internal unowned var vm: VirtualMachine
    
    internal init(_ vm: VirtualMachine) {
        self.vm = vm
        vm.pushFromStack(-1)
        registryLocation = vm.ref(RegistryIndex)
    }
    
    deinit {
        vm.unref(RegistryIndex, registryLocation)
    }
    
    open func push(_ vm: VirtualMachine) {
        vm.rawGet(tablePosition: RegistryIndex, index: registryLocation)
    }
    
    open func kind() -> Kind {
        fatalError("Override kind()")
    }
    
    open class func arg(_ vm: VirtualMachine, value: Value) -> String? {
        fatalError("Override arg()")
    }
    
}

public func ==(lhs: StoredValue, rhs: StoredValue) -> Bool {
    if lhs.vm.vm != rhs.vm.vm { return false }
    
    lhs.push(lhs.vm)
    lhs.push(rhs.vm)
    let result = lua_compare(lhs.vm.vm, -2, -1, LUA_OPEQ) == 1
    lhs.vm.pop(2)
    
    return result
}
