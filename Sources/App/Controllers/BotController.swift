//
//  BotController.swift
//  App
//
//  Created by Podvorniy Ivan on 28.05.2020.
//


import Vapor
import Fluent

struct BotSignUp: Content {
    let name: String
    let about: String
}

struct BotController: RouteCollection {
    
    let controller : WebSocketBotController
    
    init(controller : WebSocketBotController) {
        self.controller = controller
    }
    
    func boot(routes: RoutesBuilder) throws {
        let coursesRoute = routes.grouped("bot")
        
        let tokenProtected = coursesRoute.grouped(Token.authenticator())
        tokenProtected.post("signup", use: createBot)
        
        
    }
    
    func createBot(req: Request) throws -> EventLoopFuture<Bot> {
        let user = try req.auth.require(User.self)
        let botContent = try req.content.decode(BotSignUp.self)
        if (user.apiLevel == .admin) {
            let newBot = Bot(name: botContent.name, about: botContent.about, ownerID: user.id!)
            return newBot.save(on: req.db)
                .map {
                    newBot
            }
        }
        return req.eventLoop.makeFailedFuture(Abort(.forbidden))
    }
    
    
    
    
}


public class WebSocketBotController {
    var botSockets = [Bot : WebSocket]()
    var userSockets = [User : WebSocket]()
    var userChats = [User : Chat]()
    
    init() {}
    
    func addBotConnection(bot: Bot, ws: WebSocket) -> Bool {
        if (botSockets[bot] == nil) {
            botSockets[bot] = ws
            return true
        }
        return false
    }
    
    func addUserConnection(user: User, ws: WebSocket) -> Bool {
        if (userSockets[user] == nil) {
            userSockets[user] = ws
            return true
        }
        return false
    }
    
    func selectChatToUser(chat: Chat, user: User) {
        userChats[user] = chat
    }
    
    
}
