//
//  TokenGenerator.swift
//  PranceCore
//
//  Created by Tristan Burnside on 6/9/19.
//

import Foundation

protocol TokenGenerator {
  func consume(char: Character)
  func emitToken() throws -> Tokenizable
  func reset()
  
  var isValid: Bool { get }
  var isComplete: Bool { get }
}
