//
//  TronStakingTransactionValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

/// Reference: https://app.notion.com/p/tangem/Staking-Transactions-Validation-1a85d34eb678805e97a0edb777c0b671
@Suite("TronStakingTransactionValidator Tests")
struct TronStakingTransactionValidatorTests {
    typealias SUT = TronStakingTransactionValidator

    // MARK: - Valid Transactions

    @Test(arguments: [
        freezeBalanceV2Hex,
        unfreezeBalanceV2Hex,
        withdrawExpireUnfreezeHex,
        delegateResourceHex,
        cancelAllUnfreezeV2Hex,
        voteWitnessHex,
        withdrawBalanceHex,
        unDelegateResourceHex,
    ])
    func validStakingTransactionPasses(hex: String) {
        assertValid(hex)
    }

    @Test
    func realUnfreezeFromNotionPasses() {
        assertValid(Self.realUnfreezeHex)
    }

    // MARK: - Invalid Transactions

    @Test(arguments: [transferHex, transferAssetHex, triggerSmartContractHex, emptyContractHex])
    func invalidStakingTransactionFails(hex: String) {
        assertInvalid(hex)
    }

    @Test(arguments: [emptyData, malformedHex, oddLengthHex, invalidProtobuf])
    func malformedDataFails(data: String) {
        assertInvalid(data, error: .emptyOrMalformedData)
    }
}

// MARK: - Test Data

private extension TronStakingTransactionValidatorTests {
    // MARK: Valid Staking Transactions (all 8 types)

    /// FreezeBalanceV2Contract (type 54) - Freeze TRX for energy/bandwidth
    static var freezeBalanceV2Hex: String {
        buildTransaction(contractType: .freezeBalanceV2Contract)
    }

    /// UnfreezeBalanceV2Contract (type 55) - Unfreeze TRX
    static var unfreezeBalanceV2Hex: String {
        buildTransaction(contractType: .unfreezeBalanceV2Contract)
    }

    /// WithdrawExpireUnfreezeContract (type 56) - Withdraw expired unfrozen TRX
    static var withdrawExpireUnfreezeHex: String {
        buildTransaction(contractType: .withdrawExpireUnfreezeContract)
    }

    /// DelegateResourceContract (type 57) - Delegate energy/bandwidth
    static var delegateResourceHex: String {
        buildTransaction(contractType: .delegateResourceContract)
    }

    /// CancelAllUnfreezeV2Contract (type 59) - Cancel all pending unfreezes
    static var cancelAllUnfreezeV2Hex: String {
        buildTransaction(contractType: .cancelAllUnfreezeV2Contract)
    }

    /// VoteWitnessContract (type 4) - Vote for Super Representatives
    static var voteWitnessHex: String {
        buildTransaction(contractType: .voteWitnessContract)
    }

    /// WithdrawBalanceContract (type 13) - Claim voting rewards
    static var withdrawBalanceHex: String {
        buildTransaction(contractType: .withdrawBalanceContract)
    }

    /// UnDelegateResourceContract (type 58) - Reclaim delegated resources
    static var unDelegateResourceHex: String {
        buildTransaction(contractType: .unDelegateResourceContract)
    }

    // MARK: Real Transaction Data

    /// Real UnfreezeBalanceV2Contract from Notion doc
    static let realUnfreezeHex = "0a0233952208c993bda88c4852d54090a687c0d4325a5b083712570a36747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e556e667265657a6542616c616e63655632436f6e7472616374121d0a15416eb6eb0ba10e8dc827356eef03a49e979d8a7db110c0843d180170d0a9f1bfd432"

    // MARK: Invalid Transactions (non-staking contract types)

    /// TransferContract (type 1) - Regular TRX transfer
    static var transferHex: String {
        buildTransaction(contractType: .transferContract)
    }

    /// TransferAssetContract (type 2) - TRC10 token transfer
    static var transferAssetHex: String {
        buildTransaction(contractType: .transferAssetContract)
    }

    /// TriggerSmartContract (type 31) - Smart contract call
    static var triggerSmartContractHex: String {
        buildTransaction(contractType: .triggerSmartContract)
    }

    /// Transaction with empty contract array
    static var emptyContractHex: String {
        buildTransactionWithoutContract()
    }

    // MARK: Malformed Data

    static let emptyData = ""
    static let malformedHex = "not_valid_hex"
    static let oddLengthHex = "abc"
    static let invalidProtobuf = "deadbeef"
}

// MARK: - Helpers

private extension TronStakingTransactionValidatorTests {
    func assertValid(_ data: String) {
        #expect(throws: Never.self) { try SUT.validate(data) }
    }

    func assertInvalid(_ data: String) {
        #expect(throws: StakingTransactionValidationError.self) { try SUT.validate(data) }
    }

    func assertInvalid(_ data: String, error: StakingTransactionValidationError) {
        #expect(throws: error) { try SUT.validate(data) }
    }

    static func buildTransaction(contractType: Protocol_Transaction.Contract.ContractType) -> String {
        var contract = Protocol_Transaction.Contract()
        contract.type = contractType

        var rawData = Protocol_Transaction.raw()
        rawData.contract = [contract]

        do {
            let data = try rawData.serializedData()
            return data.hex()
        } catch {
            return ""
        }
    }

    static func buildTransactionWithoutContract() -> String {
        var rawData = Protocol_Transaction.raw()
        rawData.timestamp = 1 // non-empty payload so decoding succeeds and reaches the empty-contract check

        do {
            let data = try rawData.serializedData()
            return data.hex()
        } catch {
            return ""
        }
    }
}
