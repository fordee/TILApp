//
//  File.swift
//  
//
//  Created by John Forde on 23/04/22.
//

import Fluent

struct CreateCategory: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema("categories")
      .id()
      .field("name", .string, .required)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("categories").delete()
  }
}
