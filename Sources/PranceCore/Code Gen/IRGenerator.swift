import LLVM

let kInternalPropertiesCount = 2

enum IRError: Error, CustomStringConvertible {
  case unknownFunction(String)
  case unknownVariable(String)
  case wrongNumberOfArgs(String, expected: Int, got: Int)
  case incorrectFunctionLabel(String, expected: String, got: String)
  case nonTruthyType(IRType)
  case unprintableType(IRType)
  case unableToCompare(IRType, IRType)
  case expectedParameterDefinition(String)
  case unknownMember(String)
  case unknownMemberFunction(String)
  case unknownType(String)
  case incorrectlyParsedLiteral
  case missingFunction(TypeDefinition, String)
  case returnOutsideFunction
  
  var description: String {
    switch self {
    case .unknownFunction(let name):
      return "unknown function '\(name)'"
    case .unknownVariable(let name):
      return "unknown variable '\(name)'"
    case .wrongNumberOfArgs(let name, let expected, let got):
      return "call to function '\(name)' with \(got) arguments (expected \(expected))"
    case .incorrectFunctionLabel(let name, let expected, let got):
      return "call to function '\(name)' expected parameter \(expected) received \(got)"
    case .nonTruthyType(let type):
      return "logical operation found non-truthy type: \(type)"
    case .unprintableType(let type):
      return "unable to print result of type \(type)"
    case .unableToCompare(let type1, let type2):
      return "unable to compare \(type1) with \(type2)"
    case .expectedParameterDefinition(let name):
      return "expected parameter definition in declaration of function \(name)"
    case .unknownMember(let name):
      return "No member: \(name) in type"
    case .unknownMemberFunction(let name):
      return "No function: \(name) in type"
    case .unknownType(let name):
      return "No type defined called \(name)"
    case .incorrectlyParsedLiteral:
      return "String literal was not parsed before generating LLVM IR"
    case .missingFunction(let type, let name):
      return "Type: \(type.name) is missing protocol function \(name)"
    case .returnOutsideFunction:
      return "Return statement executed outside of function body"
    }
  }
}

func ==(lhs: IRType, rhs: IRType) -> Bool {
    return lhs.asLLVM() == rhs.asLLVM()
}

class IRGenerator {
  let module: Module
  let builder: IRBuilder
  let file: File
  let protocolType: StructType
  
  private var parameterValues: StackMemory<IRValue>
  private var typesByIR: [(IRType, TypeDefinition)]
  private var typesByName: [String: CallableType]
  private var typesByID: [UInt32: TypeDefinition]
  private var nextTypeID: UInt32 = 0
  private var currentReturnBlock: BasicBlock?
  
  init(moduleName: String = "main", file: File) {
    self.module = Module(name: moduleName)
    let builder = IRBuilder(module: module)
    self.builder = builder
    self.file = file
    parameterValues = StackMemory()
    typesByName = [:]
    typesByIR = []
    typesByID = [:]
    protocolType = IRGenerator.defineProtocolStruct(builder: builder)
  }
  
  func emit() throws {
    let _ = emitPrintf()
    for extern in file.externs {
      try emitPrototype(extern)
    }
    for type in file.customTypes {
      defineType(type)
    }
    for proto in file.protocols {
      defineProtocol(proto)
    }
    for type in file.customTypes {
      try populateType(type)
    }
    for proto in file.protocols {
      try emitProtocolFunctions(proto: proto)
    }
    for definition in file.functions {
      try emitFunction(definition)
    }
    try emitMain()
  }
  
  func emitPrintf() {
    guard module.function(named: "printf") == nil else { return }
    let printfType = FunctionType([PointerType(pointee: IntType.int8)], IntType.int32, variadic: true)
    let _ = builder.addFunction("printf", type: printfType)
  }
  
  func defineType(_ type: TypeDefinition) {
    let newType = builder.createStruct(name: type.name)
    type.IRType = newType
    type.IRRef = PointerType(pointee: newType)
    typesByIR.append((newType, type))
    typesByName[type.name] = type
  }
  
