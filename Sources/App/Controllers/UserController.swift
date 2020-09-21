
import Vapor
import Fluent

struct UserSignup: Content {
    let username: String
    let password: String
    let name: String
    let surname: String
}

struct Confirmation: Content {
    let token: String
}

struct NewSession: Content {
    let token: String
    let user: User.Public
}

extension UserSignup: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(6...))
    }
}

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("users")
        usersRoute.post("signup", use: create)
        usersRoute.get("confirm", use: confirm)
        let tokenProtected = usersRoute.grouped(Token.authenticator())
        tokenProtected.get("me", use: getMyOwnUser)
        
        let passwordProtected = usersRoute.grouped(User.authenticator())
        passwordProtected.post("login", use: login)
    }
    
    fileprivate func create(req: Request) throws -> EventLoopFuture<NewSession> {
        try UserSignup.validate(req)
        let userSignup = try req.content.decode(UserSignup.self)
        let user = try User.create(from: userSignup)
        var token: Token!
        
        return checkIfUserExists(userSignup.username, req: req).flatMap { exists in
            guard !exists else {
                return req.eventLoop.future(error: UserError.usernameTaken)
            }
            
            return user.save(on: req.db)
        }.flatMap {
            guard let newToken = try? user.createToken(source: .signup) else {
                return req.eventLoop.future(error: Abort(.internalServerError))
            }
            token = newToken
            return token.save(on: req.db)
        }.flatMap {
            return Course.query(on: req.db).filter(\.$isSuper == true).first().map {
                if let course = $0 {
                    let new_member = CourseMember(courseID: course.id!, userID: user.id!, status: .viewer)
                    new_member.save(on: req.db)
                }
            }
        }.flatMapThrowing {
            NewSession(token: token.value, user: try user.asPublic())
        }
    }
    
    fileprivate func confirm(req: Request) throws -> EventLoopFuture<NewSession> {
        let tokenValue = try req.content.decode(Confirmation.self).token
        return Token.query(on: req.db)
            .filter(\.$value == tokenValue)
            .filter((\.$source == .signup))
            .with(\.$user)
            .first()
            .unwrap(or: Abort(.unauthorized))
            .flatMapThrowing { token in
                token.user.isActive = true;
                token.user.save(on: req.db)
                return NewSession(token: token.value, user: try token.user.asPublic())
        }
    }
    
    fileprivate func login(req: Request) throws -> EventLoopFuture<NewSession> {
        let user = try req.auth.require(User.self)
        if (!user.isActive) {
            guard let date = user.createdAt else {
                return req.eventLoop.future(error: Abort(.internalServerError))
                
            }
            let calendar = Calendar(identifier: .gregorian)
            guard let expiryDate = calendar.date(byAdding: .day, value: 1, to: date) else {
                return req.eventLoop.future(error: Abort(.internalServerError))
                
            }
            if (expiryDate > Date()) {
                return user.delete(on: req.db).eventLoop.future(error: Abort(.unauthorized))
            }
            return req.eventLoop.future(error: Abort(.preconditionRequired))
        }
        
        
        let token = try user.createToken(source: .login)
        
        return token.save(on: req.db).flatMapThrowing {
            NewSession(token: token.value, user: try user.asPublic())
        }
    }
    
    func getMyOwnUser(req: Request) throws -> User.Public {
        try req.auth.require(User.self).asPublic()
    }
    
    private func checkIfUserExists(_ username: String, req: Request) -> EventLoopFuture<Bool> {
        User.query(on: req.db)
            .filter(\.$username == username)
            .first()
            .map { user in
                guard let userr = user else {
                    return false;
                }
                guard let date = userr.createdAt else {
                    return false;
                }
                let calendar = Calendar(identifier: .gregorian)
                guard let expiryDate = calendar.date(byAdding: .day, value: 1, to: date) else {
                    return true;
                }

                if (!userr.isActive && expiryDate > Date()) {
                    userr.delete(on: req.db)
                    return false
                }
               return true
        }
    }
}
