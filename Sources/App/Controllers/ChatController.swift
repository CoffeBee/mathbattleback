//
//  WebSocketController.swift
//  App
//
//  Created by Podvorniy Ivan on 27.05.2020.
//



import Vapor
import Fluent

enum SocketState: String {
    case noChat
    case chat
    case bot
}


struct ChatJoing: Content {
    let id: UUID
}
struct ChatController: RouteCollection {
    
    let controller : WebSocketBotController
    
    init(controller : WebSocketBotController) {
        self.controller = controller
    }
    
    func boot(routes: RoutesBuilder) throws {
        let coursesRoute = routes.grouped("chat")
        let tokenProtected = coursesRoute.grouped(Token.authenticator())
        tokenProtected.webSocket("", onUpgrade: webSocketConnect)
    }
    
    func webSocketConnect(req : Request, ws : WebSocket) {
        if let user = try? req.auth.require(User.self) {
            self.controller.addUserConnection(user: user, ws: ws, req: req)
            ws.onClose.whenComplete {_ in
                self.controller.deleteUserConnection(user: user)
            } 
            ws.send("AUTH_SUCCESS \(user.username)")
            return
        }
        ws.send("AUTH_FAILED")
        ws.close()
    
    }
    
    
    
    func selectChat(req: Request) throws -> EventLoopFuture<Chat> {
        let userID = try req.auth.require(User.self).id!
        let chatID = try req.content.decode(ChatJoing.self).id
        return try isUserInChat(userID : userID, chatID: chatID, req: req).flatMap {exists in
            guard !exists else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden))
            }
            return ChatMember
                .query(on: req.db)
                .filter(\.$chat.$id == chatID)
                .filter(\.$user.$id == userID)
                .first()
                .unwrap(or: Abort(.notFound))
                .map { $0.chat }
        }
    }
    
    
    func isUserInChat(userID : UUID, chatID : UUID, req: Request) throws -> EventLoopFuture<Bool> {
        
        return ChatMember
            .query(on: req.db)
            .filter(\.$chat.$id == chatID)
            .filter(\.$user.$id == userID)
            .first()
            .map { $0 != nil }
    }
    
}
