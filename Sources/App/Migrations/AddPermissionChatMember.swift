//
//  AddPermissionChatMember.swift
//  App
//
//  Created by Podvorniy Ivan on 02.06.2020.
//


import Fluent

struct AddPermissionChatMember: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ChatMember.schema).field("permission", .string)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ChatMember.schema).delete()
    }
}
