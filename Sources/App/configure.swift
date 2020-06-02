import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory)
    
    app.migrations.add(CreateUsers())
    app.migrations.add(CreateTokens())
    app.migrations.add(AddAdminFieldUsers())
    app.migrations.add(CreateCourses())
    app.migrations.add(CreateCourseMembers())
    app.migrations.add(AddStatusFieldCourseMember())
    app.migrations.add(CreateChats())
    app.migrations.add(AddChatUserRelation())
    app.migrations.add(CreateBots())
    app.migrations.add(AddBotChatRelation())
    app.migrations.add(AddChatMemberCouseRelation())
    app.migrations.add(AddApiLevelUsers())
    app.migrations.add(CreateBotMember())
    app.migrations.add(CreateMessage())
    app.migrations.add(AddMessageSourceTypeMessages())
    app.migrations.add(AddSuperCourse())
    app.migrations.add(AddNameUsers())
    
    
    app.commands.use(UserCommand(), as: "createsuperuser")
    app.commands.use(CourseCommand(), as: "createsupercourse")
    
    // register routes
    try routes(app)
    
    //
}
