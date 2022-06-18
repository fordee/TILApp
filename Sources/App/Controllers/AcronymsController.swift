//
//  File.swift
//  
//
//  Created by John Forde on 23/04/22.
//

import Vapor
//import os
import Fluent

struct AcronymsController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let acronymsRoute = routes.grouped("api", "acronyms")
    acronymsRoute.get(use: getAllHandler)
    //acronymsRoute.post(use: createHander)
    acronymsRoute.get(":acronymID", use: getHandler)
    //acronymsRoute.delete(":acronymID", use: deleteHandler)
    //acronymsRoute.put(":acronymID", use: updateHandler)
    acronymsRoute.get(":acronymID", "user", use: getUserHandler)
    acronymsRoute.get(":acronymID", "categories", use: getCategoriesHandler)
    //acronymsRoute.post(":acronymID", "categories", ":categoryID", use: addCategoriesHandler)
    acronymsRoute.get("search", use: searchHandler)

    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let tokenAuthGroup = acronymsRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)

    tokenAuthGroup.post(use: createHander)
    tokenAuthGroup.delete(":acronymID", use: deleteHandler)
    tokenAuthGroup.put(":acronymID", use: updateHandler)
    tokenAuthGroup.post(":acronymID", "categories", ":categoryID", use: addCategoriesHandler)
  }

  func getAllHandler(_ req: Request) async throws -> [Acronym] {
    try await Acronym.query(on: req.db).all()
  }

  func createHander(_ req: Request) async throws -> Acronym {
    let data = try req.content.decode(CreateAcronymData.self)
    let user = try req.auth.require(User.self)
    let acronym = try Acronym(short: data.short, long: data.long, userID: user.requireID())
    try await acronym.save(on: req.db)
    return acronym
  }

  func getHandler(_ req: Request) async throws -> Acronym {
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else { throw Abort(.notFound) }
    return acronym
  }

  func deleteHandler(_ req: Request) async throws -> HTTPStatus {
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else { throw Abort(.notFound) }
    try await acronym.delete(on: req.db)
    return .ok
  }

  func updateHandler(_ req: Request) async throws -> Acronym {
    let updatedAcronym = try req.content.decode(CreateAcronymData.self)
    let user = try req.auth.require(User.self)
    let userID = try user.requireID()
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else { throw Abort(.notFound) }
    acronym.short = updatedAcronym.short
    acronym.long = updatedAcronym.long
    acronym.$user.id = userID
    try await acronym.save(on: req.db)
    return acronym
  }

  func getUserHandler(_ req: Request) async throws -> User.Public {
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else { throw Abort(.notFound) }
    return try await acronym.$user.get(on: req.db).convertToPublic()
  }

  func getCategoriesHandler(_ req: Request) async throws -> [Category] {
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else { throw Abort(.notFound) }
    return try await acronym.$categories.get(on: req.db)
  }

  func addCategoriesHandler(_ req: Request) async throws -> HTTPStatus {
    guard let acronymQuery = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else { throw Abort(.notFound) }
    guard let categoryQuery = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound) }
    try await acronymQuery.$categories.attach(categoryQuery, on: req.db)
    return .ok
  }

  func searchHandler(_ req: Request) async throws -> [Acronym] {
    guard let searchTerm = req.query[String.self, at: "term"] else { throw Abort(.badRequest) }
    return try await Acronym.query(on: req.db).group(.or) { or in
      or.filter(\.$short == searchTerm)
      or.filter(\.$long == searchTerm)
    }.all()
  }
}

struct CreateAcronymData: Content {
  var short: String
  var long: String
}
