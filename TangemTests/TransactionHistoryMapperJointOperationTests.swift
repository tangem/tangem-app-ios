//
//  TransactionHistoryMapperJointOperationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("TransactionHistoryMapper joint operations")
struct TransactionHistoryMapperJointOperationTests {
    @Test("A joint operation is suggested by the recipient of its inner call, never by the relayer, the Safe or the treasury")
    func jointOperationIsSuggestedByItsRecipient() throws {
        let item = JointOperationHistoryTestDataFactory.coinItem(id: "joint", status: .executed)
        let txHash = try #require(item.operation.txHash)
        let relayerRecord = TransactionRecord(
            hash: txHash,
            index: 0,
            source: .single(.init(address: Self.relayer, amount: 0)),
            destination: .single(.init(address: .user(Self.relayer), amount: 0)),
            fee: Fee(Amount(with: Self.blockchain, value: 0.0001)),
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: JointOperationHistoryTestDataFactory.finishedAt,
            tokenTransfers: [],
            nonce: nil
        )
        let record = try #require(makeEnricher().enrich([relayerRecord], with: [item], syntheticWindowStart: nil).singleElement)

        let suggestion = makeSUT().mapSuggestedRecord(record)

        #expect(suggestion?.address == JointOperationHistoryTestDataFactory.recipient)
        #expect(record.hasDestination(address: Self.relayer) == false)
        #expect(record.hasDestination(address: JointOperationHistoryTestDataFactory.safeAddress) == false)
        #expect(record.hasDestination(address: item.operation.safeTransaction.refundReceiver) == false)
    }

    @Test("A joint operation with no on-chain record is never suggested", arguments: [
        JointAccountOperationStatus.executed,
        .failed,
        .cancelled,
    ])
    func syntheticJointOperationIsNeverSuggested(status: JointAccountOperationStatus) throws {
        let item = JointOperationHistoryTestDataFactory.item(
            id: "joint",
            status: status,
            chainId: JointOperationHistoryTestDataFactory.baseChainId,
            safeTransaction: JointOperationHistoryTestDataFactory.coinSafeTransaction()
        )
        let record = try #require(makeEnricher().enrich([], with: [item], syntheticWindowStart: nil).singleElement)

        #expect(makeSUT().mapSuggestedRecord(record) == nil)
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperJointOperationTests {
    static let blockchain = Blockchain.base(testnet: false)
    static let coin: TokenItem = .blockchain(.init(blockchain, derivationPath: nil))
    static let relayer = "0x9999999999999999999999999999999999999999"

    func makeEnricher() -> TransactionHistoryJointOperationEnricher {
        TransactionHistoryJointOperationEnricher(currentToken: Self.coin, feeTokenItem: Self.coin)
    }

    func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: Self.blockchain.currencySymbol,
            blockchain: Self.blockchain,
            addressesProvider: StubJointOperationAddressesProvider(walletAddresses: [JointOperationHistoryTestDataFactory.safeAddress]),
            showSign: true,
            isToken: false,
            stakingNetwork: nil
        )
    }
}

// MARK: - Stubs

private struct StubJointOperationAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
