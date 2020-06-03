//
//  DeleteBotOwnerMessage.swift
//  App
//
//  Created by Podvorniy Ivan on 02.06.2020.
//

import Fluent

struct DeleteBotOwnerMessage: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Message.schema)
            .deleteField("bot_owner_id")
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Message.schema)
        .field("bot_owner_id", .uuid, .references("bots", "id"))
        .create()
    }
}