  func defineProtocol(_ proto: ProtocolDefinition) {
    proto.IRType = protocolType
    proto.IRRef = PointerType(pointee: protocolType)
    
    typesByName[proto.name] = proto
  }
  
  static func defineProtocolStruct(builder: IRBuilder) -> StructType {
    let properties = [IntType.int32, IntType.int32]
    let llvmProtocol = builder.createStruct(name: "proto", types: properties)
    return llvmProtocol
  }
  
  func populateType(_ type: TypeDefinition) throws {
    guard let llvmType = type.IRType else {
      throw IRError.unknownType(type.name)
    }
    let properties = try type.properties.map{ try $0.1.findRef(types: typesByName) }
    let internalProperties = [IntType.int32, IntType.int32]
    llvmType.setBody(internalProperties + properties)
    try emitInitializer(type.initMethod, for: type)
    for function in type.functions {
      try emitMember(function: function, of: type)
    }
  }
  
  func emitMain() throws {
    let mainType = FunctionType([], VoidType())
    let function = builder.addFunction("main", type: mainType)
    let entry = function.appendBasicBlock(named: "entry")
    builder.positionAtEnd(of: entry)
    
    for expr in file.typedExpressions {
      let _ = try emitExpr(expr)
    }
    
    builder.buildRetVoid()
  }
  
  @discardableResult
  func emitMember(prototype: Prototype, of type: CallableType) throws -> Function {
    let llvmPrototype = try internalPrototype(for: prototype, of: type)
    return try emitPrototype(llvmPrototype)
  }
  
  @discardableResult
  func emitMember(function: FunctionDefinition, of type: CallableType) throws -> Function {
    let llvmPrototype = try internalPrototype(for: function.prototype, of: type)
    let llvmFunction = FunctionDefinition(prototype: llvmPrototype, expr: function.expr)
    llvmFunction.typedExpr = function.typedExpr
    return try emitFunction(llvmFunction)
  }
  
  func internalPrototype(for prototype: Prototype, of type: CallableType) throws -> Prototype {
    // Add self arg reference
    let internalName = type.name + "." + prototype.name
    let selfType = CustomStore(name: type.name)!
    let internalParams = [VariableDefinition(name: "self", type: selfType)] + prototype.params
    return Prototype(name: internalName, params: internalParams, returnType: prototype.returnType)
  }
  
  func emitProtocolFunctions(proto: ProtocolDefinition) throws {
    let conformingTypes = typesByIR.map { $0.1 }.filter { $0.protocols.contains(proto.name) }
    
    for prototype in proto.prototypes {
      let internalDefinition = try internalPrototype(for: prototype, of: proto)
      try emitProtocolMember(name: prototype.name, prototype: internalDefinition, conformingTypes: conformingTypes)
    }
  }
  
