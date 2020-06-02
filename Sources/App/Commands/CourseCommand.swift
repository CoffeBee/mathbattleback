//
//  CourseCommand.swift
//  App
//
//  Created by Podvorniy Ivan on 01.06.2020.
//

import Vapor

struct CourseCommand: Command {
    struct Signature: CommandSignature {
        @Argument(name: "name")
        var name: String
    }

    var help: String {
        "Crete new super course"
    }

    
    func run(using context: CommandContext, signature: Signature) throws {
        let new_course = Course(name: signature.name, password: "", isSuper: true)
        try new_course.save(on: context.application.db).wait()
        
        context.console.print("You create super course with name \(signature.name)")
    }
}
