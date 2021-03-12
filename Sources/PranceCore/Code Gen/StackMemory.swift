import LLVM

final class StackMemory<Value> {
  private var frames: [StackFrame<Value>]
  
  init() {
    frames = []
  }
  
  func addStatic(name: String, value: Value) {
    frames.last?.statics[name] = value
  }
  
  func addVariable(name: String, value: Value) {
    frames.last?.variables[name] = value
  }
  
  func findVariable(name: String) throws -> Value {
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
  
  func containsInCurrentFrame(_ name: String) -> Bool {
    if frames.last?.variables[name] != nil {
      return true
    }
    if frames.last?.statics[name] != nil {
      return true
    }
    return false
  }
  
  func startFrame() {
    frames.append(StackFrame<Value>())
  }
  
  func endFrame() {
    frames.removeLast()
  }
}

final class StackFrame<Value> {
  var statics: [String: Value]
  var variables: [String: Value]
  
  init() {
    statics = [:]
    variables = [:]
  }
}