  func emitProtocolMember(name: String, prototype: Prototype, conformingTypes: [TypeDefinition]) throws {
    let function = try emitPrototype(prototype)
    parameterValues.startFrame()
    
    for (idx, arg) in prototype.params.enumerated() {
      let param = function.parameter(at: idx)!
      parameterValues.addStatic(name: arg.name, value: param)
    }
    
    let entryBlock = function.appendBasicBlock(named: "entry")
    let returnBlock = function.appendBasicBlock(named: "return")
    currentReturnBlock = returnBlock
    
    builder.positionAtEnd(of: entryBlock)
    if prototype.returnType.name != VoidStore().name {
      let _ = try emitExpr(.variableDefinition(VariableDefinition(name: ".return", type: prototype.returnType), VoidStore()))
    }
    
    let selfIR = try parameterValues.findVariable(name: "self")
    let typeIDRef = builder.buildStructGEP(selfIR, type: protocolType, index: 0)
    let typeID = builder.buildLoad(typeIDRef, type: typeIDRef.type.getResolvedType())
    
    for type in conformingTypes {
      let checkCond = builder.buildICmp(typeID,
                                        type.id!,
                                        .equal)
      
      let thenBB = builder.currentFunction!.appendBasicBlock(named: "then")
      let elseBB = builder.currentFunction!.appendBasicBlock(named: "else")
      
      builder.buildCondBr(condition: checkCond, then: thenBB, else: elseBB)
      
      builder.positionAtEnd(of: thenBB)
      
      guard let typedFunction = type.functions.first(where: { $0.prototype.name == name }) else {
        throw IRError.missingFunction(type, name)
      }
      // bitcast to type
      let typedSelf = builder.buildCast(.bitCast, value: selfIR, type: type.IRRef!)
      // call type version of function
      let typedFunctionIR = try emitMember(prototype: typedFunction.prototype, of: type)
      var typedParameters = function.parameters
      typedParameters[0] = typedSelf
      let call = builder.buildCall(typedFunctionIR, args: typedParameters)
      
      if prototype.returnType.name != VoidStore().name {
        builder.buildStore(call, to: try parameterValues.findVariable(name: ".return"))
      }
      let _ = try emitExpr(.return(nil, prototype.returnType))
      
      builder.positionAtEnd(of: elseBB)
    }
    
    builder.buildUnreachable()
    
    builder.positionAtEnd(of: returnBlock)
    if prototype.returnType.name == VoidStore().name {
      builder.buildRetVoid()
    } else {
      let returnVar = try parameterValues.findVariable(name: ".return")
      let returnVal = try value(from: returnVar, with: prototype.returnType)
      builder.buildRet(returnVal)
    }
    
    parameterValues.endFrame()
  }
  
  @discardableResult // declare double @foo(double %n, double %m)
  func emitPrototype(_ prototype: Prototype) throws -> Function {
    if let function = module.function(named: prototype.name) {
      return function
    }
    let argTypes = try prototype.params.map{ $0.type }.map{ try $0.findRef(types: typesByName) }
    
    let funcType = try FunctionType(argTypes, prototype.returnType.findRef(types: typesByName))
    let function = builder.addFunction(prototype.name, type: funcType)
    
    for (var param, name) in zip(function.parameters, prototype.params.map{ $0.name }) {
      param.name = name
    }
    
    return function
  }
  
  @discardableResult
  func emitFunction(_ definition: FunctionDefinition) throws -> Function {
    let function = try emitPrototype(definition.prototype)
    
    parameterValues.startFrame()
    
    for (idx, arg) in definition.prototype.params.enumerated() {
      let param = function.parameter(at: idx)!
      parameterValues.addStatic(name: arg.name, value: param)
    }
    
    let entryBlock = function.appendBasicBlock(named: "entry")
    let returnBlock = function.appendBasicBlock(named: "return")
    currentReturnBlock = returnBlock
    
    builder.positionAtEnd(of: entryBlock)
    
    if definition.prototype.returnType.name != VoidStore().name {
      let _ = try emitExpr(.variableDefinition(VariableDefinition(name: ".return", type: definition.prototype.returnType), VoidStore()))
    }
    
    try definition.typedExpr.forEach { let _ = try emitExpr($0) }
    
    if definition.prototype.returnType is VoidStore,
      !(definition.expr.last is Returnable) {
      let _ = try emitExpr(.return(nil, VoidStore()))
    }
    
    builder.positionAtEnd(of: returnBlock)
    if definition.prototype.returnType.name == VoidStore().name {
      builder.buildRetVoid()
    } else {
      let returnVar = try parameterValues.findVariable(name: ".return")
      let returnVal = try value(from: returnVar, with: definition.prototype.returnType)
      builder.buildRet(returnVal)
    }
    
    parameterValues.endFrame()
    
    return function
  }
  
