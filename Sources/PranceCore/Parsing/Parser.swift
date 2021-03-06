protocol Expressable {
  // Creates an expression that starts at this expressable
  func express(tokenStream: TokenStream) throws -> Expr
}

protocol PostExpressable {
  // Creates an expression that must follow another expression
  func express(after previousExpr: Expr, tokenStream: TokenStream) throws -> Expr
}

protocol Definable {
  func create(from tokenStream: TokenStream) throws -> Definition
}

class TokenStream {
  
  private var currentIndex: Array<TokenMarker>.Index
  private let tokens: [TokenMarker]
  init(tokens: [TokenMarker]) {
    self.tokens = tokens
    currentIndex = tokens.startIndex
  }
  
  @discardableResult
  func next() -> TokenMarker? {
    guard currentIndex != tokens.endIndex else {
      return nil
    }
    let current = peek()
    currentIndex = tokens.index(after: currentIndex)
    return current
  }
  
  func peek() -> TokenMarker? {
    guard currentIndex < tokens.count else {
      return nil
    }
    return tokens[currentIndex]
  }
  
  // Unsafe, only call after first call and
  func previous() -> TokenMarker {
    currentIndex = tokens.index(before: currentIndex)
    return tokens[currentIndex]
  }
  
  func expressNext() throws -> Expr {
    guard let token = next()?.token as? Expressable else {
      throw ParseError.unexpectedEOF
    }
    var expr = try token.express(tokenStream: self)
    while peek()?.token is PostExpressable {
      let postToken = next()!.token as! PostExpressable
      expr = try postToken.express(after: expr, tokenStream: self)
    }
    return expr
  }
  
  func expressCurrent() throws -> Expr {
    currentIndex = tokens.index(before: currentIndex)
    return try expressNext()
  }
  
  func skip<T: Tokenizable>(_ token: T) throws {
    guard let tokenMarker = peek() else {
      throw ParseError.unexpectedEOF
    }
    guard tokenMarker.token is T else {
      return
    }
    next()
  }
}

class Parser {
  let tokenStream: TokenStream
  init(tokens: [TokenMarker]) {
    tokenStream = TokenStream(tokens: tokens)
  }
  
  func parseFile() throws -> File {
    let file = File()
    while let tok = tokenStream.next() {
      switch tok.token {
      case let definable as Definable:
        let definition = try definable.create(from: tokenStream)
        file.addDefinition(definition)
      case _ as Expressable:
        file.addExpression(try tokenStream.expressCurrent())
      default:
        throw ParseError.unexpectedToken(tok.token, tok.marker)
      }
    }
    return file
  }
}

enum ParseError: Error {
  case unexpectedToken(Tokenizable, FilePosition)
  case unexpectedEOF
  case invalidComparison(StoredType, StoredType, FilePosition)
  case invalidOperation(StoredType, StoredType, FilePosition)
  case undefinedType(String, FilePosition)
  case unableToAssignTo(Expr, FilePosition)
  case unknownProtocol(String, in: String)
  case unimplementedProtocol(String, in: String, missing: String)
  case typeDoesNotContainMembers(String)
}

extension String {
  var types: [StoredType.Type] {
    return [DoubleStore.self, IntStore.self, FloatStore.self, StringStore.self, CustomStore.self]
  }
  
  func toType() -> StoredType? {
    for type in types {
      if let store = type.init(name: self) {
        return store
      }
    }
    return nil
  }
}
