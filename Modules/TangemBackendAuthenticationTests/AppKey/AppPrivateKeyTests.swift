//
//  AppPrivateKeyTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Security
import Testing
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct AppPrivateKeyTests {
    @Test
    func initSucceedsForPKCS1Key() throws {
        let appPrivateKey = try AppPrivateKey(RSAKeyFixture.privateKeyPKCS1)
        #expect(SecKeyGetBlockSize(appPrivateKey.secKey) == 256)
    }

    @Test
    func initSucceedsForPKCS8Key() throws {
        let appPrivateKey = try AppPrivateKey(RSAKeyFixture.privateKeyPKCS8)
        #expect(SecKeyGetBlockSize(appPrivateKey.secKey) == 256)
    }

    @Test
    func initThrowsForNonBase64AppPrivateKey() throws {
        let error = try #require(throws: AppPrivateKeyParsingError.self) {
            _ = try AppPrivateKey("any non-base64 string")
        }

        guard case .invalidBase64Encoding = error else {
            Issue.record("Expected AppPrivateKeyParsingError.invalidBase64Encoding, got \(error)")
            return
        }
    }

    @Test
    func initThrowsForMalformedAppPrivateKey() throws {
        let error = try #require(throws: AppPrivateKeyParsingError.self) {
            _ = try AppPrivateKey(Data("any invalid key string".utf8).base64EncodedString())
        }

        guard case .invalidKeyFormat = error else {
            Issue.record("Expected AppPrivateKeyParsingError.invalidKeyFormat, got \(error)")
            return
        }
    }
}