  @discardableResult
  func emitInitializer(_ definition: FunctionDefinition, for type: TypeDefinition) throws -> Function {
    guard let llvmType = type.IRType else {
        throw IRError.unknownType(type.name)
    }
    let function = try emitPrototype(definition.prototype)
    
    parameterValues.startFrame()
    
    for (idx, arg) in definition.prototype.params.enumerated() {
      let param = function.parameter(at: idx)!
      parameterValues.addStatic(name: arg.name, value: param)
    }
    
    let entryBlock = function.appendBasicBlock(named: "alloc")
    
    let returnBlock = function.appendBasicBlock(named: "return")
    currentReturnBlock = returnBlock
    
    builder.positionAtEnd(of: entryBlock)
    let _ = try emitExpr(.variableDefinition(VariableDefinition(name: ".return", type: definition.prototype.returnType), VoidStore()))
    
    let selfPtr = builder.buildMalloc(llvmType)
    parameterValues.addStatic(name: "self", value: selfPtr)
    let typeIDPtr = builder.buildStructGEP(selfPtr, type: llvmType, index: 0)
    builder.buildStore(register(type: type), to: typeIDPtr)
    let arcPtr = builder.buildStructGEP(selfPtr, type: llvmType, index: 1)
    builder.buildStore(UInt32(0), to: arcPtr)
    
    try definition.typedExpr.forEach { let _ = try emitExpr($0) }
    
    builder.positionAtEnd(of: returnBlock)
    let returnVar = try parameterValues.findVariable(name: ".return")
    let returnVal = try value(from: returnVar, with: definition.prototype.returnType)
    builder.buildRet(returnVal)
    
    parameterValues.endFrame()
    
    return function
  }
  
  func register(type: TypeDefinition) -> UInt32 {
    typesByID[nextTypeID] = type
    type.id = nextTypeID
    defer {
      nextTypeID += 1
    }
    return nextTypeID
  }
  
