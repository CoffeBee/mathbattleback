//
//  AddStatusFieldCourseMember.swift
//  App
//
//  Created by Podvorniy Ivan on 27.05.2020.
//

import Fluent

struct AddStatusFieldCourseMember: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CourseMember.schema)
            .field("status", .string, .required)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CourseMember.schema).delete()
    }
}


