
import Fluent
import Vapor

final class User: Model {
    struct Public: Content {
        let username: String
        let id: UUID
        let isAdmin: Bool
        let createdAt: Date?
        let updatedAt: Date?
    }
    
    static let schema = "users"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "is_admin")
    var isAdmin: Bool
        
    @Siblings(through: CourseMember.self, from: \.$user, to: \.$course)
    var courses: [Course]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, username: String, passwordHash: String, isAdmin: Bool = false) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.isAdmin = isAdmin
    }
}

extension User {
    static func create(from userSignup: UserSignup) throws -> User {
        User(username: userSignup.username, passwordHash: try Bcrypt.hash(userSignup.password))
    }
    
    func createToken(source: SessionSource) throws -> Token {
        let calendar = Calendar(identifier: .gregorian)
        let expiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
        return try Token(userId: requireID(),
                         token: [UInt8].random(count: 16).base64, source: source, expiresAt: expiryDate)
    }
    
    func asPublic() throws -> Public {
        Public(username: username,
               id: try requireID(),
               isAdmin: isAdmin,
               createdAt: createdAt,
               updatedAt: updatedAt)
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
