//
//  CreateBotMember.swift
//  App
//
//  Created by Podvorniy Ivan on 29.05.2020.
//

import Fluent


struct CreateBotMember: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(BotMember.schema)
            .id()
            .field("course_id", .uuid, .required, .references("courses", "id"))
            .field("bot_id", .uuid, .required, .references("bots", "id"))
            .field("add_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(BotMember.schema).delete()
    }
}
