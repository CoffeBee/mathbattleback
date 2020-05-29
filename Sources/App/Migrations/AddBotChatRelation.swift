//
//  AddBotChatRelation.swift
//  App
//
//  Created by Podvorniy Ivan on 28.05.2020.
//

import Fluent
struct AddBotChatRelation: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Chat.schema)
            .field("bot_id", .uuid, .references("bots", "id"))
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Chat.schema).delete()
    }
}

