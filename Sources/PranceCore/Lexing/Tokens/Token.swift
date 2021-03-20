//
//  Token.swift
//  PranceCore
//
//  Created by Tristan Burnside on 6/9/19.
//

import Foundation

protocol Tokenizable {
  var isExecutable: Bool { get }
}

extension Tokenizable {
  var isExecutable: Bool { return true }
}

struct LeftParenToken: Tokenizable {}
struct RightParenToken: Tokenizable {}
struct CommaToken: Tokenizable {}
struct SemicolonToken: Tokenizable {}
struct ColonToken: Tokenizable {}
struct LeftBraceToken: Tokenizable {}
struct RightBraceToken: Tokenizable {}
struct AssignToken: Tokenizable {}
struct MemberReferenceToken: Tokenizable {}
struct FunctionToken: Tokenizable {}
struct ExternToken: Tokenizable {}
struct VariableToken: Tokenizable {}
struct TypeToken: Tokenizable {}
struct ProtocolToken: Tokenizable {}
struct ExtensionToken: Tokenizable {}
struct DefaultToken: Tokenizable {}
struct IfToken: Tokenizable {}
struct ThenToken: Tokenizable {}
struct ElseToken: Tokenizable {}
struct ReturnToken: Tokenizable {}
struct ForToken: Tokenizable {}
struct WhileToken: Tokenizable {}
struct IdentifierToken: Tokenizable {
  let name: String
}
struct LiteralToken: Tokenizable {
  let type: LiteralType
}
struct OperatorToken: Tokenizable {
  let type: BinaryOperator
}
struct LogicalOperatorToken: Tokenizable {
  let type: LogicalOperator
}
struct WhitespaceToken: Tokenizable {
  var isExecutable: Bool { return false }
}
struct CommentToken: Tokenizable {
  var isExecutable: Bool { return false }
}

enum BinaryOperator: UnicodeScalar {
  case plus = "+", minus = "-",
  times = "*", divide = "/",
  mod = "%"
}

enum LogicalOperator: String {
  case and = "&&"
  case or = "||"
  case equals = "=="
  case notEqual = "!="
  case lessThan = "<"
  case lessThanOrEqual = "<="
  case greaterThan = ">"
  case greaterThanOrEqual = ">="
}

enum LiteralType {
  case float(Float)
  case double(Double)
  case integer(Int)
  case string([StringPart])
}

enum StringPart {
  case string(String)
  case interpolated([Tokenizable])
}
