import PranceCore
import Foundation

typealias KSMainFunction = @convention(c) () -> Void

do {
  try PranceCompiler.run()
} catch {
  print("error: \(error)")
  exit(-1)
}
