import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "I love silaedr"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    try app.register(collection: TodoController())
    try app.register(collection: UserController())
}
