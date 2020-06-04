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

struct BotChatCreation: Content {
    let botID: UUID
    let name: String
    let about: String
    let courseID: UUID
}

struct BotChatDeletion: Content {
    let botID: UUID
    let chatID: UUID
}

struct BotChatUserAdding: Content {
    let botID: UUID
    let chatID: UUID
    let userID: UUID
    let status: ChatPermission
}

struct AddBot: Content {
    let botID: UUID
    let courseID: UUID
    let newBotID: UUID
}

struct BotConnection: Content {
    let botID: UUID
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
        
        let chatOperation = coursesRoute.grouped("chats")
        chatOperation.post("create", use: createChat)
        chatOperation.post("delete", use: deleteChat)
        chatOperation.post("add", use: addMemberToChat)
        
        coursesRoute.webSocket("ws", onUpgrade: connectToWebSocket)
        
    }
    
    func createBot(req: Request) throws -> EventLoopFuture<Bot> {
        let user = try req.auth.require(User.self)
        let botContent = try req.content.decode(BotSignUp.self)
        if (user.apiLevel == .admin) {
            let newBot = Bot(name: botContent.name, about: botContent.about, ownerID: user.id!)
            return newBot.save(on: req.db).map {
                    newBot
            }.flatMapThrowing {
                let newUser = User(id: newBot.id!, username: newBot.name, name: "Бот \(newBot.name)", surname: "", passwordHash: try Bcrypt.hash(newBot.name + "password"), isAdmin: false, apiLevel: .noAccess)
                newUser.save(on: req.db)
            }.map { newBot }
        }
        return req.eventLoop.makeFailedFuture(Abort(.forbidden))
    }
    
    func createChat(req: Request) throws -> EventLoopFuture<Chat> {
        let chatInformation = try req.content.decode(BotChatCreation.self)
        return try checkAccessToCourse(req: req, botID: chatInformation.botID, courseID: chatInformation.courseID).flatMap { access in
            guard access else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden))
            }
            let new_chat = Chat(name: chatInformation.name, about: chatInformation.about, courseID: chatInformation.courseID, botID: chatInformation.botID)
            return new_chat.save(on: req.db).map {
                new_chat
            }
            
        }
    }
    
    func deleteChat(req: Request) throws -> EventLoopFuture<Chat> {
        let chatInformation = try req.content.decode(BotChatDeletion.self)
        return Chat
            .find(chatInformation.chatID, on: req.db).unwrap(or: Abort(.notFound))
            .flatMap { chat in
                guard chat.bot.id == chatInformation.botID else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden))
                }
                return chat.delete(on: req.db).map {chat}
        }
        
    }
    
    func addMemberToChat(req: Request) throws -> EventLoopFuture<ChatMember> {
        let chatInformation = try req.content.decode(BotChatUserAdding.self)
        return  Chat
            .find(chatInformation.chatID, on: req.db).unwrap(or: Abort(.notFound))
            .flatMap { chat in
                guard chat.$bot.id == chatInformation.botID else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden))
                }
                return User.find(chatInformation.userID, on: req.db).unwrap(or: Abort(.notFound)).flatMap { user in
                    let new_member = ChatMember(chatID: chatInformation.chatID, userID: chatInformation.userID, courseID: chat.$course.id, permission: chatInformation.status)
                    return new_member.save(on: req.db).map {new_member}
                }
        }
    }
    
    func addBotToCourse(req: Request) throws -> EventLoopFuture<BotMember> {
        let newInformation = try req.content.decode(AddBot.self)
        return try checkAccessToCourse(req: req, botID: newInformation.botID, courseID: newInformation.courseID).flatMap { access in
            guard access else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden))
            }
            let new_bot_member = BotMember(courseID: newInformation.courseID, botID: newInformation.newBotID)
            return new_bot_member.save(on: req.db).map {
                new_bot_member
            }
        }
    }
    
    func checkAccessToCourse(req: Request, botID : UUID, courseID: UUID) throws -> EventLoopFuture<Bool> {
        return BotMember
            .query(on: req.db)
            .filter(\.$bot.$id == botID)
            .filter(\.$course.$id == courseID)
            .first()
            .map {$0 != nil}
    }
    
    
    func connectToWebSocket(req: Request, ws: WebSocket) {
        if let token = try? req.content.decode(BotConnection.self).botID {
            Bot.find(token, on: req.db).map { exists in
                guard exists == nil else {
                    ws.send("AUTH_SUCCESS")
                    ws.onClose.whenComplete {_ in
                        self.controller.deleteBotConnection(botID: token)
                    }
                    self.controller.addBotConnection(botID: token, ws: ws)
                    return
                }
                ws.send("AUTH_FAILD")
                ws.close()
            }
        }
        else {
            ws.send("AUTH_FAILD")
            ws.close();
        }
    }
    
    
}

