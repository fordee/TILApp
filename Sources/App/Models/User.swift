//
//  File.swift
//  
//
//  Created by John Forde on 23/04/22.
//

import Vapor
import Fluent
import Foundation

final class User: Model {
  @ID
  var id: UUID?

  @Field(key: "name")
  var name: String

  @Field(key: "username")
  var username: String

  @Field(key: "password")
  var password: String

  @Children(for: \.$user)
  var acronyms: [Acronym]

  init() {}

  init(id: UUID? = nil, name: String, username: String, password: String) {
    self.id = id
    self.name = name
    self.username = username
    self.password = password
  }

  struct Public: Content {
    let id: UUID?
    let name: String
    let username: String
  }

  static var schema: String = "users"
}

extension User: Content {}

extension User {
  func convertToPublic() -> User.Public {
    return Public(id: id, name: name, username: username)
  }
}

extension Collection where Element: User {
  func convertToPublic() -> [User.Public] {
    self.map { $0.convertToPublic() }
  }
}

extension User: ModelAuthenticatable {
  static let usernameKey = \User.$username
  static let passwordHashKey = \User.$password

  func verify(password: String) throws -> Bool {
    try Bcrypt.verify(password, created: self.password)
  }
}

extension User: ModelCredentialsAuthenticatable {}
extension User: ModelSessionAuthenticatable {}
