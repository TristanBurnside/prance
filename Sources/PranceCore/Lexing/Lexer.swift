#if os(macOS)
  import Darwin
#elseif os(Linux)
  import Glibc
#endif

import Foundation

struct FilePosition {
  let line: Int
  let position: Int
}

extension Character {
  var value: Int32 {
    return Int32(String(self).unicodeScalars.first!.value)
  }
  var isSpace: Bool {
    return isspace(value) != 0
  }
  var isAlphanumeric: Bool {
    return isalnum(value) != 0 || self == "_"
  }
}

class Lexer {
  
  var nextTokenStartPos = FilePosition(line: 1, position: 1)
  var currentPos = FilePosition(line: 1, position: 1)
  
  let generators: [TokenGenerator] = [WhitespaceTokenGenerator(),
                                      InlineCommentTokenGenerator(),
                                      MultiCharTokenGenerator(),
                                      SingleCharTokenGenerator(),
                                      StringLiteralTokenGenerator(),
                                      FloatLiteralTokenGenerator(),
                                      DoubleLiteralTokenGenerator(),
                                      IntegerLiteralTokenGenerator(),
                                      IdentifierGenerator()]
  
  init() {
  }

  func lex(input: String) throws -> [TokenMarker] {
    let tokens = try input.compactMap { try self.getToken(for: $0) }
    let activeTokens = tokens.filter { $0.token.isExecutable }
    return activeTokens
  }
  
  private func getToken(for char: Character) throws -> TokenMarker? {
    if char == "\n" {
      currentPos = FilePosition(line: currentPos.line+1, position: 1)
    } else {
      currentPos = FilePosition(line: currentPos.line, position: currentPos.position + 1)
    }
    let previouslyValidGenerators = generators.filter { $0.isValid }
    let validGenerators = previouslyValidGenerators.filter {
        $0.consume(char: char)
        return $0.isValid
      }
    if validGenerators.isEmpty {
      guard let token = try? previouslyValidGenerators.first(where: { $0.isComplete })?.emitToken() else {
        throw LexError.unexpectedSymbol
      }
      generators.forEach { $0.reset() }
      generators.forEach { $0.consume(char: char)}
      let pos = nextTokenStartPos
      nextTokenStartPos = currentPos
      return TokenMarker(token: token, marker: pos)
    }
    return nil
  }
}

enum LexError: Error {
  case unexpectedSymbol
}