enum EventType: String, Codable {
    case message
    case join
    case add
}

struct MessageEvent: Content {
    let type: EventType
    let data: Message.PublicBot
}

struct JoinEvent: Content {
    let type: EventType
    let data: CourseMember.PublicBot
}

struct AddEvent: Content {
    let type: EventType
    let data: Course.Public
}

public class WebSocketBotController {
    var botSockets = [UUID : WebSocket]()
    var userSockets = [UUID : WebSocket]()
    var userRequests = [UUID : Request]()
    var userChats = [UUID : UUID]()
    
    init() {}
    
    func addBotConnection(botID: UUID, ws: WebSocket){
        botSockets[botID] = ws
    }
    
    func addUserConnection(userID: UUID, ws: WebSocket, req: Request){
        userSockets[userID] = ws
        userRequests[userID] = req
    }
    
    func deleteBotConnection(botID: UUID) {
        botSockets[botID] = nil
    }
    
    func deleteUserConnection(userID: UUID) {
        userChats[userID] = nil
        userSockets[userID] = nil
        userRequests[userID] = nil
    }
    
    func userSelectChat(userID: UUID, chatID: UUID) {
        userChats[userID] = chatID
    }
    
    func getChatByUser(userID: UUID) -> UUID? {
        return userChats[userID]
    }
    
    func sendMessageToChat(message: Message, chatID: UUID, req: Request) throws {
        let encoder = JSONEncoder()
        try message.asPublic(req: req).map { messagePublic in
            let data = try! encoder.encode(MessageEvent(type: .message, data: messagePublic))
            let dataString = String(data: data, encoding: .utf8) ?? "{}"
            self.sendDataToChat(chatID: chatID, dataString: dataString, req: req, toBot: message.soureType == .user)
        }
        
    }
    
    func userJoinToCourse(member: CourseMember, req: Request) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(JoinEvent(type: .message, data: member.asPublicBot()))
        let dataString = String(data: data, encoding: .utf8) ?? "{}"
        sendDataToCourse(courseID: member.course.id!, dataString: dataString, req: req)
    }
    
    func sendDataToChat(chatID: UUID, dataString: String, req: Request, toBot: Bool = true) {
        
        Chat.query(on: req.db).filter(\.$id == chatID).first().unwrap(or: Abort(.notFound)).map { chat in
            chat.$users.query(on: req.db).all().map {
                $0.map {user in
                    if (self.userChats[user.id!] == chatID && self.userSockets[user.id!] != nil) {
                        self.userSockets[user.id!]!.send(dataString)
                    }
                }
            }
            if (toBot) {
                chat.$bot.query(on: req.db).all().map {
                    $0.map {bot in
                        if (self.botSockets[bot.id!] != nil) {
                            self.botSockets[bot.id!]!.send(dataString)
                        }
                    }
                }
            }
            
        }
        
    }
    
    func sendDataToCourse(courseID: UUID, dataString: String, req: Request, toBot: Bool = true) {
        if (toBot) {
            Course.find(courseID, on: req.db).unwrap(or: Abort(.notFound)).map {
                $0.$bots.query(on: req.db).all().map {
                    $0.map { bot in
                        if (self.botSockets[bot.id!] != nil) {
                            self.botSockets[bot.id!]!.send(dataString)
                        }
                    }
                }
            }
        }
    }
}
