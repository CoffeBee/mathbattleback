//
//  AddChatUserRelation.swift
//  App
//
//  Created by Podvorniy Ivan on 28.05.2020.
//

import Fluent


struct AddChatUserRelation: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ChatMember.schema)
            .id()
            .field("chat_id", .uuid, .required, .references("chats", "id"))
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("join_at", .datetime, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ChatMember.schema).delete()
    }
}
