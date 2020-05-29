//
//  AddApiLevelUsers.swift
//  App
//
//  Created by Podvorniy Ivan on 28.05.2020.
//

import Fluent

struct AddApiLevelUsers: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .field("api_level", .string)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}

