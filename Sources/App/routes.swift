import Fluent
import Vapor

func routes(_ app: Application) throws {
    let webSocketController = WebSocketBotController()
    try app.register(collection: UserController())
    try app.register(collection: CourseController(controller: webSocketController))
    try app.register(collection: ChatController(controller: webSocketController))
    try app.register(collection: BotController(controller: webSocketController))
}
