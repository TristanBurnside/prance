import LLVM

protocol StoredType: class {
  var IRType: IRType? { get set }
  var IRRef: IRType? { get set }
  var name: String { get }

  init?(name: String)
}

final class CustomStore: StoredType {
  // Type is currently unknown
  var IRType: IRType? = nil
  var IRRef: IRType? = nil
  let name: String
  
  init?(name: String) {
    self.name = name
  }
}
