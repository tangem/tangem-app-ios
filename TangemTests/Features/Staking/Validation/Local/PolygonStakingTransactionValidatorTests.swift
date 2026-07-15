//
//  PolygonStakingTransactionValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

/// Reference: https://app.notion.com/p/tangem/Staking-Transactions-Validation-1a85d34eb678805e97a0edb777c0b671
@Suite("POLStakingTransactionValidator Tests")
struct PolygonStakingTransactionValidatorTests {
    typealias SUT = POLStakingTransactionValidator

    // MARK: - Valid Transactions

    @Test(arguments: [stakingJson, approveJson])
    func validTransactionPasses(json: String) {
        assertValid(json)
    }

    @Test
    func realStakingFromDocPasses() {
        assertValid(Self.realStakingJson)
    }

    // MARK: - Invalid Transactions

    @Test(arguments: [
        wrongAddressJson,
        oldStakeKitContractJson,
        wrongSpenderJson,
        oldSpenderJson,
        wrongTokenJson,
        wrongMethodIdJson,
        tamperedStakeKitAddressJson,
        shortApproveDataJson,
    ])
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

private extension PolygonStakingTransactionValidatorTests {
    /// Legacy StakeKit contract, replaced by `SUT.stakeKitContract`; kept only as a negative fixture.
    static let oldStakeKitContract = "0x467585AaEa860F9D8B3B43bb994E4Da8A93788a7"

    // MARK: Valid Transactions

    /// Staking transaction to the StakeKit contract
    static var stakingJson: String {
        makeTransaction(to: SUT.stakeKitContract)
    }

    /// Approve transaction on POL token with the StakeKit contract as spender
    static var approveJson: String {
        makeApproveTransaction(tokenContract: SUT.polToken, spender: SUT.stakeKitContract)
    }

    /// Real staking tx from Notion doc — direct call to the StakeKit contract (`chainId: 1`)
    static let realStakingJson = """
    {
        "from": "0x04623d188f472237439B7d146260550Fa6b0C2e2",
        "gasLimit": "0x03e157",
        "to": "0x5e3Ef299fDDf15eAa0432E6e66473ace8c13D908",
        "data": "0xe4457a8a0000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000000000000000000000000000000000000000000000",
        "nonce": 35,
        "type": 2,
        "maxFeePerGas": "0x01165a8b80",
        "maxPriorityFeePerGas": "0x054e0840",
        "chainId": 1
    }
    """

    // MARK: Invalid Transactions

    /// Transaction to wrong address
    static var wrongAddressJson: String {
        makeTransaction(to: "0x1234567890123456789012345678901234567890")
    }

    /// Direct call to the legacy StakeKit contract — no longer accepted
    static var oldStakeKitContractJson: String {
        makeTransaction(to: oldStakeKitContract)
    }

    /// Approve with wrong spender
    static var wrongSpenderJson: String {
        makeApproveTransaction(
            tokenContract: SUT.polToken,
            spender: "0x1234567890123456789012345678901234567890"
        )
    }

    /// Approve with the legacy StakeKit contract as spender — no longer accepted
    static var oldSpenderJson: String {
        makeApproveTransaction(tokenContract: SUT.polToken, spender: oldStakeKitContract)
    }

    /// Approve on wrong token (not POL)
    static var wrongTokenJson: String {
        makeApproveTransaction(
            tokenContract: "0xABCDEF1234567890123456789012345678901234",
            spender: SUT.stakeKitContract
        )
    }

    /// Transaction with wrong method ID (transfer instead of approve)
    static var wrongMethodIdJson: String {
        makeTransaction(
            to: SUT.polToken,
            data: "0xa9059cbb" + String(repeating: "0", count: 128) // transfer methodID
        )
    }

    /// Tampered StakeKit address (last char changed)
    static var tamperedStakeKitAddressJson: String {
        // 0x5e3Ef299fDDf15eAa0432E6e66473ace8c13D908 → ...D909
        makeTransaction(to: "0x5e3Ef299fDDf15eAa0432E6e66473ace8c13D909")
    }

    /// Approve with too short data (missing spender)
    static var shortApproveDataJson: String {
        makeTransaction(to: SUT.polToken, data: "0x095ea7b3") // only methodID, no spender
    }

    // MARK: Malformed Data

    static let emptyData = ""
    static let malformedJson = "not valid json"
}

// MARK: - Helpers

private extension PolygonStakingTransactionValidatorTests {
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
            "chainId": 1,
            "from": "0x1234567890123456789012345678901234567890",
            "to": "\(to)",
            "data": "\(data)",
            "value": "0x0",
            "nonce": 0,
            "gasLimit": "0x5208",
            "maxFeePerGas": "0x3b9aca00",
            "maxPriorityFeePerGas": "0x3b9aca00"
        }
        """
    }

    static func makeApproveTransaction(tokenContract: String, spender: String) -> String {
        // approve(address spender, uint256 amount)
        // Method ID: 0x095ea7b3
        let spenderPadded = spender.lowercased()
            .replacingOccurrences(of: "0x", with: "")
            .leftPadding(toLength: 64, withPad: "0")
        let amountMax = String(repeating: "f", count: 64)
        let data = "0x095ea7b3" + spenderPadded + amountMax

        return makeTransaction(to: tokenContract, data: data)
    }
}

// MARK: - String Extension

private extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = count
        if stringLength < toLength {
            return String(repeating: character, count: toLength - stringLength) + self
        }
        return self
    }
}
