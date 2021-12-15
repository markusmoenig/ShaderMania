
extension Bool: Value {
    
    public func push(_ vm: VirtualMachine) {
        lua_pushboolean(vm.vm, self ? 1 : 0)
    }
    
    public func kind() -> Kind { return .boolean }
    
    public static func arg(_ vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .boolean { return "boolean" }
        return nil
    }
    
}
