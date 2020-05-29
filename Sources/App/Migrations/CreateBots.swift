//
//  CreateBot.swift
//  App
//
//  Created by Podvorniy Ivan on 28.05.2020.
//

import Fluent

struct CreateBots: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Bot.schema)
            .id()
            .field("name", .string, .required)
            .field("about", .string, .required)
            .field("owner_id", .uuid, .references("users", "id"))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Bot.schema).delete()
    }
}
