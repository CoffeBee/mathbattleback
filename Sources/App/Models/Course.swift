//
//  Course.swift
//  App
//
//  Created by Podvorniy Ivan on 27.05.2020.
//

import Fluent
import Vapor

final class Course: Model, Content {
    struct Public : Content {
        let name : String
    }
    static let schema = "courses"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "password")
    var password: String
    
    @Children(for: \.$course)
    var chats: [Chat]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Siblings(through: CourseMember.self, from: \.$course, to: \.$user)
    var users: [User]
    
    @Siblings(through: BotMember.self, from: \.$course, to: \.$bot)
    var bots: [Bot]
    
    init() {}
    
    init(id: UUID? = nil, name: String, password: String) {
        self.id = id
        self.name = name
    }
}

extension Course {
    func asPublic() throws -> Public {
        Public(name: name)
    }
}

enum MemeberStatus: String, Codable {
    case admin
    case teacher
    case student
    case viewer
}

final class CourseMember: Model, Content {
    static let schema = "course_member"
    
    @ID(key: "id")
    var id: UUID?
    
    @Parent(key: "course_id")
    var course: Course

    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "status")
    var status: MemeberStatus

    
    @Timestamp(key: "join_at", on: .create)
    var joinAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, courseID: UUID, userID: UUID, status: MemeberStatus) {
        self.id = id
        self.$course.id = courseID
        self.$user.id = userID
        self.status = status
    }
}


