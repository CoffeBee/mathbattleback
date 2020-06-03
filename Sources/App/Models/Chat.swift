//
//  Chat.swift
//  App
//
//  Created by Podvorniy Ivan on 27.05.2020.
//

import Fluent
import Vapor


final class Chat: Model, Content {
    
    static let schema = "chats"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "about")
    var about: String
    
    @Parent(key: "course_id")
    var course: Course
    
    @Parent(key: "bot_id")
    var bot: Bot
    
    @Siblings(through: ChatMember.self, from: \.$chat, to: \.$user)
    var users: [User]
    
    @Children(for: \.$chat)
    var messages: [Message]
    
    init() {}
    
    init(id: UUID? = nil, name: String, about: String, courseID: UUID, botID: UUID) {
        self.id = id
        self.name = name
        self.about = about
        self.$course.id = courseID
        self.$bot.id = botID
    }
}

enum ChatPermission: String, Codable {
    case read
    case write
}

final class ChatMember : Model, Content {
    
    static let schema = "chat_members"
    
    @ID(key: "id")
    var id: UUID?
    
    
    @Parent(key: "chat_id")
    var chat: Chat
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "course_id")
    var course: Course
    
    @Field(key: "permission")
    var permission: ChatPermission
    
    @Timestamp(key: "join_at", on: .create)
    var joinAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, chatID: UUID, userID: UUID, courseID: UUID, permission: ChatPermission) {
        self.id = id
        self.$chat.id = chatID
        self.$user.id = userID
        self.$course.id = courseID
        self.permission = permission
    }
}

enum MessageSource : String, Codable {
    case user
    case bot
    case system
}

final class Message: Model, Content {
    
    struct PublicBot: Content {
        let id: UUID?
        let user: User.Public
        let text: String
        let sendAt: Date?
    }
    
    static let schema = "message"
    
    @ID(key: "id")
    var id: UUID?
    
    @Parent(key: "chat_id")
    var chat: Chat
    
    @Parent(key: "user_owner_id")
    var user_owner: User
    
    
    @Field(key: "text")
    var text: String
    
    @Timestamp(key: "send_at", on: .create)
    var sendAt: Date?
    
    @Field(key: "message_source")
    var soureType: MessageSource
    
    init() {}
    
    init(id: UUID? = nil, chatID: UUID, user_ownerID: UUID, status: MessageSource, text: String) {
        self.id = id
        self.$chat.id = chatID
        self.$user_owner.id = user_ownerID
        self.soureType = status
        self.text = text
    }
    
}

extension Message {
    func asPublic(req: Request) throws -> EventLoopFuture<Message.PublicBot> {
        return try self.$user_owner.query(on: req.db).first().unwrap(or: Abort(.notFound)).map { user in
            return PublicBot(id: self.id, user: try! user.asPublic(), text: self.text, sendAt: self.sendAt)
        }
        
    }
    func asPublicMessage() throws -> Message.PublicBot {
        return PublicBot(id: self.id, user: try user_owner.asPublic(), text: self.text, sendAt: self.sendAt)
    }
}
