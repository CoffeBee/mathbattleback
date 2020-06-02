//
//  AddSuperCourse.swift
//  App
//
//  Created by Podvorniy Ivan on 01.06.2020.
//


import Fluent

struct AddSuperCourse: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Course.schema)
            .field("is_super", .bool, .required)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Course.schema).delete()
    }
}
