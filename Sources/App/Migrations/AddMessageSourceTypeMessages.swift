//
//  AddMessageSourceTypeMessages.swift
//  App
//
//  Created by Podvorniy Ivan on 29.05.2020.
//

import Fluent

struct AddMessageSourceTypeMessages: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Message.schema)
            .field("message_source", .string, .required)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Message.schema).delete()
    }
}
