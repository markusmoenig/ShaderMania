
public enum FunctionResults {
    case values([Value])
    case error(String)
}

open class Function: StoredValue {
    
    open func call(_ args: [Value]) -> FunctionResults {
        let debugTable = vm.globals["debug"] as! Table
        let messageHandler = debugTable["traceback"]
        
        let originalStackTop = vm.stackSize()
        
        messageHandler.push(vm)
        push(vm)
        for arg in args {
            arg.push(vm)
        }
        
        let result = lua_pcallk(vm.vm, Int32(args.count), LUA_MULTRET, Int32(originalStackTop + 1), 0, nil)
        vm.remove(originalStackTop + 1)
        
        if result == LUA_OK {
            var values = [Value]()
            let numReturnValues = vm.stackSize() - originalStackTop
            
            for _ in 0..<numReturnValues {
                let v = vm.popValue(originalStackTop+1)!
                values.append(v)
            }
            
            return .values(values)
        }
        else {
            let err = vm.popError()
            return .error(err)
        }
    }
    
    override open func kind() -> Kind { return .function }
    
    override open class func arg(_ vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .function { return "function" }
        return nil
    }
    
}

public typealias TypeChecker = (VirtualMachine, Value) -> String?

public enum SwiftReturnValue {
    case value(Value?)
    case values([Value])
    case nothing // convenience for Values([])
    case error(String)
}

public typealias SwiftFunction = (Arguments) -> SwiftReturnValue

open class Arguments {
    
    internal var values = [Value]()
    
    open var string: String { return values.remove(at: 0) as! String }
    open var number: Number { return values.remove(at: 0) as! Number }
    open var boolean: Bool { return values.remove(at: 0) as! Bool }
    open var function: Function { return values.remove(at: 0) as! Function }
    open var table: Table { return values.remove(at: 0) as! Table }
    open var userdata: Userdata { return values.remove(at: 0) as! Userdata }
    open var lightUserdata: LightUserdata { return values.remove(at: 0) as! LightUserdata }
    open var thread: Thread { return values.remove(at: 0) as! Thread }
    
    open var integer: Int64 { return (values.remove(at: 0) as! Number).toInteger() }
    open var double: Double { return (values.remove(at: 0) as! Number).toDouble() }
    
    open func customType<T: CustomTypeInstance>() -> T { return (values.remove(at: 0) as! Userdata).toCustomType() }
    
}
