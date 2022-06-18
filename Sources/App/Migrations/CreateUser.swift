//
//  File.swift
//  
//
//  Created by John Forde on 23/04/22.
//

import Fluent

struct CreateUser: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema("users")
      .id()
      .field("name", .string, .required)
      .field("username", .string, .required)
      .field("password", .string, .required)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("users").delete()
  }
}
