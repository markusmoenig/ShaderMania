import CoreGraphics

extension CGPoint: Value {
    
    public func push(_ vm: VirtualMachine) {
        let t = vm.createTable()
        t["x"] = Double(self.x)
        t["y"] = Double(self.y)
        t.push(vm)
    }
    
    public func kind() -> Kind { return .table }
    
    fileprivate static let typeName: String = "point (table with numeric keys x,y)"
    public static func arg(_ vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .table { return typeName }
        if let result = Table.arg(vm, value: value) { return result }
        let t = value as! Table
        if !(t["x"] is Number) || !(t["y"] is Number) { return typeName }
        return nil
    }
    
}

extension CGSize: Value {
    
    public func push(_ vm: VirtualMachine) {
        let t = vm.createTable()
        t["w"] = Double(self.width)
        t["h"] = Double(self.height)
        t.push(vm)
    }
    
    public func kind() -> Kind { return .table }
    
    fileprivate static let typeName: String = "size (table with numeric keys w,h)"
    public static func arg(_ vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .table { return typeName }
        if let result = Table.arg(vm, value: value) { return result }
        let t = value as! Table
        if !(t["w"] is Number) || !(t["h"] is Number) { return typeName }
        return nil
    }
    
}

extension Table {
    
    public func toPoint() -> CGPoint? {
        let x = self["x"] as? Number
        let y = self["y"] as? Number
        if x == nil || y == nil { return nil }
        return CGPoint(x: x!.toDouble(), y: y!.toDouble())
    }
    
    public func toSize() -> CGSize? {
        let w = self["w"] as? Number
        let h = self["h"] as? Number
        if w == nil || h == nil { return nil }
        return CGSize(width: w!.toDouble(), height: h!.toDouble())
    }
    
}

extension Arguments {
    
    public var point: CGPoint { return (values.remove(at: 0) as! Table).toPoint()! }
    public var size:  CGSize  { return (values.remove(at: 0) as! Table).toSize()!  }
    
}