  func emitExpr(_ expr: TypedExpr) throws -> (IRValue, StoredType) {
    switch expr {
    case .variableDefinition(let definition, let type):
      let newVar = builder.buildAlloca(type: try definition.type.findRef(types: typesByName), name: definition.name)
      parameterValues.addVariable(name: definition.name, value: newVar)
      return (VoidType().undef(), type)
    case .variable(let name, let type):
      let value = try parameterValues.findVariable(name: name)
      return (value, type)
    case .memberDereference(let instance, .property(let member), let type):
        let (instanceIR, instanceType) = try emitExpr(instance)
        guard let matchingType = typesByName[instanceType.name] else {
          throw IRError.unknownType(instanceType.name)
        }
        let members = matchingType.properties.enumerated().filter{ $1.0 == member }
        guard let (elementIndex, _) = members.first else {
            throw IRError.unknownMember(member)
        }
      let memberRef = builder.buildStructGEP(instanceIR, type: try instanceType.findType(types: typesByName), index: elementIndex + kInternalPropertiesCount, name: member)
      return (memberRef, type)
    case .memberDereference(let instance, .function(let functionCall), let type):
      let (instanceIR, instanceType) = try emitExprAndLoad(expr: instance)
      
      guard let matchingType = typesByName[instanceType.name] else {
        throw IRError.unknownMemberFunction(functionCall.name)
      }
      let functions = matchingType.prototypes.filter{ $0.name == functionCall.name }
      guard let function = functions.first else {
        throw IRError.unknownMemberFunction(functionCall.name)
      }
      guard function.params.count == functionCall.args.count else {
        throw IRError.wrongNumberOfArgs(functionCall.name,
                                        expected: function.params.count,
                                        got: functionCall.args.count)
      }
      try zip(function.params, functionCall.args).forEach { (protoArg, callArg) in
        if protoArg.name != callArg.label {
          throw IRError.incorrectFunctionLabel(function.name,
                                               expected: protoArg.name,
                                               got: callArg.label ?? "")
        }
      }
      let llvmFunction = try emitMember(prototype: function, of: matchingType)
      let callArgs = try functionCall.args.map{$0.typedExpr}.map(emitExprAndLoad).map { $0.0 }
      let callReturn = builder.buildCall(llvmFunction, args: [instanceIR] + callArgs)
      return (callReturn, type)
    case .variableAssignment(let variable, let expr, let type):
      let (variablePointer, ptrType) = try emitExpr(variable)
      let (value, valueType) = try emitExpr(expr)
      var castValue = value
      if ptrType.name != valueType.name {
        castValue = builder.buildCast(.bitCast, value: value, type: try ptrType.findRef(types: typesByName))
      }
      
      builder.buildStore(castValue, to: variablePointer)
      return (VoidType().undef(), type)

    case .literal(.double(let value), let type):
      return (FloatType.double.constant(value), type)
    case .literal(.float(let value), let type):
      return (FloatType.float.constant(Double(value)), type)
    case .literal(.integer(let value), let type):
      return (value.asLLVM(), type)
    case .literal(.string(let parts), let type):
      if case let .string(string) = parts.first {
        let globalString = builder.buildGlobalStringPtr(string)
        return (globalString, type)
      }
      throw IRError.unknownType("String with parts")
    case .binary(let lhs, let op, let rhs, let type):
      let (lhsVal, _) = try emitExprAndLoad(expr: lhs)
      let (rhsVal, _) = try emitExprAndLoad(expr: rhs)
      let result: IRValue
      switch op {
      case .plus:
        result = builder.buildAdd(lhsVal, rhsVal)
      case .minus:
        result = builder.buildSub(lhsVal, rhsVal)
      case .divide:
        result = builder.buildDiv(lhsVal, rhsVal)
      case .times:
        result = builder.buildMul(lhsVal, rhsVal)
      case .mod:
        result = builder.buildRem(lhsVal, rhsVal)
      }
      return (result, type)
    case .logical(let lhs, let op, let rhs, let type):
      let (lhsVal, _) = try emitExprAndLoad(expr: lhs)
      let (rhsVal, _) = try emitExprAndLoad(expr: rhs)
      
      let lhsCond = try lhsVal.truthify(builder: builder)
      let rhsCond = try rhsVal.truthify(builder: builder)
      
      var comparisonType: (float: RealPredicate, int: IntPredicate)? = nil
      
      switch op {
      case .and:
        let intRes = builder.buildAnd(lhsCond, rhsCond)
        return (intRes, type)
      case .or:
        let intRes = builder.buildOr(lhsCond, rhsCond)
        return (intRes, type)
      case .equals:
        comparisonType = (.orderedEqual, .equal)
      case .notEqual:
        comparisonType = (.orderedNotEqual, .notEqual)
      case .lessThan:
        comparisonType = (.orderedLessThan, .signedLessThan)
      case .lessThanOrEqual:
        comparisonType = (.orderedLessThanOrEqual, .signedLessThanOrEqual)
      case .greaterThan:
        comparisonType = (.orderedGreaterThan, .signedGreaterThan)
      case .greaterThanOrEqual:
        comparisonType = (.orderedGreaterThanOrEqual, .signedGreaterThanOrEqual)
      }
      if lhsVal.type is FloatType,
        rhsVal.type is FloatType {
        return (builder.buildFCmp(lhsVal, rhsVal, comparisonType!.float), type)
      }
      if lhsVal.type is IntType,
        rhsVal.type is IntType {
        return (builder.buildICmp(lhsVal, rhsVal, comparisonType!.int), type)
      }
      throw IRError.unableToCompare(lhsVal.type, rhsVal.type)
      
    case .call(let functionCall, let type):
      guard let prototype = file.prototype(name: functionCall.name) else {
        throw IRError.unknownFunction(functionCall.name)
      }
      guard prototype.params.count == functionCall.args.count else {
        throw IRError.wrongNumberOfArgs(functionCall.name,
                                        expected: prototype.params.count,
                                        got: functionCall.args.count)
      }
      try zip(prototype.params, functionCall.args).forEach { (protoArg, callArg) in
        if protoArg.name != callArg.label {
          throw IRError.incorrectFunctionLabel(prototype.name,
                                               expected: protoArg.name,
                                               got: callArg.label ?? "")
        }
      }
      let callArgs = try functionCall.args.map{$0.typedExpr}.map(emitExprAndLoad).map { $0.0 }
      let function = try emitPrototype(prototype)
      return (builder.buildCall(function, args: callArgs), type)
    case .return(let expr, let type):
      guard let returnBlock = currentReturnBlock else {
        throw IRError.returnOutsideFunction
      }
      if let expr = expr {
        let (innerVal, _) = try emitExprAndLoad(expr: expr)
        let returnVar = try parameterValues.findVariable(name: ".return")
        builder.buildStore(innerVal, to: returnVar)
      }
      return (builder.buildBr(returnBlock), type)
    case .ifelse(let cond, let thenBlock, let elseBlock, let type):
      let (condition, _) = try emitExprAndLoad(expr: cond)
      let truthCondition = try condition.truthify(builder: builder)
      let checkCond = builder.buildICmp(truthCondition,
                                        (truthCondition.type as! IntType).zero(),
                                        .notEqual)
      
      let thenBB = builder.currentFunction!.appendBasicBlock(named: "then")
      let elseBB = builder.currentFunction!.appendBasicBlock(named: "else")
      let mergeBB = builder.currentFunction!.appendBasicBlock(named: "merge")
      
      builder.buildCondBr(condition: checkCond, then: thenBB, else: elseBB)
      
      builder.positionAtEnd(of: thenBB)
      try thenBlock.forEach { let _ = try emitExpr($0) }
      if case .return = thenBlock.last {
        // No need to branch because we already returned
      } else {
        builder.buildBr(mergeBB)
      }
      
      builder.positionAtEnd(of: elseBB)
      try elseBlock.forEach { let _ = try emitExpr($0) }
      if case .return = elseBlock.last {
        // No need to branch because we already returned
      } else {
        builder.buildBr(mergeBB)
      }
      
      builder.positionAtEnd(of: mergeBB)
      
      return (VoidType().undef(), type)
    case .forLoop(let ass, let cond, let body, let type):
      parameterValues.startFrame()
      defer {
        parameterValues.endFrame()
      }
      let startBB = builder.currentFunction!.appendBasicBlock(named: "setup")
      let bodyBB = builder.currentFunction!.appendBasicBlock(named: "body")
      let cleanupBB = builder.currentFunction!.appendBasicBlock(named: "cleanup")
      
      builder.buildBr(startBB)
      
      builder.positionAtEnd(of: startBB)
      let _ = try emitExpr(ass)
      let (startCondition, _) = try emitExpr(cond)
      let startTruthCondition = try startCondition.truthify(builder: builder)
      let startCheckCond = builder.buildICmp(startTruthCondition,
                                        (startTruthCondition.type as! IntType).zero(),
                                        .notEqual)
      builder.buildCondBr(condition: startCheckCond, then: bodyBB, else: cleanupBB)

      
      builder.positionAtEnd(of: bodyBB)
      try body.forEach { let _ = try emitExpr($0) }
      let (endCondition, _) = try emitExpr(cond)
      let endTruthCondition = try endCondition.truthify(builder: builder)
      let endCheckCond = builder.buildICmp(endTruthCondition,
                                        (endTruthCondition.type as! IntType).zero(),
                                        .notEqual)
      builder.buildCondBr(condition: endCheckCond, then: bodyBB, else: cleanupBB)
      builder.positionAtEnd(of: cleanupBB)
      
      return (VoidType().undef(), type)
    case .whileLoop(let cond, let body, let type):
      parameterValues.startFrame()
      defer {
        parameterValues.endFrame()
      }
      let startBB = builder.currentFunction!.appendBasicBlock(named: "setup")
      let bodyBB = builder.currentFunction!.appendBasicBlock(named: "body")
      let cleanupBB = builder.currentFunction!.appendBasicBlock(named: "cleanup")
      
      builder.positionAtEnd(of: startBB)
      let (startCondition, _) = try emitExpr(cond)
      let startTruthCondition = try startCondition.truthify(builder: builder)
      let startCheckCond = builder.buildICmp(startTruthCondition,
                                             (startTruthCondition.type as! IntType).zero(),
                                             .notEqual)
      builder.buildCondBr(condition: startCheckCond, then: bodyBB, else: cleanupBB)
      
      builder.positionAtEnd(of: bodyBB)
      try body.forEach { let _ = try emitExpr($0) }
      let (endCondition, _) = try emitExpr(cond)
      let endTruthCondition = try endCondition.truthify(builder: builder)
      let endCheckCond = builder.buildICmp(endTruthCondition,
                                           (endTruthCondition.type as! IntType).zero(),
                                           .notEqual)
      builder.buildCondBr(condition: endCheckCond, then: bodyBB, else: cleanupBB)
      builder.positionAtEnd(of: cleanupBB)
      
      return (VoidType().undef(), type)
    }
  }
  
