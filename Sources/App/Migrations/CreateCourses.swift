//
//  CreateCourses.swift
//  App
//
//  Created by Podvorniy Ivan on 27.05.2020.
//

import Fluent

struct CreateCourses: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Course.schema)
            .id()
            .field("name", .string, .required)
            .field("password", .string, .required)
            .field("created_at", .datetime, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Course.schema).delete()
    }
}

struct CreateCourseMembers: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CourseMember.schema)
            .id()
            .field("course_id", .uuid, .required, .references("courses", "id"))
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("join_at", .datetime, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CourseMember.schema).delete()
    }
}
