//
//  WebCredentialUtilTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("WebCredentialUtil")
struct WebCredentialUtilTests {
    private let user = "user@tangem.com"
    private let password = "Backup#Password1"

    @Test("SavedCredential encodes the pair as JSON under stable keys")
    func credentialDataContainsEncodedPair() throws {
        let credential = try WebCredentialUtil.SavedCredential(user: user, password: password)

        let decoded = try JSONSerialization.jsonObject(with: credential.data) as? [String: String]

        #expect(decoded?["user"] == user)
        #expect(decoded?["password"] == password)
    }

    @Test("secureErase zeroes every byte without freeing the buffer")
    func secureEraseZeroesBytes() throws {
        let credential = try WebCredentialUtil.SavedCredential(user: user, password: password)
        let countBeforeErase = credential.data.count
        #expect(credential.data.contains { $0 != 0 })

        credential.secureErase()

        #expect(credential.data.count == countBeforeErase)
        #expect(credential.data.allSatisfy { $0 == 0 })
    }

    @Test("Erased credential is refused as invalid data before any system call")
    func erasedCredentialIsRefused() async throws {
        let credential = try WebCredentialUtil.SavedCredential(user: user, password: password)
        credential.secureErase()

        await #expect {
            try await WebCredentialUtil.save(credential)
        } throws: { error in
            guard case WebCredentialUtil.SaveError.invalidData = error else {
                return false
            }
            return true
        }
    }
}
