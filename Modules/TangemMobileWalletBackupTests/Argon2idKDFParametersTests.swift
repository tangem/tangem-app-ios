//
//  Argon2idKDFParametersTests.swift
//  TangemMobileWalletBackupTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemMobileWalletBackup

private typealias Constants = Argon2idKDFParameters.Constants

@Suite("Argon2id KDF parameters validation")
struct Argon2idKDFParametersTests {
    @Test("Supported parameters are accepted, including the sanity bounds")
    func acceptsSupportedParameters() throws {
        let memoryRange = Constants.memoryRangeKiB
        let iterationsRange = Constants.iterationsRange

        try #expect(Self.makeParams(memory: memoryRange.lowerBound).memory == memoryRange.lowerBound)
        try #expect(Self.makeParams(memory: memoryRange.upperBound).memoryBytes == memoryRange.upperBound * Constants.bytesPerKiB)
        try #expect(Self.makeParams(iterations: iterationsRange.lowerBound).iterations == iterationsRange.lowerBound)
        try #expect(Self.makeParams(iterations: iterationsRange.upperBound).iterations == iterationsRange.upperBound)
    }

    @Test("Argon2 versions other than 1.3 are refused")
    func rejectsUnsupportedVersion() {
        expectUnsupported { try Self.makeParams(version: Constants.argon2Version13 - 1) }
        expectUnsupported { try Self.makeParams(version: 0) }
    }

    @Test("Parallelism other than libsodium's single lane is refused")
    func rejectsUnsupportedParallelism() {
        expectUnsupported { try Self.makeParams(parallelism: Constants.supportedParallelism - 1) }
        expectUnsupported { try Self.makeParams(parallelism: Constants.supportedParallelism + 1) }
    }

    @Test("Salt of any length but 16 bytes is refused")
    func rejectsUnsupportedSaltLength() {
        expectUnsupported { try Self.makeParams(salt: Data()) }
        expectUnsupported { try Self.makeParams(salt: Data(repeating: 0x01, count: Constants.saltLength - 1)) }
        expectUnsupported { try Self.makeParams(salt: Data(repeating: 0x01, count: Constants.saltLength + 1)) }
    }

    @Test("Memory cost outside the sanity bounds is refused")
    func rejectsMemoryOutOfBounds() {
        expectUnsupported { try Self.makeParams(memory: Constants.memoryRangeKiB.lowerBound - 1) }
        expectUnsupported { try Self.makeParams(memory: -1) }
        expectUnsupported { try Self.makeParams(memory: Constants.memoryRangeKiB.upperBound + 1) }
    }

    @Test("Iteration count outside the sanity bounds is refused")
    func rejectsIterationsOutOfBounds() {
        expectUnsupported { try Self.makeParams(iterations: Constants.iterationsRange.lowerBound - 1) }
        expectUnsupported { try Self.makeParams(iterations: -1) }
        expectUnsupported { try Self.makeParams(iterations: Constants.iterationsRange.upperBound + 1) }
    }

    @Test("Derived key length other than the AES-256 key size is refused")
    func rejectsUnsupportedDKLen() {
        expectUnsupported { try Self.makeParams(dklen: Constants.expectedDKLen / 2) }
        expectUnsupported { try Self.makeParams(dklen: Constants.expectedDKLen * 2) }
    }
}

// MARK: - Helpers

private extension Argon2idKDFParametersTests {
    static func makeParams(
        version: Int = Constants.argon2Version13,
        memory: Int = 8,
        iterations: Int = 1,
        parallelism: Int = Constants.supportedParallelism,
        dklen: Int = Constants.expectedDKLen,
        salt: Data = Data(repeating: 0xA5, count: Constants.saltLength)
    ) throws(WalletBackupCryptoError) -> Argon2idKDFParameters {
        try Argon2idKDFParameters(
            version: version,
            memory: memory,
            iterations: iterations,
            parallelism: parallelism,
            dklen: dklen,
            salt: salt
        )
    }

    func expectUnsupported(
        sourceLocation: SourceLocation = #_sourceLocation,
        _ makeParams: () throws -> Argon2idKDFParameters
    ) {
        #expect(sourceLocation: sourceLocation) {
            try makeParams()
        } throws: { error in
            guard case WalletBackupCryptoError.unsupportedKDFParams = error else {
                return false
            }
            return true
        }
    }
}
