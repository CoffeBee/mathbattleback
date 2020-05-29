//
//  CreateMessage.swift
//  App
//
//  Created by Podvorniy Ivan on 29.05.2020.
//

import Fluent

struct CreateMessage: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Message.schema)
            .id()
            .field("chat_id", .uuid, .references("chats", "id"))
            .field("user_owner_id", .uuid, .references("users", "id"))
            .field("bot_owner_id", .uuid, .references("bots", "id"))
            .field("text", .string, .required)
            .field("send_at", .datetime, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Message.schema).delete()
    }
}
