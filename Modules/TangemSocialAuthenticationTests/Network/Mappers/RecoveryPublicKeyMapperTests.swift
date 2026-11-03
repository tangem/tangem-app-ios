//
//  RecoveryPublicKeyMapperTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemSocialAuthentication

@Suite("RecoveryPublicKeyMapper", .tags(.socialAuthentication))
struct RecoveryPublicKeyMapperTests {
    @Test(
        "The JWK maps to a key with its kid as is, algorithm and decoded RSA components",
        arguments: ["kms-recovery-key-v2", " spaced kid ", "Kid/With+Symbols=", "arn:aws:kms:eu-central-1:123456789012:key/0f1e2d3c"]
    )
    func jwkMapsToTheKey(kid: String) throws {
        let key = try RecoveryPublicKeyMapper.map(RSAKeyPairFixture.publicKeyJWK(kid: kid))

        let expected = RecoveryPublicKey(
            keyId: kid,
            algorithm: "RSA-OAEP-256",
            modulus: RSAKeyPairFixture.modulus,
            exponent: RSAKeyPairFixture.exponent
        )
        #expect(key == expected)
    }

    @Test("An empty kid maps to a key without an id")
    func emptyKidMapsToAKeyWithoutAnId() throws {
        let key = try RecoveryPublicKeyMapper.map(RSAKeyPairFixture.publicKeyJWK(kid: ""))

        #expect(key.keyId == nil)
    }

    @Test("An RSA component that is not base64url is an invalid public key", arguments: Self.jwksWithInvalidComponents)
    func componentThatIsNotBase64URLIsAnInvalidPublicKey(jwk: RecoveryPublicKeyDTO.Response) throws {
        let error = try #require(throws: RecoveryKeyEncryptionError.self) {
            try RecoveryPublicKeyMapper.map(jwk)
        }

        guard case .invalidPublicKey = error else {
            Issue.record("Expected .invalidPublicKey, got \(error)")
            return
        }
    }
}

// MARK: - Helpers

private extension RecoveryPublicKeyMapperTests {
    static let jwksWithInvalidComponents: [RecoveryPublicKeyDTO.Response] = [
        RSAKeyPairFixture.publicKeyJWK(n: "not base64url!"),
        RSAKeyPairFixture.publicKeyJWK(e: "not base64url!"),
    ]
}
