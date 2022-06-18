//
//  File.swift
//  
//
//  Created by John Forde on 24/04/22.
//

import Vapor
import Foundation

struct WebsiteController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
    authSessionsRoutes.get(use: indexHandler)
    authSessionsRoutes.get("index", use: indexHandler)
    authSessionsRoutes.get("acronyms", ":acronymID", use: acronymHandler)
    authSessionsRoutes.get("users", ":userID", use: userHandler)
    authSessionsRoutes.get("users", use: allUsersHandler)
    authSessionsRoutes.get("categories", ":categoryID", use: categoryHandler)
    authSessionsRoutes.get("categories", use: allCategoriesHandler)
    authSessionsRoutes.get("login", use: loginHandler)

    let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
    credentialsAuthRoutes.post("login", use: loginPostHandler)

    let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/login"))
    protectedRoutes.get("acronyms", "create", use: createAcronymHandler)
    protectedRoutes.post("acronyms", "create", use: createAcronymPostHandler)
    protectedRoutes.get("acronyms", ":acronymID", "edit", use: editAcronymHandler)
    protectedRoutes.post("acronyms", ":acronymID", "edit", use: editAcronymPostHandler)
    protectedRoutes.post("acronyms", ":acronymID", "delete", use: deleteAcronymHandler)
  }

  func indexHandler(_ req: Request) async throws -> View {
    let acronyms = try await Acronym.query(on: req.db).all()
    let context = IndexContext(title: "Homepage", acronyms: acronyms)
    return try await req.view.render("index", context)
  }

  func acronymHandler(_ req: Request) async throws -> View {
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else { throw Abort(.notFound) }
    let user = try await acronym.$user.get(on: req.db)
    let context = AcronymContext(title: "Acronym", acronym: acronym, user: user)
    //print("ContexT: \(context)")
    return try await req.view.render("acronym", context)
  }

  func userHandler(_ req: Request) async throws -> View {
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else { throw Abort(.notFound) }
    let acronyms = try await user.$acronyms.get(on: req.db)
    let context = UserContext(title: user.name, user: user, acronyms: acronyms)
    return try await req.view.render("user", context)
  }

  func allUsersHandler(_ req: Request) async throws -> View {
    let users = try await User.query(on: req.db).all()
    let context = AllUsersContext(title: "All Users", users: users.isEmpty ? [] : users)
    return try await req.view.render("allusers", context)
  }

  func allCategoriesHandler(_ req: Request) async throws -> View {
    let categories = try await Category.query(on: req.db).all()
    let context = AllCategoriesContext(title: "All Categories", categories: categories.isEmpty ? [] : categories)
    return try await req.view.render("allcategories", context)
  }

  func categoryHandler(_ req: Request) async throws -> View {
    guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound) }
    let acronyms = try await category.$acronyms.get(on: req.db)
    let context = CategoryContext(title: category.name, category: category, acronyms: acronyms)
    return try await req.view.render("category", context)
  }

  func createAcronymHandler(_ req: Request) async throws -> View {
    let context = CreateAcronymContext(title: "Create An Acronym")
    return try await req.view.render("createAcronym", context)
  }

  func createAcronymPostHandler(_ req: Request) async throws -> Response {
    let data = try req.content.decode(CreateAcronymData.self)
    let user = try req.auth.require(User.self)
    let acronym = try Acronym(short: data.short, long: data.long, userID: user.requireID())
    try await acronym.save(on: req.db)
    let id = try acronym.requireID()
    return req.redirect(to: "/acronyms/\(id)")
  }

  func editAcronymHandler(_ req: Request) async throws -> View {
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else { throw Abort(.notFound) }
    let context = EditAcronymContext(title: "Edit Acronym", acronym: acronym)
    print("Context: \(context.acronym.long)")
    return try await req.view.render("createAcronym", context)
  }

  func editAcronymPostHandler(_ req: Request) async throws -> Response {
    let updateData = try req.content.decode(CreateAcronymData.self)
    let user = try req.auth.require(User.self)
    let userID = try user.requireID()
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else { throw Abort(.notFound) }
    acronym.short = updateData.short
    acronym.long = updateData.long
    acronym.$user.id = userID
    try await acronym.save(on: req.db)
    let id = try acronym.requireID()
    return req.redirect(to: "/acronyms/\(id)")
  }

  func deleteAcronymHandler(_ req: Request) async throws -> Response {
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else { throw Abort(.notFound) }
    try await acronym.delete(on: req.db)
    return req.redirect(to: "/index")
  }

  func loginHandler(_ req: Request) async throws -> View {
    let context = LoginContext(title: "Log In")
    return try await req.view.render("login", context)
  }

  func loginPostHandler(_ req: Request) async throws -> Response {
    if req.auth.has(User.self) {
      print("Authorised *************************")
      return req.redirect(to: "/index")
    } else {
      print(try req.auth.require(User.self))
      print("NOT Authorised *************************")
      return try await req.view.render("login", LoginContext(title: "Log In")).encodeResponse(for: req)
    }
  }
}

struct IndexContext: Encodable {
  let title: String
  let acronyms: [Acronym]
}

struct AcronymContext: Encodable {
  let title: String
  let acronym: Acronym
  let user: User
}

struct UserContext: Encodable {
  let title: String
  let user: User
  let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
  let title: String
  let users: [User]
}

struct AllCategoriesContext: Encodable {
  let title: String
  let categories: [Category]
}

struct CategoryContext: Encodable {
  let title: String
  let category: Category
  let acronyms: [Acronym]
}

struct CreateAcronymContext: Encodable {
  let title: String
}

struct EditAcronymContext: Encodable {
  let title: String
  let acronym: Acronym
  let editing = true
}

struct LoginContext: Encodable {
  let title: String
}
