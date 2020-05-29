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
    
    init(id: UUID? = nil, name: String, about: String, courseID: UUID) {
        self.id = id
        self.name = name
        self.about = about
        self.$course.id = courseID
    }
}

enum ChatPermission: String, Codable {
    case read
    case write
    case command
    
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
    
    init(id: UUID? = nil, chatID: UUID, userID: UUID, courseID: UUID) {
        self.id = id
        self.$chat.id = chatID
        self.$user.id = userID
        self.$course.id = courseID
    }
}

enum MessageSource : String, Codable {
    case user
    case bot
    case system
}

final class Message: Model, Content {
    static let schema = "message"
    
    @ID(key: "id")
    var id: UUID?
    
    @Parent(key: "chat_id")
    var chat: Chat
    
    @Parent(key: "user_owner_id")
    var user_owner: User
    
    @Parent(key: "bot_owner_id")
    var bot_owner: User
    
    @Field(key: "text")
    var text: String
    
    @Timestamp(key: "send_at", on: .create)
    var sendAt: Date?
    
    
    
    init() {}
    
    init(id: UUID? = nil, chatID: UUID, user_ownerID: UUID, bot_ownerID: UUID, text: String) {
        self.id = id
        self.$chat.id = chatID
        self.$user_owner.id = user_ownerID
        self.$bot_owner.id = bot_ownerID
        self.text = text
    }
    
}
