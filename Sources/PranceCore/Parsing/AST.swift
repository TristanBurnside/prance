import LLVM

struct Prototype {
  let name: String
  let params: [VariableDefinition]
  let returnType: StoredType
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
  let functions: [FunctionDefinition]
  let protocols: [String]
  
  var prototypes: [Prototype] {
    return functions.map { $0.prototype }
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
  
  init(name: String, properties: [(String, StoredType)], prototypes: [Prototype]) {
    self.name = name
    self.properties = properties
    self.prototypes = prototypes
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
  let returnType: StoredType?
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
}

class File {
  private(set) var externs = [Prototype]()
  private(set) var functions = [FunctionDefinition]()
  private(set) var expressions = [Expr]()
  var typedExpressions = [TypedExpr]()
  private(set) var prototypeMap = [String: Prototype]()
  private(set) var customTypes = [TypeDefinition]()
  private(set) var protocols = [ProtocolDefinition]()
  
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
