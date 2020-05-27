//
//  Chat.swift
//  App
//
//  Created by Podvorniy Ivan on 27.05.2020.
//

import Fluent
import Vapor
final class Chat: Model {
    
    static let schema = "chats"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "about")
    var about: String
    
    @Parent(key: "course_id")
    var course: Course
    
    
    init() {}
    
    init(id: UUID? = nil, name: String, about: String, courseID: UUID) {
        self.id = id
        self.name = name
        self.about = about
        self.$course.id = courseID
    }
}