  func emitExprAndLoad(expr: TypedExpr) throws -> (IRValue, StoredType) {
    let (reference, refType) = try emitExpr(expr)
    let loaded = try value(from: reference, with: refType)
    return (loaded, refType)
  }
  
  func value(from variable: IRValue, with expectedType: StoredType) throws -> (IRValue) {
    guard let type = variable.type as? PointerType else {
      return variable
    }
    // Make sure IRRef is populated
    let expectedIRType = try expectedType.findRef(types: typesByName)
    let expectedIRTypePtr = PointerType(pointee: expectedIRType)
    if type.asLLVM() == expectedIRTypePtr.asLLVM() {
      return builder.buildLoad(variable, type: type.pointee)
    } else if type.asLLVM() == expectedIRType.asLLVM() {
      return variable
    } else {
      throw IRError.unknownType(expectedType.name)
    }
  }
  
  func stringPrintFormat() -> IRValue {
    guard let format = module.global(named: "StringPrintFormat") else {
      return builder.buildGlobalStringPtr("%s\n", name: "StringPrintFormat")
    }
    return format.constGEP(indices: [IntType.int1.zero(), IntType.int1.zero()])
  }
}

extension StoredType {
  func findType(types: [String: CallableType]) throws -> IRType {
    if let type = IRType {
      return type
    }
    guard let typeDef = types[name],
      let type = typeDef.IRType else {
      throw IRError.unknownType(name)
    }
    IRType = type
    return type
  }
  
