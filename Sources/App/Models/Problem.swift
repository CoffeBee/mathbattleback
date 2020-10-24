//
//  File.swift
//  
//
//  Created by Ulyana Eskova on 24.10.2020.
//

import Fluent
import Vapor

final class Problem : Model, Content {
    static let schema = "problem";
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "task")
    var task: String
    
    @Field(key: "correctanswer")
    var correctanswer: String
    
    @Children(for: \.$problem)
    var solutons: [Solution]
    
    init() {}
    
    init(id: UUID? = nil, title: String, task: String, correctanswer: String, courseID: UUID) {
        self.id = id
        self.title = title
        self.correctanswer = correctanswer
        self.$course.id = courseID
    }
    
}
