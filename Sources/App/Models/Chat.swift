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
    
    @Siblings(through: ChatMember.self, from: \.$chat, to: \.$user)
    var users: [User]
    
    init() {}
    
    init(id: UUID? = nil, name: String, about: String, courseID: UUID) {
        self.id = id
        self.name = name
        self.about = about
        self.$course.id = courseID
    }
}


final class ChatMember : Model, Content {
    
    static let schema = "chat_members"
    
    @ID(key: "id")
    var id: UUID?
    
    
    @Parent(key: "chat_id")
    var chat: Chat

    @Parent(key: "user_id")
    var user: User
    
    @Timestamp(key: "join_at", on: .create)
    var joinAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, chatID: UUID, userID: UUID) {
        self.id = id
        self.$chat.id = chatID
        self.$user.id = userID
    }
}
