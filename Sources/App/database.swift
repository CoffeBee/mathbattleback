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
        hostname: Environment.get("DATABASE_HOST") ?? "192.168.1.75",
        port: 6432,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
        
        ), as: .psql)
    
    
}
