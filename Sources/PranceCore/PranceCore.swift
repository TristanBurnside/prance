import Foundation
import LLVM

extension String: Error {}

public struct PranceCompiler {
  
  static func shellExecute(_ args: String...) throws {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    if (task.terminationStatus != 0) {
      var errFileHandle: FileHandle?
      if let errStream = task.standardError as? FileHandle {
        errFileHandle = errStream
      }
      if let errStream = task.standardError as? Pipe {
        errFileHandle = errStream.fileHandleForReading
      }
      throw String(data: errFileHandle!.availableData, encoding: .ascii) ?? ""
    }
  }
  
  public static func run() throws {
    guard CommandLine.arguments.count > 1 else {
      throw "usage: Prance <file>"
    }
    
    let path = URL(fileURLWithPath: CommandLine.arguments[1])
    let input = try String(contentsOf: path, encoding: .utf8)
    let toks = try Lexer().lex(input: input)
    let file = try Parser(tokens: toks).parseFile()
    try TypeResolver(file: file).resolveTypes()
    let irGen = IRGenerator(file: file)
    try irGen.emit()
    let llPath = path.deletingPathExtension().appendingPathExtension("ll")
    if FileManager.default.fileExists(atPath: llPath.path) {
      try FileManager.default.removeItem(at: llPath)
    }
    FileManager.default.createFile(atPath: llPath.path, contents: nil)
    try irGen.module.print(to: llPath.path)
    print("Successfully wrote LLVM IR to \(llPath.lastPathComponent)")
    
    try irGen.module.verify()
    
    let objPath = path.deletingPathExtension().appendingPathExtension("o")
    if FileManager.default.fileExists(atPath: objPath.path) {
      try FileManager.default.removeItem(at: objPath)
    }
    
    let targetMachine = try TargetMachine()
    try targetMachine.emitToFile(module: irGen.module,
                                 type: .object,
                                 path: objPath.path)
    print("Successfully wrote binary object file to \(objPath.lastPathComponent)")
    
    let execPath = path.deletingPathExtension()
    if FileManager.default.fileExists(atPath: execPath.path) {
      try FileManager.default.removeItem(at: execPath)
    }
    
    try shellExecute("clang", objPath.path, "-o", execPath.path)
  }
}
