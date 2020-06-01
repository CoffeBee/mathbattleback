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
    let status: MemeberStatus
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
            return newBot.save(on: req.db)
                .map {
                    newBot
            }
        }
        return req.eventLoop.makeFailedFuture(Abort(.forbidden))
    }
    
    func createChat(req: Request) throws -> EventLoopFuture<Chat> {
        let chatInformation = try req.content.decode(BotChatCreation.self)
        return try checkAccessToCourse(req: req, botID: chatInformation.botID, courseID: chatInformation.courseID).flatMap { access in
            guard access else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden))
            }
            let new_chat = Chat(name: chatInformation.name, about: chatInformation.about, courseID: chatInformation.courseID)
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
                guard chat.bot.id == chatInformation.botID else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden))
                }
                return User.find(chatInformation.userID, on: req.db).unwrap(or: Abort(.notFound)).flatMap { user in
                    let new_member = ChatMember(chatID: chatInformation.chatID, userID: chatInformation.userID, courseID: chat.$course.id)
                    return new_member.save(on: req.db).map {new_member}
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
                        self.controller.deleteBotConnection(bot: exists!)
                    }
                    self.controller.addBotConnection(bot: exists!, ws: ws)
                    return
                }
                ws.send("AUTH_FAILD")
                ws.close()
            }
        }
        
    }
    
    
}

enum EventType: String, Codable {
    case message
    case join
    case connect
    case disconnet
}

struct MessageEvent: Content {
    let type: EventType
    let data: Message.PublicBot
}

struct JoinEvent: Content {
    let type: EventType
    let data: CourseMember.PublicBot
}


public class WebSocketBotController {
    var botSockets = [Bot : WebSocket]()
    var userSockets = [User : WebSocket]()
    var userRequests = [User : Request]()
    var userChats = [User : Chat]()
    
    init() {}
    
    func addBotConnection(bot: Bot, ws: WebSocket){
        botSockets[bot] = ws
    }
    
    func addUserConnection(user: User, ws: WebSocket, req: Request){
        userSockets[user] = ws
        userRequests[user] = req
    }
    
    func deleteBotConnection(bot: Bot) {
        botSockets[bot] = nil
    }
    
    func deleteUserConnection(user: User) {
        userChats[user] = nil
        userSockets[user] = nil
        userRequests[user] = nil
    }
    
    func userSelectChat(user: User, chat: Chat) {
        userChats[user] = chat
    }
    
    func getChatByUser(user: User) -> Chat? {
        return userChats[user]
    }
    
    func sendMessageToChat(message: Message) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(MessageEvent(type: .message, data: message.asPublic()))
        let dataString = String(data: data, encoding: .utf8) ?? "{}"
        sendDataToChat(chat: message.chat, dataString: dataString, toBot: message.soureType == .user)
    }
    
    func userJoinToCourse(member: CourseMember) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(JoinEvent(type: .message, data: member.asPublicBot()))
        let dataString = String(data: data, encoding: .utf8) ?? "{}"
        sendDataToCourse(course: member.course, dataString: dataString)
    }
    
    func sendDataToChat(chat: Chat, dataString: String, toBot: Bool = true) {
        for user in chat.users {
            if (userChats[user] != nil && userChats[user]!.id == chat.id) {
                userSockets[user]!.send(dataString)
            }
        }
        if (toBot) {
            if (botSockets[chat.bot] != nil) {
                botSockets[chat.bot]!.send(dataString)
            }
        }
    }
    
    func sendDataToCourse(course: Course, dataString: String, toBot: Bool = true) {
        for user in course.users {
            if (userChats[user] != nil && userChats[user]!.course.id == course.id) {
                userSockets[user]!.send(dataString)
            }
        }
        if (toBot) {
            for bot in course.bots {
                if (botSockets[bot] != nil) {
                    botSockets[bot]!.send(dataString)
                }
            }
        }
    }
}
