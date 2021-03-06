import LLVM

struct Prototype {
  let name: String
  let params: [VariableDefinition]
  let returnType: StoredType
}

extension Prototype: Equatable {
  static func ==(lhs: Prototype, rhs: Prototype) -> Bool {
    guard lhs.name == rhs.name else {
      return false
    }
    guard lhs.returnType.name == rhs.returnType.name else {
      return false
    }
    for (lhsParam, rhsParam) in zip(lhs.params, rhs.params) {
      if lhsParam.name != rhsParam.name || lhsParam.type.name != rhsParam.type.name {
        return false
      }
    }
    return true
  }
}

protocol CallableType {
  var IRType: StructType? { get set }
  var IRRef: PointerType? { get set }
  var name: String { get }
  var properties: [(String, StoredType)] { get }
  var prototypes: [Prototype] { get }
}

final class TypeDefinition: CallableType {
  let name: String
  var id: UInt32? = nil
  var IRType: StructType? = nil
  var IRRef: PointerType? = nil
  let properties: [(String, StoredType)]
  var functions: [FunctionDefinition]
  let protocols: [String]
  var protocolConformanceStubs: [(String, Prototype)] = []
  
  var prototypes: [Prototype] {
    return functions.map { $0.prototype } + protocolConformanceStubs.map { $0.1 }
  }
  
  init(name: String, properties: [(String, StoredType)], functions: [FunctionDefinition], protocols: [String]) {
    self.name = name
    self.properties = properties
    self.functions = functions
    self.protocols = protocols
  }
  
  lazy var initMethod: FunctionDefinition = {
    let variables = properties.map { (name, type) in
      return VariableDefinition(name: name, type: type)
    }
    guard let type = CustomStore(name: name) else {
      fatalError("Type \(name) could not be created")
    }
    
    var initExpr = [Expr]()
    for variable in variables {
      initExpr.append(.variableAssignment(.memberDereference(.variable("self"),.property(variable.name)), .variable(variable.name)))
    }
    initExpr.append(.return(.variable("self")))
    return FunctionDefinition(prototype: Prototype(name: self.name, params: variables, returnType: type), expr: initExpr)
  }()
}

final class ProtocolDefinition: CallableType {
  let name: String
  var IRType: StructType? = nil
  var IRRef: PointerType? = nil
  let properties: [(String, StoredType)]
  var prototypes: [Prototype]
  var defaults: [String: FunctionDefinition] = [:]
  
  init(name: String, properties: [(String, StoredType)], prototypes: [Prototype]) {
    self.name = name
    self.properties = properties
    self.prototypes = prototypes
  }
}

final class ExtensionDefinition {
  let name: String
  let functions: [FunctionDefinition]
  
  init(name: String, functions: [FunctionDefinition]) {
    self.name = name
    self.functions = functions
  }
}

final class FunctionDefinition {
  let prototype: Prototype
  let expr: [Expr]
  var typedExpr: [TypedExpr]!
  
  init(prototype: Prototype, expr: [Expr]) {
    self.prototype = prototype
    self.expr = expr
  }
}

struct FunctionCall {
  let name: String
  let args: [FunctionArg]
}

struct FunctionArg {
  let label: String?
  let expr: Expr
  let typedExpr: TypedExpr!
}

struct VariableDefinition {
  let name: String
  let type: StoredType
}

enum Definition {
  case function(FunctionDefinition)
  case extern(Prototype)
  case type(TypeDefinition)
  case proto(ProtocolDefinition)
  case extend(ExtensionDefinition)
  case defaultImpl(ExtensionDefinition)
}

class File {
  private(set) var externs = [Prototype]()
  private(set) var functions = [FunctionDefinition]()
  private(set) var expressions = [Expr]()
  var typedExpressions = [TypedExpr]()
  private(set) var prototypeMap = [String: Prototype]()
  private(set) var customTypes = [TypeDefinition]()
  private(set) var protocols = [ProtocolDefinition]()
  private(set) var extensions = [ExtensionDefinition]()
  private(set) var defaults = [ExtensionDefinition]()
  
  init() {
    addExtern(Prototype(name: "printf", params: [VariableDefinition(name: "format", type: StringStore()), VariableDefinition(name: "str", type: StringStore())], returnType: VoidStore()))
    addExtern(Prototype(name: "scanf", params: [VariableDefinition(name: "format", type: StringStore()), VariableDefinition(name: "str", type: StringStore())], returnType: VoidStore()))
    addExtern(Prototype(name: "scanLine", params: [], returnType: StringStore()))
    
    let printProto = Prototype(name: "print", params: [VariableDefinition(name: "line", type: StringStore())], returnType: VoidStore())
    let printExprs: [TypedExpr] = [.call(FunctionCall(name: "printf",
                                                      args: [FunctionArg(label: "format", expr: .literal(.string([.string("%s\n")])), typedExpr: .literal(.string([.string("%s\n")]), StringStore())),
                                                             FunctionArg(label: "str", expr: .variable("line"), typedExpr: .variable("line", StringStore()))]), VoidStore())]
    let function = FunctionDefinition(prototype: printProto, expr: [])
    function.typedExpr = printExprs
    addFunctionDefinition(function)
  }
  
  func prototype(name: String) -> Prototype? {
    return prototypeMap[name]
  }
  
  func addExpression(_ expression: Expr) {
    expressions.append(expression)
  }
  
  func addExtern(_ prototype: Prototype) {
    externs.append(prototype)
    prototypeMap[prototype.name] = prototype
  }
  
  func addDefinition(_ definition: Definition) {
    switch definition {
    case .extern(let proto):
      addExtern(proto)
    case .function(let function):
      addFunctionDefinition(function)
    case .type(let type):
      addType(type)
    case .proto(let proto):
      addProtocol(proto)
    case .extend(let extend):
      addExtension(extend)
    case .defaultImpl(let def):
      addDefault(def)
    }
  }
  
  func addFunctionDefinition(_ definition: FunctionDefinition) {
    functions.append(definition)
    prototypeMap[definition.prototype.name] = definition.prototype
  }
  
  func addType(_ type: TypeDefinition) {
    customTypes.append(type)
    prototypeMap[type.name] = type.initMethod.prototype
  }
  
  func addProtocol(_ proto: ProtocolDefinition) {
    protocols.append(proto)
  }
  
  func addExtension(_ extend: ExtensionDefinition) {
    extensions.append(extend)
  }
  
  func addDefault(_ def: ExtensionDefinition) {
    defaults.append(def)
  }
}

indirect enum Expr {
  case literal(LiteralType)
  case variable(String)
  case variableDefinition(VariableDefinition)
  case memberDereference(Expr, TypeMemberReference)
  case variableAssignment(Expr, Expr)
  case binary(Expr, BinaryOperator, Expr)
  case logical(Expr, LogicalOperator, Expr)
  case ifelse(Expr, [Expr], [Expr])
  case forLoop(Expr, Expr, [Expr])
  case whileLoop(Expr,[Expr])
  case call(FunctionCall)
  case `return`(Expr?)
}
