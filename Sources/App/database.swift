//
//  database.swift
//  App
//
//  Created by Podvorniy Ivan on 02.06.2020.
//

import Fluent
import Vapor

func database_init(_ app: Application) {
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        username: Environment.get("DATABASE_USERNAME") ?? "podvorniy",
        password: Environment.get("DATABASE_PASSWORD") ?? "Podvorniy1303©",
        database: Environment.get("DATABASE_NAME") ?? "vapor"
        ), as: .psql)
    
    
}
