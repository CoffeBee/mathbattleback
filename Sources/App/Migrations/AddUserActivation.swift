//
//  DeleteBotOwnerMessage.swift
//  App
//
//  Created by Podvorniy Ivan on 02.06.2020.
//

import Fluent

struct AddUserActivation: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .field("is_active", .bool)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .deleteField("is_active")
            .update()
    }
}
