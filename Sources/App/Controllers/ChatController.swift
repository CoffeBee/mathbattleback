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
        tokenProtected.post("select", use: selectChat)
        tokenProtected.post("send", use: sendMessage)
        coursesRoute.webSocket("", onUpgrade: webSocketConnect)
    }
    
    func webSocketConnect(req : Request, ws : WebSocket) {
       ws.onText { ws, text in
            Token.query(on: req.db).filter(\.$value == text).with(\.$user).first().map { t in
                if let token = t {
                    self.controller.addUserConnection(userID: token.user.id!, ws: ws, req: req)
                    ws.onClose.whenComplete {_ in
                        self.controller.deleteUserConnection(userID: token.user.id!)
                    }
                    ws.send("AUTH_SUCCESS \(token.user.username)")
                    return
                }else {
                    ws.send("AUTH_FAILED")
                    ws.close()
                }
                
            }
        }
    }
    
    
    func sendMessage(req: Request) throws -> EventLoopFuture<Message> {
        let user = try req.auth.require(User.self)
        let text = try req.content.decode(SendMessage.self).text
        
        if let chat = self.controller.getChatByUser(userID: user.id!) {
            let new_message = Message(chatID: chat, user_ownerID: user.id!, status: .user, text: text)
            return new_message.save(on: req.db).map {
                try! self.controller.sendMessageToChat(message: new_message, chatID: chat, req: req)
                return new_message
            }
        }
        else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }
        
    }
    
    func selectChat(req: Request) throws -> EventLoopFuture<[Message.PublicBot]> {
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
                .flatMap { chat in
                    self.controller.userSelectChat(userID: user.id!, chatID: chatID)
                    return try! chat.$messages.query(on: req.db).with(\.$user_owner).all().map {
                        try! $0.flatMap {
                            try! $0.asPublicMessage()
                        }
                    }
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
