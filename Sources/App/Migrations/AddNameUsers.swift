//
//  AddNameUsers.swift
//  App
//
//  Created by Podvorniy Ivan on 02.06.2020.
//

import Fluent

struct AddNameUsers: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .field("name", .string)
            .field("surname", .string)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}
