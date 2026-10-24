//
//  WCTransactionTargetValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("WalletConnect transaction target validation")
struct WCTransactionTargetValidatorTests {
    @Test("Contract data sent to an address without code warns that the funds may be lost")
    func callDataToAddressWithoutCode() async {
        let events = await validate(transaction(data: Self.swapCallData), hasCode: false)

        #expect(events == [.recipientIsNotContract(blockchainName: Self.blockchain.displayName)])
        #expect(!events.contains { $0.blocksSigning })
    }

    @Test("Contract data sent to a contract passes")
    func callDataToContract() async {
        let events = await validate(transaction(data: Self.swapCallData), hasCode: true)

        #expect(events.isEmpty)
    }

    @Test("A plain transfer never looks the recipient code up", arguments: [nil, "0x", ""] as [String?])
    func plainTransferSkipsCodeLookup(data: String?) async {
        let lookups = OSAllocatedUnfairLock(initialState: 0)

        let events = await Self.validator.validateRecipient(of: transaction(data: data)) { _ in
            lookups.withLock { $0 += 1 }
            return false
        }

        #expect(events.isEmpty)
        #expect(lookups.withLock { $0 } == 0)
    }

    @Test("A failed code lookup does not warn")
    func failedCodeLookup() async {
        let events = await Self.validator.validateRecipient(of: transaction(data: Self.swapCallData)) { _ in
            throw StubError()
        }

        #expect(events.isEmpty)
    }

    @Test("A chain ID from another network blocks signing", arguments: ["0x1237", "4663"])
    func chainMismatchBlocksSigning(chainId: String) {
        let events = Self.validator.validateChain(of: transaction(data: nil, chainId: chainId))

        #expect(events == [.chainMismatch(blockchainName: Self.blockchain.displayName, declaredChainId: 4663)])
        #expect(events.contains { $0.blocksSigning })
    }

    @Test("A chain ID of the requested network passes", arguments: ["0x1", "1"])
    func matchingChainId(chainId: String) {
        let events = Self.validator.validateChain(of: transaction(data: nil, chainId: chainId))

        #expect(events.isEmpty)
    }

    @Test("Only transaction requests are validated", arguments: [
        (WalletConnectMethod.sendTransaction, true),
        (.signTransaction, true),
        (.personalSign, false),
        (.signTypedDataV4, false),
    ])
    func onlyTransactionRequestsAreValidated(method: WalletConnectMethod, isValidated: Bool) throws {
        let requestData = try JSONEncoder().encode(transaction(data: Self.swapCallData, chainId: "0x1237"))

        let validated = WCTransactionTargetValidator.transaction(method: method, requestData: requestData)

        #expect((validated != nil) == isValidated)
    }

    @Test("A missing chain ID is not checked")
    func missingChainId() {
        let events = Self.validator.validateChain(of: transaction(data: Self.swapCallData))

        #expect(events.isEmpty)
    }
}

// MARK: - Fixtures

private extension WCTransactionTargetValidatorTests {
    static let blockchain = Blockchain.ethereum(testnet: false)
    static let validator = WCTransactionTargetValidator(blockchain: blockchain)
    static let swapCallData = "0x3593564c0000000000000000000000000000000000000000000000000000000000000060"

    struct StubError: Error {}

    func transaction(data: String?, chainId: String? = nil) -> WalletConnectEthTransaction {
        WalletConnectEthTransaction(
            from: "0xfce1fff34c2ca2933efa8bebb35b8f01c0bbc1d7",
            to: "0x204faca1764b154221e35c0d20abb3c525710498",
            value: "0x2fc06120b792ab1",
            data: data,
            gas: nil,
            gasPrice: nil,
            nonce: nil,
            chainId: chainId
        )
    }

    func validate(_ transaction: WalletConnectEthTransaction, hasCode: Bool) async -> [WCNotificationEvent] {
        await Self.validator.validateRecipient(of: transaction) { _ in hasCode }
    }
}
