//
//  Bot.swift
//  App
//
//  Created by Podvorniy Ivan on 28.05.2020.
//

import Fluent
import Vapor

final class Bot: Model, Content {

    static let schema = "bots"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "about")
    var about: String
    
    @Parent(key: "owner_id")
    var owner: User
    
    @Siblings(through: BotMember.self, from: \.$bot, to: \.$course)
    var courses: [Course]
    
    
    init() {}
    
    init(id: UUID? = nil, name: String, about: String, ownerID: UUID) {
        self.id = id
        self.name = name
        self.about = about
        self.$owner.id = ownerID
    }
    

}

extension Bot: Hashable {
    
    static func == (lhs: Bot, rhs: Bot) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class BotMember: Model, Content {
    static let schema = "bot_member"
    
    @ID(key: "id")
    var id: UUID?
    
    @Parent(key: "course_id")
    var course: Course
    
    @Parent(key: "bot_id")
    var bot: Bot
    
    @Timestamp(key: "add_at", on: .create)
    var addAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, courseID: UUID, botID: UUID) {
        self.id = id
        self.$course.id = courseID
        self.$bot.id = botID
    }
    
}
