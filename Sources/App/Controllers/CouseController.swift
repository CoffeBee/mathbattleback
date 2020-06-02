//
//  CouseController.swift
//  App
//
//  Created by Podvorniy Ivan on 27.05.2020.
//

import Vapor
import Fluent

struct CourseInvitation: Content {
    let name: String
    let password: String
}

struct DataByCourse: Content {
    let id: UUID
}


struct AddBotToCourse: Content {
    let courseID: UUID
    let botID: UUID
}


extension Course: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(6...))
    }
}

struct CourseController: RouteCollection {
    
    let controller : WebSocketBotController
    
    init(controller : WebSocketBotController) {
        self.controller = controller
    }
    
    func boot(routes: RoutesBuilder) throws {
        let coursesRoute = routes.grouped("courses")
        let tokenProtected = coursesRoute.grouped(Token.authenticator())
        tokenProtected.get("", use: getMyCourses)
        
        tokenProtected.post("join", use: joinCourse)
        tokenProtected.post("create", use: createCourse)
        tokenProtected.post("chats", use: getMyChatsInCourse)
        tokenProtected.post("bot", use: addBotToCourse)
    }
    
    func getMyCourses(req: Request) throws -> EventLoopFuture<[Course.Public]> {
        
        let userID = try  req.auth.require(User.self).id
        
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap {
                $0.$courses
                    .query(on: req.db)
                    .all()
        }.map {
            $0.map {
                try! $0.asPublic()
            }
        }
    }
    
    func createCourse(req: Request) throws -> EventLoopFuture<Course.Public> {
        let user = try  req.auth.require(User.self)
        
        if (!user.isAdmin) {
            return req.eventLoop.makeFailedFuture(Abort(.forbidden))
        }
        
        try Course.validate(req)
        let course = try req.content.decode(Course.self)
        
        return course.save(on: req.db)
            .map {
                let newCourseMember = CourseMember(courseID: course.id!, userID: user.id!, status: .admin)
                newCourseMember.save(on: req.db);
        } .map {try! course.asPublic()}
        
    }
    
    func joinCourse(req: Request) throws -> EventLoopFuture<CourseMember> {
        
        let userID = try req.auth.require(User.self).id!
        let invitation = try req.content.decode(CourseInvitation.self)
        return try checkIsRegestationExists(userID: userID, req: req).flatMap { exists in
            guard !exists else {
                return req.eventLoop.makeFailedFuture(Abort(.alreadyReported))
            }
            return Course.query(on: req.db)
                .filter(\.$name == invitation.name)
                .filter(\.$password == invitation.password)
                .first()
                .unwrap(or: Abort(.notFound))
                .flatMap {course in
                    
                    let newCourseMember = CourseMember(courseID: course.id!, userID: userID, status: .student)
                    return newCourseMember.save(on: req.db)
                        .map { newCourseMember }
            }
        }
        
    }
    
    
    func checkIsRegestationExists(userID : UUID, req: Request) throws -> EventLoopFuture<Bool> {
        
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap {
                $0.$courses
                    .query(on: req.db)
                    .first()
        }.map { $0 != nil }
    }
    
    func checkIsAdminInCourse(userID: UUID, courseID: UUID, req: Request) throws -> EventLoopFuture<Bool> {
        return CourseMember.query(on: req.db).filter(\.$user.$id == userID).filter(\.$course.$id == courseID).filter(\.$status == MemeberStatus.admin).first().map {$0 != nil}
    }
    
    func getMyChatsInCourse(req: Request) throws -> EventLoopFuture<[Chat]> {
        
        let userID = try req.auth.require(User.self).id!
        let courseID = try req.content.decode(DataByCourse.self).id
        
        return ChatMember
            .query(on: req.db)
            .filter(\.$user.$id == userID).filter(\.$course.$id == courseID)
            .all()
            .map {
                $0.map {
                    $0.chat
                }
        }
    }
    
    func addBotToCourse(req: Request) throws -> EventLoopFuture<BotMember> {
        let userID = try req.auth.require(User.self).id!
        let information = try req.content.decode(AddBotToCourse.self)
        return try checkIsAdminInCourse(userID: userID, courseID: information.courseID, req: req).flatMap {admin in
            guard admin else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden))
            }
            return Bot.find(information.botID, on: req.db).flatMap { bot in
                guard bot != nil else {
                    return req.eventLoop.makeFailedFuture(Abort(.notFound))
                }
                let new_bot_member = BotMember(courseID: information.courseID, botID: information.botID)
                return new_bot_member.save(on: req.db).map {new_bot_member}
            }
        }
    }

}
