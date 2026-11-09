//
//  TransactionHistoryMapperJointOperationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
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
        let record = try #require(enrich([relayerRecord], with: [item]).singleElement)

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
        let record = try #require(enrich([], with: [item]).singleElement)

        #expect(makeSUT().mapSuggestedRecord(record) == nil)
    }

    @Test("An operation that is not executed is never suggested, even when its hash matches an on-chain record", arguments: [
        JointAccountOperationStatus.awaitingSignatures,
        .pending,
        .failed,
        .cancelled,
        .unknown,
    ])
    func unexecutedJointOperationIsNeverSuggested(status: JointAccountOperationStatus) throws {
        let item = makeItem(status: status, base: JointOperationHistoryTestDataFactory.coinItem(id: "joint"))
        let record = try #require(enrich([makeOnChainRecord(for: item)], with: [item]).singleElement)

        #expect(makeSUT().mapSuggestedRecord(record) == nil)
    }

    @Test("A joint row of a coin or a token transfer is a transfer, whatever the operation's status", arguments: [
        JointAccountOperationStatus.executed,
        .failed,
        .cancelled,
    ])
    func jointTransferIsTransfer(status: JointAccountOperationStatus) throws {
        let coin = JointOperationHistoryTestDataFactory.coinItem(id: "coin", status: status)
        let token = try JointOperationHistoryTestDataFactory.tokenItem(id: "token", status: status)
        let records = try enrich([], with: [coin, token])

        #expect(records.map { makeSUT().mapTransactionViewModel($0).transactionType } == [.transfer, .transfer])
    }

    @Test("A joint row takes its status and title from the operation", arguments: zip(
        [JointAccountOperationStatus.executed, .failed, .cancelled],
        [
            (TransactionViewModel.Status.confirmed, Localization.commonSent),
            (.failed, Localization.transactionHistoryStatusSendFailed),
            (.cancelled, Localization.transactionHistoryStatusSendCancelled),
        ]
    ))
    func jointRowFollowsTheOperation(status: JointAccountOperationStatus, expected: (TransactionViewModel.Status, String)) throws {
        let item = JointOperationHistoryTestDataFactory.coinItem(id: "joint", status: status)
        let record = try #require(enrich([], with: [item]).singleElement)

        let viewModel = makeSUT().mapTransactionViewModel(record)

        #expect(viewModel.status == expected.0)
        #expect(viewModel.display.title.fullText == expected.1)
    }

    @Test("A joint row of an operation that is not finished or in a stage this version does not know keeps the status of its on-chain record", arguments: [
        JointAccountOperationStatus.awaitingSignatures,
        .pending,
        .unknown,
    ])
    func unfinishedOrUnknownStageKeepsTheOnChainStatus(status: JointAccountOperationStatus) throws {
        let item = makeItem(status: status, base: JointOperationHistoryTestDataFactory.coinItem(id: "joint"))
        let onChainRecord = try makeOnChainRecord(for: item, status: .unconfirmed)
        let record = try #require(enrich([onChainRecord], with: [item]).singleElement)

        #expect(makeSUT().mapTransactionViewModel(record).status == .inProgress)
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperJointOperationTests {
    static let blockchain = Blockchain.base(testnet: false)
    static let coin: TokenItem = .blockchain(.init(blockchain, derivationPath: nil))
    static let relayer = "0x9999999999999999999999999999999999999999"

    func enrich(_ records: [TransactionRecord], with items: [JointOperationHistoryItem]) throws -> [TransactionRecord] {
        TransactionHistoryJointOperationEnricher(currentToken: Self.coin, feeTokenItem: Self.coin)
            .enrich(records, with: try items.map(JointOperationHistoryTestDataFactory.info), syntheticWindowStart: nil)
    }

    func makeItem(status: JointAccountOperationStatus, base: JointOperationHistoryItem) -> JointOperationHistoryItem {
        let operation = base.operation

        return JointOperationHistoryItem(
            operation: JointAccountOperation(
                id: operation.id,
                chainId: operation.chainId,
                safeTransaction: operation.safeTransaction,
                status: status,
                txHash: operation.txHash,
                finishedAt: operation.finishedAt,
                cancelReason: operation.cancelReason,
                initiator: operation.initiator,
                signatures: operation.signatures,
                createdAt: operation.createdAt,
                threshold: operation.threshold
            ),
            cryptoAccountId: base.cryptoAccountId,
            safeAddress: base.safeAddress,
            createdAt: base.createdAt,
            threshold: base.threshold
        )
    }

    func makeOnChainRecord(for item: JointOperationHistoryItem, status: TransactionRecord.TransactionStatus = .confirmed) throws -> TransactionRecord {
        TransactionRecord(
            hash: try #require(item.operation.txHash),
            index: 0,
            source: .single(.init(address: Self.relayer, amount: 0)),
            destination: .single(.init(address: .user(Self.relayer), amount: 0)),
            fee: Fee(Amount(with: Self.blockchain, value: 0.0001)),
            status: status,
            isOutgoing: true,
            type: .transfer,
            date: JointOperationHistoryTestDataFactory.finishedAt,
            tokenTransfers: [],
            nonce: nil
        )
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
