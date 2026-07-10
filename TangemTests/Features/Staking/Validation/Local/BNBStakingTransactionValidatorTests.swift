//
//  BNBStakingTransactionValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

/// Reference: https://app.notion.com/p/tangem/Staking-Transactions-Validation-1a85d34eb678805e97a0edb777c0b671
@Suite("BNBStakingTransactionValidator Tests")
struct BNBStakingTransactionValidatorTests {
    typealias SUT = BNBStakingTransactionValidator

    // MARK: - Valid Transactions

    @Test(arguments: [stakingJson])
    func validTransactionPasses(json: String) {
        assertValid(json)
    }

    // MARK: - Invalid Transactions

    @Test(arguments: [wrongAddressJson, tamperedStakeHubJson])
    func invalidTransactionFails(json: String) {
        assertInvalid(json)
    }

    // MARK: - Malformed Data

    @Test(arguments: [emptyData, malformedJson])
    func malformedDataFails(data: String) {
        assertInvalid(data, error: .emptyOrMalformedData)
    }
}

// MARK: - Test Data

private extension BNBStakingTransactionValidatorTests {
    // MARK: Valid Transactions

    /// Staking tx to the BSC StakeHub system contract (literal — pins the address independently of SUT).
    static var stakingJson: String {
        makeTransaction(to: "0x0000000000000000000000000000000000002002")
    }

    // MARK: Invalid Transactions

    /// Transaction to wrong address
    static var wrongAddressJson: String {
        makeTransaction(to: "0x1234567890123456789012345678901234567890")
    }

    /// Tampered StakeHub address (last char changed)
    static var tamperedStakeHubJson: String {
        // 0x0000000000000000000000000000000000002002 → ...2003
        makeTransaction(to: "0x0000000000000000000000000000000000002003")
    }

    // MARK: Malformed Data

    static let emptyData = ""
    static let malformedJson = "not valid json"
}

// MARK: - Helpers

private extension BNBStakingTransactionValidatorTests {
    func assertValid(_ data: String) {
        #expect(throws: Never.self) { try SUT.validate(data) }
    }

    func assertInvalid(_ data: String) {
        #expect(throws: StakingTransactionValidationError.self) { try SUT.validate(data) }
    }

    func assertInvalid(_ data: String, error: StakingTransactionValidationError) {
        #expect(throws: error) { try SUT.validate(data) }
    }

    static func makeTransaction(to: String, data: String = "0x") -> String {
        """
        {
            "chainId": 56,
            "from": "0x1234567890123456789012345678901234567890",
            "to": "\(to)",
            "data": "\(data)",
            "value": "0x0",
            "nonce": 0,
            "gasLimit": "0x5208",
            "gasPrice": "0x3b9aca00"
        }
        """
    }
}
