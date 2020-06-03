//
//  AddSourceMessage.swift
//  App
//
//  Created by Podvorniy Ivan on 03.06.2020.
//

import Fluent

struct AddSourceMessage: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Message.schema).field("message_source", .string)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Message.schema).delete()
    }
}
