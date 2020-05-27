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

extension Course: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(6...))
    }
}

struct CourseController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let coursesRoute = routes.grouped("courses")
        let tokenProtected = coursesRoute.grouped(Token.authenticator())
        tokenProtected.get("", use: getMyCourses)
        
        tokenProtected.post("join", use: joinCourse)
        tokenProtected.post("create", use: createCourse)
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
        
        let userID = try  req.auth.require(User.self).id
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap {
                $0.$courses
                    .query(on: req.db)
                    .first()
        }.map { $0 != nil }
    }
    
}
