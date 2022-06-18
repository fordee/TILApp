//
//  File.swift
//  
//
//  Created by John Forde on 23/04/22.
//

import Vapor

struct CategoriesController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let categoriesRoute = routes.grouped("api", "categories")
    categoriesRoute.get(use: getAllHandler)
    categoriesRoute.post(use: createHander)
    categoriesRoute.get(":categoryID", use: getHandler)
    categoriesRoute.delete(":categoryID", use: deleteHandler)
    categoriesRoute.put(":categoryID", use: updateHandler)
    categoriesRoute.get(":categoryID", "acronyms", use: getAcronymsHandler)
  }

  func getAllHandler(_ req: Request) async throws -> [Category] {
    try await Category.query(on: req.db).all()
  }

  func createHander(_ req: Request) async throws -> Category {
    let user = try req.content.decode(Category.self)
    try await user.save(on: req.db)
    return user
  }

  func getHandler(_ req: Request) async throws -> Category {
    guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound) }
    return category
  }

  func deleteHandler(_ req: Request) async throws -> HTTPStatus {
    guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound) }
    try await category.delete(on: req.db)
    return .ok
  }

  func updateHandler(_ req: Request) async throws -> Category {
    let updatedCategory = try req.content.decode(Category.self)
    guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound) }
    category.name = updatedCategory.name
    try await category.save(on: req.db)
    return category
  }

  func getAcronymsHandler(_ req: Request) async throws -> [Acronym] {
    guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound) }
    return try await category.$acronyms.get(on: req.db)
  }

}