  func findRef(types: [String: CallableType]) throws -> IRType {
    if let ref = IRRef {
      return ref
    }
    guard let typeDef = types[name],
      let ref = typeDef.IRRef else {
        throw IRError.unknownType(name)
    }
    IRRef = ref
    return ref
  }
}

extension IRValue {
  func truthify(builder: IRBuilder) throws -> IRValue {
    if let truthVal = self.type.truthify(value:self, with: builder) {
      return truthVal
    }
    throw IRError.nonTruthyType(self.type)
  }
}

extension IRType {
  func truthify(value: IRValue, with builder: IRBuilder) -> IRValue? {
    if let truthable = self as? Truthable {
      return truthable.truthy(value: value, with: builder)
    }
    return nil
  }
  
  func getResolvedType() -> IRType {
    var type: IRType = self
    while let pointer = type as? PointerType {
      type = pointer.pointee
    }
    return type
  }
}

protocol Truthable {
  func truthy(value: IRValue, with builder: IRBuilder) -> IRValue
}

extension FloatType: Truthable {
  func truthy(value: IRValue, with builder: IRBuilder) -> IRValue {
    return builder.buildFPToInt(value, type: .int1, signed: false)
  }
}

extension IntType: Truthable {
  func truthy(value: IRValue, with builder: IRBuilder) -> IRValue {
    return value
  }
}

protocol Printable {
  func printFormat(module: Module, builder: IRBuilder) -> IRValue
}

extension IntType: Printable {
  func printFormat(module: Module, builder: IRBuilder) -> IRValue {
    guard let format = module.global(named: "IntPrintFormat") else {
      return builder.buildGlobalStringPtr("%d\n", name: "IntPrintFormat")
    }
    return format.constGEP(indices: [IntType.int1.zero(), IntType.int1.zero()])
  }
}

extension FloatType: Printable {
  func printFormat(module: Module, builder: IRBuilder) -> IRValue {
    guard let format = module.global(named: "FloatPrintFormat") else {
      return builder.buildGlobalStringPtr("%f\n", name: "FloatPrintFormat")
    }
    return format.constGEP(indices: [IntType.int1.zero(), IntType.int1.zero()])
  }
}


