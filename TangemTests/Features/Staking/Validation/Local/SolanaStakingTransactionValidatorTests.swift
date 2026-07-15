//
//  SolanaStakingTransactionValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

/// Reference: https://app.notion.com/p/tangem/Staking-Transactions-Validation-1a85d34eb678805e97a0edb777c0b671
@Suite("SolanaStakingTransactionValidator Tests")
struct SolanaStakingTransactionValidatorTests {
    typealias SUT = SolanaStakingTransactionValidator

    // MARK: - Valid Transactions

    @Test(arguments: [syntheticStakingHex])
    func validStakingTransactionPasses(hex: String) {
        assertValid(hex)
    }

    @Test
    func realStakingFromNotionPasses() {
        assertValid(Self.realStakingHex)
    }

    // MARK: - Invalid Transactions

    @Test(arguments: [nonStakingHex, tamperedStakeProgramHex, emptyAccountKeysHex])
    func invalidStakingTransactionFails(hex: String) {
        assertInvalid(hex)
    }

    @Test(arguments: [emptyData, malformedHex, oddLengthHex])
    func malformedDataFails(data: String) {
        assertInvalid(data, error: .emptyOrMalformedData)
    }
}

// MARK: - Test Data

private extension SolanaStakingTransactionValidatorTests {
    // MARK: Valid Transactions

    /// Synthetic staking transaction with Stake program ID
    static var syntheticStakingHex: String {
        buildStakingTransaction()
    }

    /// Real staking transaction from Notion doc
    /// Contains Stake11111111111111111111111111111111111111 in account keys
    static let realStakingHex = "0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010002041f920e2bd077f2e82b1f9c91a997b82c73d579afcf782e74444c9a38304e40bb3df3ecebe8089a54c20315bed7946ffdd2708c7f3eea27af98250bd48362a4e406a1d8179137542a983437bdfe2a7ab2557f535c8a78722b68a49dc00000000006a7d51718c774c928566398691d5eb68b5eb8a39b4b6d5c73555b2100000000ca7bc46333569bfe9e2a686a39b119fa8021a7cf2a8e998d0b214f9b7f95f0140102030103000405000000"

    // MARK: Invalid Transactions

    /// Transaction without Stake program ID
    static var nonStakingHex: String {
        buildNonStakingTransaction()
    }

    /// Transaction with tampered Stake program ID (last digit changed)
    /// Stake11111111111111111111111111111111111111 → Stake11111111111111111111111111111111111112
    static var tamperedStakeProgramHex: String {
        buildTransactionWithTamperedStakeProgram()
    }

    /// Transaction with empty account keys array
    static var emptyAccountKeysHex: String {
        buildTransactionWithEmptyAccountKeys()
    }

    // MARK: Malformed Data

    static let emptyData = ""
    static let malformedHex = "not_valid_hex"
    static let oddLengthHex = "abc"
}

// MARK: - Helpers

private extension SolanaStakingTransactionValidatorTests {
    func assertValid(_ data: String) {
        #expect(throws: Never.self) { try SUT.validate(data) }
    }

    func assertInvalid(_ data: String) {
        #expect(throws: StakingTransactionValidationError.self) { try SUT.validate(data) }
    }

    func assertInvalid(_ data: String, error: StakingTransactionValidationError) {
        #expect(throws: error) { try SUT.validate(data) }
    }

    /// Builds a minimal Solana transaction containing the Stake program ID.
    static func buildStakingTransaction() -> String {
        var data = Data()

        // 1. Signature count = 1
        data.append(0x01)

        // 2. Signature placeholder (64 zeros)
        data.append(contentsOf: [UInt8](repeating: 0, count: 64))

        // 3. Message header (3 bytes)
        data.append(contentsOf: [0x01, 0x00, 0x01])

        // 4. Account count (1 byte)
        data.append(0x02)

        // 5. First account key (32 bytes) - some wallet
        data.append(contentsOf: [UInt8](repeating: 0x11, count: 32))

        // 6. Second account key - Stake program ID
        data.append(SUT.stakeProgramBytes)

        return data.hex()
    }

    /// Builds a minimal Solana transaction WITHOUT the Stake program ID.
    static func buildNonStakingTransaction() -> String {
        var data = Data()

        // 1. Signature count = 1
        data.append(0x01)

        // 2. Signature placeholder (64 zeros)
        data.append(contentsOf: [UInt8](repeating: 0, count: 64))

        // 3. Message header
        data.append(contentsOf: [0x01, 0x00, 0x01])

        // 4. Account count = 2
        data.append(0x02)

        // 5. Two random account keys (not Stake program)
        data.append(contentsOf: [UInt8](repeating: 0x11, count: 32))
        data.append(contentsOf: [UInt8](repeating: 0x22, count: 32))

        return data.hex()
    }

    /// Builds a transaction with tampered Stake program ID.
    /// Changes last byte of Stake program to make it invalid.
    static func buildTransactionWithTamperedStakeProgram() -> String {
        var data = Data()

        // 1. Signature count = 1
        data.append(0x01)

        // 2. Signature placeholder (64 zeros)
        data.append(contentsOf: [UInt8](repeating: 0, count: 64))

        // 3. Message header
        data.append(contentsOf: [0x01, 0x00, 0x01])

        // 4. Account count = 2
        data.append(0x02)

        // 5. First account key - some wallet
        data.append(contentsOf: [UInt8](repeating: 0x11, count: 32))

        // 6. Tampered Stake program ID (change last byte)
        var tamperedStakeProgram = SUT.stakeProgramBytes
        tamperedStakeProgram[31] = 0x01 // Change last byte
        data.append(tamperedStakeProgram)

        return data.hex()
    }

    /// Builds a transaction with empty account keys array.
    static func buildTransactionWithEmptyAccountKeys() -> String {
        var data = Data()

        // 1. Signature count = 1
        data.append(0x01)

        // 2. Signature placeholder (64 zeros)
        data.append(contentsOf: [UInt8](repeating: 0, count: 64))

        // 3. Message header
        data.append(contentsOf: [0x01, 0x00, 0x01])

        // 4. Account count = 0 (empty)
        data.append(0x00)

        // No account keys

        return data.hex()
    }
}
