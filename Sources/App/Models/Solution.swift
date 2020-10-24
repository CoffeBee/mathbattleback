//
//  File.swift
//  
//
//  Created by Ulyana Eskova on 24.10.2020.
//

import Fluent
import Vapor

final class Solution : Model, Content {
    static let schema = "solution";
    
    @ID(key: "id")
    var id: UUID?
    
    @Parent(key: "problem_id")
    var problem: Problem
    
    @Field(key: "answer")
    var anwer: answer
    
    @Field(key: "evidence")
    var evidence: String
    
    @Timestamp(key: "add_at", on: .create)
    var addAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, problemID: UUID, answer: answer, evidence: String) {
        self.id = id
        self.$problem.id = problemID
        self.answer = answer
        self.evidence = evidence
    }
}
