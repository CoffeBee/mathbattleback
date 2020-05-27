//
//  CreateChats.swift
//  App
//
//  Created by Podvorniy Ivan on 27.05.2020.
//

import Fluent

struct CreateChats: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Chat.schema)
            .id()
            .field("name", .string, .required)
            .field("about", .string, .required)
            .field("course_id", .uuid, .references("courses", "id"))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Chat.schema).delete()
    }
}
