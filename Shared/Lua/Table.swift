
open class Table: StoredValue {
    
    override open func kind() -> Kind { return .table }
    
    override open class func arg(_ vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .table { return "table" }
        return nil
    }
    
    open subscript(key: Value) -> Value {
        get {
            push(vm)
            
            key.push(vm)
            lua_gettable(vm.vm, -2)
            let v = vm.popValue(-1)
            
            vm.pop()
            return v!
        }
        
        set {
            push(vm)
            
            key.push(vm)
            newValue.push(vm)
            lua_settable(vm.vm, -3)
            
            vm.pop()
        }
    }
    
    open func keys() -> [Value] {
        var k = [Value]()
        push(vm) // table
        lua_pushnil(vm.vm)
        while lua_next(vm.vm, -2) != 0 {
            vm.pop() // val
            let key = vm.popValue(-1)!
            k.append(key)
            key.push(vm)
        }
        vm.pop() // table
        return k
    }
    
    open func becomeMetatableFor(_ thing: Value) {
        thing.push(vm)
        self.push(vm)
        lua_setmetatable(vm.vm, -2)
        vm.pop() // thing
    }
    
    open func asTupleArray<K1: Value, V1: Value, K2: Value, V2: Value>(_ kfn: (K1) -> K2 = {$0 as! K2}, _ vfn: (V1) -> V2 = {$0 as! V2}) -> [(K2, V2)] {
        var v = [(K2, V2)]()
        for key in keys() {
            let val = self[key]
            if key is K1 && val is V1 {
                v.append((kfn(key as! K1), vfn(val as! V1)))
            }
        }
        return v
    }
    
    open func asDictionary<K1: Value, V1: Value, K2: Value, V2: Value>(_ kfn: (K1) -> K2 = {$0 as! K2}, _ vfn: (V1) -> V2 = {$0 as! V2}) -> [K2: V2] where K2: Hashable {
        var v = [K2: V2]()
        for (key, val) in asTupleArray(kfn, vfn) {
            v[key] = val
        }
        return v
    }
    
    open func asSequence<T: Value>() -> [T] {
        var sequence = [T]()
        
        let dict: [Int64 : T] = asDictionary({ (k: Number) in k.toInteger() }, { $0 as T })
        
        // if it has no numeric keys, then it's empty; job well done, team, job well done.
        if dict.count == 0 { return sequence }
        
        // ensure table has no holes and keys start at 1
        let sortedKeys = dict.keys.sorted(by: <)
        if [Int64](1...sortedKeys.last!) != sortedKeys { return sequence }
        
        // append values to the array, in order
        for i in sortedKeys {
            sequence.append(dict[i]!)
        }
        
        return sequence
    }
    
    func storeReference(_ v: Value) -> Int {
        v.push(vm)
        return vm.ref(RegistryIndex)
    }
    
    func removeReference(_ ref: Int) {
        vm.unref(RegistryIndex, ref)
    }
    
}
