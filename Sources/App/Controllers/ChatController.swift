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

struct ChatController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let coursesRoute = routes.grouped("chat")
        let tokenProtected = coursesRoute.grouped(Token.authenticator())
        tokenProtected.webSocket("", onUpgrade: webSocketConnect)
    }

    func webSocketConnect(req : Request, ws : WebSocket) {
        if let user = try? req.auth.require(User.self) {
            ws.send("AUTH_SUCCESS \(user.username)")
            self.setupChatSocket(ws: ws)
        } else {
            ws.send("AUTH_FAILED")
            ws.close()
        }
    }
    /*
    func selectChat(req: Request) throws -> EventLoopFuture<Chat> {
        let user = try req.auth.require(User.self)
        return Chat.
    }
    */
    func setupChatSocket(ws: WebSocket) {
        ws.onClose.whenComplete { result in
            
        }
        
        ws.onText { ws, text in
            ws.send("NO_CHAT")
        }
    }
}
