//
//  CosmosStakingTransactionValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

/// Reference: https://app.notion.com/p/tangem/Staking-Transactions-Validation-1a85d34eb678805e97a0edb777c0b671
@Suite("CosmosStakingTransactionValidator Tests")
struct CosmosStakingTransactionValidatorTests {
    typealias SUT = CosmosStakingTransactionValidator

    // MARK: - Valid Transactions

    @Test(arguments: [msgDelegate, msgUndelegate, msgRedelegate, msgCancelUnbonding, msgWithdrawReward])
    func validMessageTypePasses(messageType: String) {
        assertValid(buildMessage(messageType: messageType))
    }

    @Test
    func realDelegationFromNotionPasses() {
        assertValid(Self.realDelegationHex)
    }

    // MARK: - Invalid Transactions

    @Test(arguments: [msgSend, msgFundCommunityPool, msgSetWithdrawAddress])
    func invalidMessageTypeFails(messageType: String) {
        assertInvalid(buildMessage(messageType: messageType))
    }

    @Test(arguments: [emptyData, malformedHex, oddLengthHex, invalidProtobuf])
    func malformedDataFails(data: String) {
        assertInvalid(data, error: .emptyOrMalformedData)
    }

    @Test
    func tamperedMessageTypeFails() {
        assertInvalid(Self.tamperedMessageTypeHex)
    }
}

// MARK: - Test Data

private extension CosmosStakingTransactionValidatorTests {
    // MARK: Valid Message Types

    // Staking module — accepted via the "/cosmos.staking." prefix.
    static let msgDelegate = "/cosmos.staking.v1beta1.MsgDelegate"
    static let msgUndelegate = "/cosmos.staking.v1beta1.MsgUndelegate"
    static let msgRedelegate = "/cosmos.staking.v1beta1.MsgBeginRedelegate"
    static let msgCancelUnbonding = "/cosmos.staking.v1beta1.MsgCancelUnbondingDelegation"
    /// Distribution module — accepted via explicit allowlist (not the whole prefix).
    static let msgWithdrawReward = "/cosmos.distribution.v1beta1.MsgWithdrawDelegatorReward"

    // MARK: Invalid Message Types

    static let msgSend = "/cosmos.bank.v1beta1.MsgSend"
    /// Distribution module but outside the staking-flow allowlist — must be rejected.
    static let msgFundCommunityPool = "/cosmos.distribution.v1beta1.MsgFundCommunityPool"
    /// Redirects where rewards are paid — rejected: not built by the StakeKit staking flow, and a reward-redirect risk.
    static let msgSetWithdrawAddress = "/cosmos.distribution.v1beta1.MsgSetWithdrawAddress"

    // MARK: Malformed Data

    static let emptyData = ""
    static let malformedHex = "not_valid_hex"
    static let oddLengthHex = "abc"
    static let invalidProtobuf = "deadbeef"

    // MARK: Real Transaction Data

    /// MsgDelegate tx from Notion doc
    static let realDelegationHex = "0ab6010a9c010a232f636f736d6f732e7374616b696e672e763162657461312e4d736744656c656761746512750a2d636f736d6f73316b737a7936776635677267657a3066777437787a38367034666379397368737977376d38727a1234636f736d6f7376616c6f706572317772783078396d39796b64687739736730347637756c6a6d65353377756a30336161356434661a0e0a057561746f6d120531303030301215766961205374616b654b6974204349442d3130303912670a500a460a1f2f636f736d6f732e63727970746f2e736563703235366b312e5075624b657912230a2103bd57c036160b047dfd4b4f3253b7277ef93777987df96b9056fc3b0f175ebdd712040a020801181712130a0d0a057561746f6d12043635363510cd88281a0b636f736d6f736875622d3420d8daaf01"

    /// Tampered tx: "staking" → "stak1ng" (69 → 31)
    static let tamperedMessageTypeHex = "0ab6010a9c010a232f636f736d6f732e7374616b316e672e763162657461312e4d736744656c656761746512750a2d636f736d6f73316b737a7936776635677267657a3066777437787a38367034666379397368737977376d38727a1234636f736d6f7376616c6f706572317772783078396d39796b64687739736730347637756c6a6d65353377756a30336161356434661a0e0a057561746f6d120531303030301215766961205374616b654b6974204349442d3130303912670a500a460a1f2f636f736d6f732e63727970746f2e736563703235366b312e5075624b657912230a2103bd57c036160b047dfd4b4f3253b7277ef93777987df96b9056fc3b0f175ebdd712040a020801181712130a0d0a057561746f6d12043635363510cd88281a0b636f736d6f736875622d3420d8daaf01"
}

// MARK: - Helpers

private extension CosmosStakingTransactionValidatorTests {
    func assertValid(_ data: String) {
        #expect(throws: Never.self) { try SUT.validate(data) }
    }

    func assertInvalid(_ data: String) {
        #expect(throws: StakingTransactionValidationError.self) { try SUT.validate(data) }
    }

    func assertInvalid(_ data: String, error: StakingTransactionValidationError) {
        #expect(throws: error) { try SUT.validate(data) }
    }

    func buildMessage(messageType: String) -> String {
        var delegate = CosmosProtoMessage.CosmosMessageDelegate()
        delegate.messageType = messageType

        var delegateContainer = CosmosProtoMessage.CosmosMessageDelegateContainer()
        delegateContainer.delegate = delegate

        var message = CosmosProtoMessage()
        message.delegateContainer = delegateContainer

        do {
            let data = try message.serializedData()
            return data.hex()
        } catch {
            return ""
        }
    }
}
