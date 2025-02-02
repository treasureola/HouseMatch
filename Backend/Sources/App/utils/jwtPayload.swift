//
//  jwtPayload.swift
//  MyAuthBackend
//
//  Created by Issouf Diarrassouba on 12/1/24.
//

import Vapor
import JWT

// JWT payload structure.

struct MyJWTPayload: JWTPayload {
    // The "sub" (subject) claim identifies the principal that is the
    // subject of the JWT.
    var subject: SubjectClaim
    
    // The "exp" (expiration time) claim identifies the expiration time on
    // or after which the JWT MUST NOT be accepted for processing.
    var expiration: ExpirationClaim

    // Run any additional verification logic beyond
       // signature verification here.
       // Since we have an ExpirationClaim, we will
       // call its verify method.
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
