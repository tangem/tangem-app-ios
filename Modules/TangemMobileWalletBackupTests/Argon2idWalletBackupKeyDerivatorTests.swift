//
//  Argon2idWalletBackupKeyDerivatorTests.swift
//  TangemMobileWalletBackupTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemMobileWalletBackup

@Suite("Argon2id key derivator")
struct Argon2idWalletBackupKeyDerivatorTests {
    /// swift-sodium's `PWHash.hash` converts the password with `passwd.map(Int8.init)`.
    /// That unapplied `Int8.init` reference resolves to the concrete `init(bitPattern:)`,
    /// not to the trapping generic `init(_:)` a direct `Int8(x)` call would pick — so
    /// high-bit bytes (every byte of any non-ASCII UTF-8 character) reinterpret instead
    /// of crashing. Key derivation for non-ASCII passwords relies on this resolution;
    /// this test pins it against stdlib and toolchain changes.
    @Test
    func unappliedInt8InitReferenceResolvesToBitPattern() {
        let allByteValues = Array(UInt8.min ... UInt8.max)

        let viaUnappliedReference = allByteValues.map(Int8.init)
        let viaBitPattern = allByteValues.map { Int8(bitPattern: $0) }

        #expect(viaUnappliedReference == viaBitPattern)
    }

    @Test
    func derivesKeyFromNonASCIIPassword() async throws {
        let derivator = Argon2idWalletBackupKeyDerivator()
        let params = try makeFastParams()

        let key = try derivator.deriveKey(password: "pässwörd🔑", params: params)

        #expect(key.count == params.dklen)
    }

    @Test
    func derivationIsDeterministicAndPasswordSensitive() async throws {
        let derivator = Argon2idWalletBackupKeyDerivator()
        let params = try makeFastParams()

        let first = try derivator.deriveKey(password: "pässwörd🔑", params: params)
        let second = try derivator.deriveKey(password: "pässwörd🔑", params: params)
        let other = try derivator.deriveKey(password: "parol", params: params)

        #expect(first == second)
        #expect(first != other)
    }

    @Test
    func defaultParamsUseFreshSaltPerCall() throws {
        let derivator = Argon2idWalletBackupKeyDerivator()

        let first = try derivator.makeDefaultParams()
        let second = try derivator.makeDefaultParams()

        #expect(first.salt != second.salt)
        #expect(first.salt.count == Argon2idKDFParameters.Constants.saltLength)
    }

    /// The weakest parameters the validator accepts: the tests exercise byte handling,
    /// not memory-hardness, so derivation stays instant.
    private func makeFastParams() throws -> Argon2idKDFParameters {
        try Argon2idKDFParameters(
            version: 19,
            memory: 8, // KiB — libsodium's single-lane minimum
            iterations: 1,
            parallelism: 1,
            dklen: 32,
            salt: Data(repeating: 0xA5, count: 16)
        )
    }
}
