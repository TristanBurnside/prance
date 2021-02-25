import LLVM

final class StackMemory {
  private var frames: [StackFrame]
  
  init() {
    frames = []
  }
  
  func addStatic(name: String, value: IRValue, type: StoredType) {
    frames.last?.statics[name] = (value, type)
  }
  
  func addVariable(name: String, type: StoredType, value: IRValue?) {
    frames.last?.variables[name] = (value, type)
  }
  
  func findVariable(name: String) throws -> (IRValue?, StoredType) {
    for frame in frames.reversed() {
      if let variableRef = frame.variables[name] {
        return variableRef
      }
      if let variableRef = frame.statics[name] {
        return variableRef
      }
    }
    throw IRError.unknownVariable(name)
  }
  
  func startFrame() {
    frames.append(StackFrame())
  }
  
  func endFrame() {
    frames.removeLast()
  }
}

final class StackFrame {
  var statics: [String: (IRValue, StoredType)]
  var variables: [String: (IRValue?, StoredType)]
  
  init() {
    statics = [:]
    variables = [:]
  }
}
