//
//  WebSocketController.swift
//  App
//
//  Created by Podvorniy Ivan on 27.05.2020.
//



import Vapor
import Fluent


struct WebSocketController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let coursesRoute = routes.grouped("ws")
        let tokenProtected = coursesRoute.grouped(Token.authenticator())
        tokenProtected.webSocket("") { req, ws in
            
            if let user = try? req.auth.require(User.self) {
                ws.send("AUTH_SUCCESS \(user.username)" )
            } else {
                ws.send("AUTH_FAILED")
                ws.close()
            }
            
            ws.onText { ws, text in
                ws.send(text)
            }
            ws.onText { ws, text in
                ws.send("Hi \(text)")
            }
            ws.onClose.whenComplete { result in
                print("Dissconnect")
            }
        }
    }

    
}
