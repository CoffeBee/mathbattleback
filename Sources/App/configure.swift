import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory)
    
    
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        username: Environment.get("DATABASE_USERNAME") ?? "podvorniy",
        password: Environment.get("DATABASE_PASSWORD") ?? "Podvorniy1303©",
        database: Environment.get("DATABASE_NAME") ?? "vapor"
        ), as: .psql)
    
    app.migrations.add(CreateUsers())
    app.migrations.add(CreateTokens())
    app.migrations.add(AddAdminFieldUsers())
    app.migrations.add(CreateCourses())
    app.migrations.add(CreateCourseMembers())
    app.migrations.add(AddStatusFieldCourseMember())
    app.migrations.add(CreateChats())
    
    // register routes
    try routes(app)
}
