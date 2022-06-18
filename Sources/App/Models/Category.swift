//
//  File.swift
//  
//
//  Created by John Forde on 23/04/22.
//

import Vapor
import Fluent
import Foundation

final class Category: Model {
  @ID
  var id: UUID?

  @Field(key: "name")
  var name: String

  @Siblings(through: AcronymCategoryPivot.self, from: \.$category, to: \.$acronym)
  var acronyms: [Acronym]

  init() {}

  init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
  }

  static var schema: String = "categories"
}

extension Category: Content {}
