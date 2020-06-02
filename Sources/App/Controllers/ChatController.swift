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

struct SendMessage: Content {
    let text: String
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
        tokenProtected.get("select", use: selectChat)
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
    
    
    func sendMessage(req: Request) throws -> EventLoopFuture<Message> {
        let user = try req.auth.require(User.self)
        let text = try req.content.decode(SendMessage.self).text
        if let chat = self.controller.getChatByUser(user: user) {
            let new_message = Message(chatID: chat.id!, user_ownerID: user.id!, bot_ownerID: nil, text: text)
            return new_message.save(on: req.db).map {
                try! self.controller.sendMessageToChat(message: new_message)
                return new_message
            }
        }
        else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }
        
    }
    
    func selectChat(req: Request) throws -> EventLoopFuture<Chat> {
        let user = try req.auth.require(User.self)
        let userID = user.id!
        let chatID = try req.content.decode(ChatJoing.self).id
        return try isUserInChat(userID : userID, chatID: chatID, req: req).flatMap {exists in
            guard exists else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden))
            }
            return Chat
                .query(on: req.db)
                .filter(\.$id == chatID).with(\.$messages).first()
                .unwrap(or: Abort(.notFound))
                .map { chat in
                    self.controller.userSelectChat(user: user, chat: chat)
                    return chat
            }
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
