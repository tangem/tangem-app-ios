//
//  CardanoStakingTransactionValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

/// Reference: https://app.notion.com/p/tangem/Staking-Transactions-Validation-1a85d34eb678805e97a0edb777c0b671
@Suite("CardanoStakingTransactionValidator Tests")
struct CardanoStakingTransactionValidatorTests {
    typealias SUT = CardanoStakingTransactionValidator

    // MARK: - Valid Transactions

    @Test(arguments: [delegationHex, withdrawalHex])
    func validStakingTransactionPasses(hex: String) {
        assertValid(hex)
    }

    // MARK: - Invalid Transactions

    @Test(arguments: [transferHex, tamperedKeyHex])
    func invalidStakingTransactionFails(hex: String) {
        assertInvalid(hex)
    }

    @Test(arguments: [emptyData, malformedHex, oddLengthHex, invalidCbor])
    func malformedDataFails(data: String) {
        assertInvalid(data, error: .emptyOrMalformedData)
    }
}

// MARK: - Test Data

private extension CardanoStakingTransactionValidatorTests {
    // MARK: Valid Transactions

    /// Delegation tx from Notion doc - contains key "4" (certificates)
    static let delegationHex = "84a400d90102828258201f8b8d5a75fe28f274952a3b6bd11e644ec468ad32212b2e46ca472ec3b5ef7f00825820df352db7efc48cf40d31e024464212484e55be226e18eb49ba74e40c0fecbb11000181825839014550405e15be880411ea9359987f0ee54b6f46caf3780ca7d5df0a41a00293341df23f0accdfe727cb0355e0dcf31a257996ecbaf8e5917b1a77aa5134021a0002a49104d901028182018200581ca00293341df23f0accdfe727cb0355e0dcf31a257996ecbaf8e5917ba0f5f6"

    /// Withdrawal tx - contains key "5" (withdrawals)
    static let withdrawalHex = "84a400d90102828258201f8b8d5a75fe28f274952a3b6bd11e644ec468ad32212b2e46ca472ec3b5ef7f00825820df352db7efc48cf40d31e024464212484e55be226e18eb49ba74e40c0fecbb11000181825839014550405e15be880411ea9359987f0ee54b6f46caf3780ca7d5df0a41a00293341df23f0accdfe727cb0355e0dcf31a257996ecbaf8e5917b1a77aa5134021a0002a49105d901028182018200581ca00293341df23f0accdfe727cb0355e0dcf31a257996ecbaf8e5917ba0f5f6"

    // MARK: Invalid Transactions

    /// Regular transfer - only keys "0", "1", "2" (no "4" or "5")
    static let transferHex = "83a30080018002001a000f4240f5f6"

    /// Tampered tx: certificate key (04) changed to (06)
    static let tamperedKeyHex = "84a400d90102828258201f8b8d5a75fe28f274952a3b6bd11e644ec468ad32212b2e46ca472ec3b5ef7f00825820df352db7efc48cf40d31e024464212484e55be226e18eb49ba74e40c0fecbb11000181825839014550405e15be880411ea9359987f0ee54b6f46caf3780ca7d5df0a41a00293341df23f0accdfe727cb0355e0dcf31a257996ecbaf8e5917b1a77aa5134021a0002a49106d901028182018200581ca00293341df23f0accdfe727cb0355e0dcf31a257996ecbaf8e5917ba0f5f6"

    // MARK: Malformed Data

    static let emptyData = ""
    static let malformedHex = "not_valid_hex"
    static let oddLengthHex = "abc"
    static let invalidCbor = "deadbeef"
}

// MARK: - Helpers

private extension CardanoStakingTransactionValidatorTests {
    func assertValid(_ data: String) {
        #expect(throws: Never.self) { try SUT.validate(data) }
    }

    func assertInvalid(_ data: String) {
        #expect(throws: StakingTransactionValidationError.self) { try SUT.validate(data) }
    }

    func assertInvalid(_ data: String, error: StakingTransactionValidationError) {
        #expect(throws: error) { try SUT.validate(data) }
    }
}
