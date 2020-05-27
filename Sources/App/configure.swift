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
    
    app.webSocket("ws") { (req: Request, ws: WebSocket) -> () in
        if let result = try? req.auth.require(User.self).asPublic() {
            ws.send("AUTH_SUCCESS")
        } else {
            ws.send("AUTH_FAILED")
            ws.close()
        }
        
        ws.onText { ws, text in
            ws.send(text)
        }
        
        ws.onClose.whenComplete { result in
            print("Dissconnect")
        }
    }
    
    // register routes
    try routes(app)
}
