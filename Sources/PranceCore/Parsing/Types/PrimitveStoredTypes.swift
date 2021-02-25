import LLVM

final class DoubleStore: StoredType {
  var IRType: IRType? {
    get {
      return FloatType.double
    }
    set {
      // Not implemented because this type is already known
    }
  }
  var IRRef: IRType? {
    get {
      return FloatType.double
    }
    set {
      // Not implemented because this type is already known
    }
  }
  let name = "Double"
  
  convenience init?(name: String) {
    self.init()
    guard name == self.name else {
      return nil
    }
  }
  
}

final class IntStore: StoredType {
  let name = "Int"
  var IRType: IRType? {
    get {
      return IntType(width: MemoryLayout<Int>.size * 8)
    }
    set {
      // Not implemented because this type is already known
    }
  }
  
  var IRRef: IRType? {
    get {
      return IntType(width: MemoryLayout<Int>.size * 8)
    }
    set {
      // Not implemented because this type is already known
    }
  }

  convenience init?(name: String) {
    self.init()
    guard name == self.name else {
      return nil
    }
  }
}

final class FloatStore: StoredType {
  let name = "Float"
  var IRType: IRType? {
    get {
      return FloatType.float
    }
    set {
      // Not implemented because this type is already known
    }
  }
  
  var IRRef: IRType? {
    get {
      return FloatType.float
    }
    set {
      // Not implemented because this type is already known
    }
  }
  
  convenience init?(name: String) {
    self.init()
    guard name == self.name else {
      return nil
    }
  }
}

final class StringStore: StoredType {
  let name = "String"
  var IRType: IRType? {
    get {
      return PointerType(pointee: IntType.int8)
    }
    set {
      // Not implemented because this type is already known
    }
  }

  var IRRef: IRType? {
    get {
      return PointerType(pointee: IntType.int8)
    }
    set {
      // Not implemented because this type is already known
    }
  }
  
  convenience init?(name: String) {
    self.init()
    guard name == self.name else {
      return nil
    }
  }
}

final class VoidStore: StoredType {
  let name = ""
  var IRType: IRType? {
    get {
      return VoidType()
    }
    set {
      // Not implemented because this type is already known
    }
  }
  
  var IRRef: IRType? {
    get {
      return VoidType()
    }
    set {
      // Not implemented because this type is already known
    }
  }

  convenience init?(name: String) {
      return nil
  }
}
