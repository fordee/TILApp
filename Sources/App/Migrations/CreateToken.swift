//
//  File.swift
//  
//
//  Created by John Forde on 24/04/22.
//

import Fluent

struct CreateToken: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema("tokens")
      .id()
      .field("value", .string, .required)
      .field("userID", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("tokens").delete()
  }
}
