//
//  AddChatMemberCouseRelation.swift
//  App
//
//  Created by Podvorniy Ivan on 28.05.2020.
//

import Fluent

struct AddChatMemberCouseRelation: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ChatMember.schema)
            .field("course_id", .uuid, .required, .references("courses", "id"))
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ChatMember.schema).delete()
    }
}
