import Foundation
import KituraContracts
import CredentialsJWT
import SwiftJWT
import Credentials
import LoggerAPI

func initializeJWTRoutes(app: App) {

    app.router.post("/jwtlogin") { request, response, next in
        let credentials = try request.read(as: UserCredentials.self)
        // Users credentials are authenticated
        let myClaims = ClaimsStandardJWT(iss: "Kitura", sub: credentials.username, exp: Date(timeIntervalSinceNow: 3600))
        var myJWT = JWT(claims: myClaims)
        let signedJWT = try myJWT.sign(using: App.jwtSigner)
        response.send(signedJWT + "\n")
        next()
    }

    let jwtCredentials = CredentialsJWT<ClaimsStandardJWT>(verifier: App.jwtVerifier)
    let authenticationMiddleware = Credentials()
    authenticationMiddleware.register(plugin: jwtCredentials)
    app.router.post("/jwtprotected", middleware: authenticationMiddleware)
    app.router.post("/jwtprotected") { request, response, next in
        
        guard let userProfile = request.userProfile else {
                Log.verbose("Failed raw token authentication")
                response.status(.unauthorized)
                try response.end()
                return
            }
        response.send("\(userProfile.id)\n")
            next()
        }
}

extension App {
    // Define JWT signer and verifier here
    static let jwtSigner = JWTSigner.hs256(key: Data("kitura".utf8))
    static let jwtVerifier = JWTVerifier.hs256(key: Data("kitura".utf8))
}
