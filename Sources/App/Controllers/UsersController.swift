//
//  File.swift
//  
//
//  Created by John Forde on 23/04/22.
//

import Vapor

struct UsersController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
      let usersRoutes = routes.grouped("api", "users")
      usersRoutes.post(use: createHandler)
      usersRoutes.get(use: getAllHandler)
      usersRoutes.get(":userID", use: getHandler)
      usersRoutes.get(":userID", "acronyms", use: getAcronymsHandler)

      let basicAuthMiddleware = User.authenticator()
      let basicAuthGroup = usersRoutes.grouped(basicAuthMiddleware)
      basicAuthGroup.post("login", use: loginHandler)
  }

  func getAllHandler(_ req: Request) async throws -> [User.Public] {
    try await User.query(on: req.db).all().convertToPublic()
  }

  func createHandler(_ req: Request) async throws -> User.Public {
    let user = try req.content.decode(User.self)
    user.password = try Bcrypt.hash(user.password)
    try await user.save(on: req.db)
    return user.convertToPublic()
  }

  func getHandler(_ req: Request) async throws -> User.Public {
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else { throw Abort(.notFound) }
    return user.convertToPublic()
  }

  func deleteHandler(_ req: Request) async throws -> HTTPStatus {
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else { throw Abort(.notFound) }
    try await user.delete(on: req.db)
    return .ok
  }

  func updateHandler(_ req: Request) async throws -> User {
    let updatedUser = try req.content.decode(User.self)
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else { throw Abort(.notFound) }
    user.name = updatedUser.name
    user.username = updatedUser.username
    try await user.save(on: req.db)
    return user
  }

  func getAcronymsHandler(_ req: Request) async throws -> [Acronym] {
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else { throw Abort(.notFound) }
    return try await user.$acronyms.get(on: req.db)
  }

  func loginHandler(_ req: Request) async throws -> Token {
    let user = try req.auth.require(User.self)
    let token = try Token.generate(for: user)
    try await token.save(on: req.db)
    return token
  }

}

