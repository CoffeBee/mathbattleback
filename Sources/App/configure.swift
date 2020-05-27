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
    // Create a new NIO websocket server
    
    app.webSocket("ws") { req, ws in
        ws.onText { ws, text in
            ws.send(text)
        }
        ws.send("fd");
        print(ws)
    }
    
    // register routes
    try routes(app)
}
