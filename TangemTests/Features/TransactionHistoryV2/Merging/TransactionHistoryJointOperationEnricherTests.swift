//
//  TransactionHistoryJointOperationEnricherTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
import TangemExpress
@testable import Tangem
@testable import BlockchainSdk

extension TransactionHistoryAuxDataRepositoryDependentTests {
    @Suite("TransactionHistoryJointOperationEnricher")
    final class TransactionHistoryJointOperationEnricherTests {
        private let auxDataRepository = TransactionHistoryAuxDataRepositoryStub()

        @Test("An executed coin operation takes over its on-chain record, whatever the case of the hash")
        func executedCoinOperationTakesOverItsRecord() async throws {
            let item = Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction())
            let record = Self.record(hash: Self.txHash.uppercased(), isOutgoing: true, destination: .contract(Self.safeAddress))

            let enriched = try #require(await enrich([record], with: [item]).singleElement)

            #expect(enriched.hash == Self.txHash.uppercased())
            #expect(enriched.jointOperationInfo == JointOperationHistoryInfo(item: item))
            #expect(enriched.isOutgoing)
            #expect(enriched.source == .single(.init(address: Self.safeAddress, amount: 1)))
            #expect(enriched.destination == .single(.init(address: .user(Self.recipient), amount: 1)))
            #expect(enriched.status == .confirmed)
            #expect(enriched.fee.amount == Amount(with: Self.blockchain, value: Self.coinRefundCap))
        }

        @Test("An operation whose hash comes in another case still takes over its on-chain record")
        func operationHashCaseDoesNotMatter() async throws {
            let item = Self.item(status: .executed, txHash: Self.txHash.uppercased(), safeTransaction: Self.coinSafeTransaction())
            let record = Self.record(hash: Self.txHash, isOutgoing: true, destination: .contract(Self.safeAddress))

            let enriched = try #require(await enrich([record], with: [item]).singleElement)

            #expect(enriched.hash == Self.txHash)
            #expect(enriched.jointOperationInfo == JointOperationHistoryInfo(item: item))
        }

        @Test("A token operation states the token amount and the refund cap, not the relayer's gas")
        func tokenOperationStatesTokenAmountAndRefundCap() async throws {
            let item = try Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.tokenSafeTransaction())
            let record = Self.record(
                hash: Self.txHash,
                isOutgoing: true,
                destination: .user(Self.recipient),
                fee: Fee(Amount(with: Self.blockchain, value: 0.0000123))
            )

            let enriched = try #require(await enrich([record], with: [item], currentToken: Self.usdc).singleElement)

            #expect(enriched.source == .single(.init(address: Self.safeAddress, amount: 5)))
            #expect(enriched.destination == .single(.init(address: .user(Self.recipient), amount: 5)))
            #expect(enriched.fee.amount == Amount(with: Self.blockchain, value: Self.coinRefundCap))
        }

        @Test("Of several records under one hash only the first outgoing one is kept")
        func onlyFirstOutgoingRecordOfHashIsKept() async throws {
            let item = Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction())
            let records = [
                Self.record(hash: Self.txHash, index: 0, isOutgoing: false, destination: .user(Self.safeAddress)),
                Self.record(hash: Self.txHash, index: 2, isOutgoing: true, destination: .user(Self.treasury)),
                Self.record(hash: Self.txHash, index: 1, isOutgoing: true, destination: .user(Self.recipient)),
            ]

            let enriched = await enrich(records, with: [item])

            #expect(enriched.map(\.index) == [1])
            #expect(enriched.first?.jointOperationInfo != nil)
        }

        @Test("With no outgoing record under the hash the one with the lowest index is kept")
        func lowestIndexIsKeptWithoutOutgoingRecords() async throws {
            let item = Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction())
            let records = [
                Self.record(hash: Self.txHash, index: 3, isOutgoing: false, destination: .user(Self.safeAddress)),
                Self.record(hash: Self.txHash, index: 1, isOutgoing: false, destination: .user(Self.safeAddress)),
            ]

            let enriched = await enrich(records, with: [item])

            #expect(enriched.map(\.index) == [1])
            #expect(enriched.first?.isOutgoing == true)
        }

        @Test("A failed operation that reached the network marks its on-chain record failed")
        func failedOperationMarksRecordFailed() async throws {
            let item = Self.item(status: .failed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction())
            let record = Self.record(hash: Self.txHash, isOutgoing: true, destination: .contract(Self.safeAddress), status: .confirmed)

            let enriched = try #require(await enrich([record], with: [item]).singleElement)

            #expect(enriched.status == .failed)
            #expect(enriched.jointOperationInfo != nil)
        }

        @Test("An operation of a stage this version does not know still takes over its record and keeps its status")
        func unknownOperationTakesOverItsRecord() async throws {
            let item = Self.item(status: .unknown, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction())
            let record = Self.record(hash: Self.txHash, isOutgoing: true, destination: .contract(Self.safeAddress), status: .unconfirmed)

            let enriched = try #require(await enrich([record], with: [item]).singleElement)

            #expect(enriched.status == .unconfirmed)
            #expect(enriched.jointOperationInfo != nil)
        }

        @Test("A record that already carries Express data is left as it is")
        func expressRecordIsLeftAsIs() async throws {
            let item = Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction())
            let expressRecord = Self.record(hash: Self.txHash, isOutgoing: true, destination: .user(Self.recipient))
                .withExpressExtraInfo(.exchange(Self.exchangeInfo()))

            let enriched = await enrich([expressRecord], with: [item])

            #expect(enriched == [expressRecord])
        }

        @Test(
            "A finished operation with no on-chain record shows as a synthetic one",
            arguments: [
                (JointAccountOperationStatus.executed, TransactionRecord.TransactionStatus.confirmed),
                (.failed, .failed),
                (.cancelled, .failed),
            ]
        )
        func finishedOperationWithoutRecordIsSynthetic(
            status: JointAccountOperationStatus,
            expectedStatus: TransactionRecord.TransactionStatus
        ) async throws {
            let item = Self.item(status: status, txHash: nil, safeTransaction: Self.coinSafeTransaction())

            let synthetic = try #require(await enrich([], with: [item]).singleElement)

            #expect(synthetic.hash == JointOperationSyntheticTxHelper(operationId: Self.operationId).makeSyntheticTxIdentifier())
            #expect(JointOperationSyntheticTxHelper.isSyntheticIdentifier(synthetic.hash))
            #expect(synthetic.index == 0)
            #expect(synthetic.type == .contractMethodName(name: JointOperationSyntheticTxHelper.methodName))
            #expect(synthetic.status == expectedStatus)
            #expect(synthetic.isOutgoing)
            #expect(synthetic.date == Self.finishedAt)
            #expect(synthetic.source == .single(.init(address: Self.safeAddress, amount: 1)))
            #expect(synthetic.destination == .single(.init(address: .user(Self.recipient), amount: 1)))
            #expect(synthetic.tokenTransfers.isEmpty)
            #expect(synthetic.nonce == nil)
            #expect(synthetic.jointOperationInfo == JointOperationHistoryInfo(item: item))
        }

        @Test("Only an executed synthetic operation states the refund cap as its fee")
        func onlyExecutedSyntheticOperationHasFee() async throws {
            let executed = Self.item(id: "executed", status: .executed, txHash: nil, safeTransaction: Self.coinSafeTransaction())
            let cancelled = Self.item(id: "cancelled", status: .cancelled, txHash: nil, safeTransaction: Self.coinSafeTransaction())

            let enriched = await enrich([], with: [executed, cancelled])
            let feesByOperation = Dictionary(uniqueKeysWithValues: enriched.compactMap { record in
                record.jointOperationInfo.map { ($0.groupingId, record.fee.amount.value) }
            })

            #expect(feesByOperation == ["executed": Self.coinRefundCap, "cancelled": 0])
        }

        @Test("An operation still in flight, or of a stage this version does not know, has no synthetic record", arguments: [
            JointAccountOperationStatus.awaitingSignatures,
            .pending,
            .unknown,
        ])
        func unfinishedOperationHasNoSyntheticRecord(status: JointAccountOperationStatus) async {
            let item = Self.item(status: status, txHash: nil, safeTransaction: Self.coinSafeTransaction())

            #expect(await enrich([], with: [item]).isEmpty)
        }

        @Test("A synthetic operation is replaced by its on-chain record once that arrives")
        func syntheticOperationIsReplacedByItsRecord() async {
            let item = Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction())
            let record = Self.record(hash: Self.txHash, isOutgoing: true, destination: .contract(Self.safeAddress))

            let beforeRecord = await enrich([], with: [item])
            let afterRecord = await enrich([record], with: [item])

            #expect(beforeRecord.map(\.hash) == [JointOperationSyntheticTxHelper(operationId: Self.operationId).makeSyntheticTxIdentifier()])
            #expect(afterRecord.map(\.hash) == [Self.txHash])
        }

        @Test("A synthetic operation older than the window is left out, and shown once the window is lifted")
        func syntheticOperationOutsideWindowIsLeftOut() async {
            let item = Self.item(status: .executed, txHash: nil, safeTransaction: Self.coinSafeTransaction())
            let windowStart = Self.finishedAt.addingTimeInterval(1)

            #expect(await enrich([], with: [item], syntheticWindowStart: windowStart).isEmpty)
            #expect(await enrich([], with: [item], syntheticWindowStart: Self.finishedAt).count == 1)
            #expect(await enrich([], with: [item], syntheticWindowStart: nil).count == 1)
        }

        @Test("A synthetic operation is dated by its result, or by its creation when it has none")
        func syntheticOperationIsDatedByResult() async {
            let item = Self.item(status: .cancelled, txHash: nil, safeTransaction: Self.coinSafeTransaction(), finishedAt: nil)

            #expect(await enrich([], with: [item]).first?.date == Self.createdAt)
        }

        @Test("The result is sorted newest first")
        func resultIsSortedNewestFirst() async {
            let item = Self.item(status: .executed, txHash: nil, safeTransaction: Self.coinSafeTransaction())
            let older = Self.record(hash: "0xolder", isOutgoing: false, destination: .user(Self.safeAddress), date: Self.createdAt)
            let newer = Self.record(hash: "0xnewer", isOutgoing: false, destination: .user(Self.safeAddress), date: Self.finishedAt.addingTimeInterval(60))

            let enriched = await enrich([older, newer], with: [item])

            #expect(enriched.map(\.hash) == ["0xnewer", JointOperationSyntheticTxHelper(operationId: Self.operationId).makeSyntheticTxIdentifier(), "0xolder"])
        }

        @Test("Gas paid in a token keeps the fee already taken from the refund transfer")
        func tokenGasKeepsAttachedFee() async throws {
            let attachedFee = Fee(Amount(with: Self.usdcToken, value: 0.031))
            let item = Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction(gasToken: Self.usdcContract))
            let record = Self.record(hash: Self.txHash, isOutgoing: true, destination: .contract(Self.safeAddress), fee: attachedFee)

            let enriched = try #require(await enrich([record], with: [item]).singleElement)

            #expect(enriched.fee.amount == attachedFee.amount)
        }

        @Test("Gas paid in a token the wallet knows is stated as the refund cap in that token")
        func tokenGasIsStatedInThatToken() async throws {
            auxDataRepository.register(Self.usdc, for: ExpressCurrency(contractAddress: Self.usdcContract.lowercased(), network: Self.blockchain.networkId))
            let item = Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction(gasToken: Self.usdcContract))
            let record = Self.record(hash: Self.txHash, isOutgoing: true, destination: .contract(Self.safeAddress))

            let enriched = try #require(await enrich([record], with: [item]).singleElement)

            #expect(enriched.fee.amount.type == Self.usdc.amountType)
            #expect(enriched.fee.amount.value == Self.tokenRefundCap)
        }

        @Test("Gas paid in the wallet's own token is stated in that token without looking it up")
        func ownTokenGasIsStatedInThatToken() async throws {
            let item = try Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.tokenSafeTransaction(gasToken: Self.usdcContract))
            let record = Self.record(hash: Self.txHash, isOutgoing: true, destination: .user(Self.recipient))

            let enriched = try #require(await enrich([record], with: [item], currentToken: Self.usdc).singleElement)

            #expect(enriched.fee.amount.type == Self.usdc.amountType)
            #expect(enriched.fee.amount.value == Self.tokenRefundCap)
            #expect(auxDataRepository.requestedCurrencies.isEmpty)
        }

        @Test("Gas paid in a token the wallet does not know keeps the fee of the on-chain record")
        func unknownTokenGasKeepsRecordFee() async throws {
            let recordFee = Fee(Amount(with: Self.blockchain, value: 0.0000123))
            let item = Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction(gasToken: Self.usdcContract))
            let record = Self.record(hash: Self.txHash, isOutgoing: true, destination: .contract(Self.safeAddress), fee: recordFee)

            let enriched = try #require(await enrich([record], with: [item]).singleElement)

            #expect(enriched.fee.amount == recordFee.amount)
        }

        @Test("The refund the Safe paid in a record of its own is the fee, and that record is not shown")
        func refundInSeparateRecordIsTheFee() async throws {
            let item = Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction())
            let records = [
                Self.transfer(index: 0, destinations: [(Self.recipient, 1)]),
                Self.transfer(index: 1, destinations: [(Self.treasury, Self.actualRefund)]),
            ]

            let enriched = try #require(await enrich(records, with: [item]).singleElement)

            #expect(enriched.index == 0)
            #expect(enriched.fee.amount == Amount(with: Self.blockchain, value: Self.actualRefund))
        }

        @Test("The refund among the destinations of the matched record is the fee")
        func refundAmongDestinationsIsTheFee() async throws {
            let item = Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction())
            let record = Self.transfer(index: 0, destinations: [(Self.recipient, 1), (Self.treasury, Self.actualRefund)])

            let enriched = try #require(await enrich([record], with: [item]).singleElement)

            #expect(enriched.fee.amount == Amount(with: Self.blockchain, value: Self.actualRefund))
            #expect(enriched.destination == .single(.init(address: .user(Self.recipient), amount: 1)))
        }

        @Test("A transfer to the refund receiver in another currency than the gas is not the fee")
        func refundInAnotherCurrencyIsNotTheFee() async throws {
            let item = try Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.tokenSafeTransaction())
            let refundReceiver = item.operation.safeTransaction.refundReceiver
            let records = [
                Self.transfer(index: 0, destinations: [(Self.recipient, 5)]),
                Self.transfer(index: 1, destinations: [(refundReceiver, 0.03)]),
            ]

            let enriched = try #require(await enrich(records, with: [item], currentToken: Self.usdc).singleElement)

            #expect(enriched.fee.amount == Amount(with: Self.blockchain, value: Self.coinRefundCap))
        }

        @Test("A refund in the gas token among the token transfers is the fee in that token")
        func refundInGasTokenTransfersIsTheFee() async throws {
            auxDataRepository.register(Self.usdc, for: ExpressCurrency(contractAddress: Self.usdcContract.lowercased(), network: Self.blockchain.networkId))
            let item = Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction(gasToken: Self.usdcContract))
            let refundTransfer = TransactionRecord.TokenTransfer(
                source: Self.safeAddress,
                destination: Self.treasury,
                amount: 31000,
                name: nil,
                symbol: nil,
                decimals: nil,
                contract: Self.usdcContract.lowercased()
            )
            let record = Self.transfer(index: 0, destinations: [(Self.recipient, 1)], tokenTransfers: [refundTransfer])

            let enriched = try #require(await enrich([record], with: [item]).singleElement)

            #expect(enriched.fee.amount == Amount(with: Self.usdcToken, value: Decimal(31000) / 1_000_000))
        }

        @Test(
            "A matched record takes the status of the operation once the operation is finished",
            arguments: [
                (JointAccountOperationStatus.executed, TransactionRecord.TransactionStatus.unconfirmed, TransactionRecord.TransactionStatus.confirmed),
                (.failed, .confirmed, .failed),
                (.cancelled, .confirmed, .failed),
                (.pending, .unconfirmed, .unconfirmed),
                (.unknown, .unconfirmed, .unconfirmed),
            ]
        )
        func matchedRecordTakesFinishedOperationStatus(
            operationStatus: JointAccountOperationStatus,
            onChainStatus: TransactionRecord.TransactionStatus,
            expectedStatus: TransactionRecord.TransactionStatus
        ) async throws {
            let item = Self.item(status: operationStatus, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction())
            let record = Self.record(hash: Self.txHash, isOutgoing: true, destination: .contract(Self.safeAddress), status: onChainStatus)

            let enriched = try #require(await enrich([record], with: [item]).singleElement)

            #expect(enriched.status == expectedStatus)
        }

        @Test("Records of other hashes pass through untouched")
        func otherRecordsPassThrough() async {
            let item = Self.item(status: .executed, txHash: Self.txHash, safeTransaction: Self.coinSafeTransaction())
            let matched = Self.record(hash: Self.txHash, isOutgoing: true, destination: .contract(Self.safeAddress))
            let other = Self.record(hash: "0xother", isOutgoing: false, destination: .user(Self.safeAddress), date: Self.createdAt)

            let enriched = await enrich([matched, other], with: [item])

            #expect(enriched.map(\.hash) == [Self.txHash, "0xother"])
            #expect(enriched.first?.jointOperationInfo != nil)
            #expect(enriched.last == other)
        }
    }
}

// MARK: - Helpers

private extension TransactionHistoryAuxDataRepositoryDependentTests.TransactionHistoryJointOperationEnricherTests {
    static let blockchain = Blockchain.base(testnet: false)
    static let coin: TokenItem = .blockchain(.init(blockchain, derivationPath: nil))
    static let usdcContract = JointOperationHistoryTestDataFactory.checksummedTokenContract
    static let usdcToken = Token(name: "USD Coin", symbol: "USDC", contractAddress: usdcContract, decimalCount: 6)
    static let usdc: TokenItem = .token(usdcToken, .init(blockchain, derivationPath: nil))
    static let operationId = "operation-1"
    static let txHash = "0x4e3a3754410177e6937ef1f84bba68ea139e8d1a2258c5f85db9f1cd715a1bdd"
    static let safeAddress = JointOperationHistoryTestDataFactory.safeAddress
    static let recipient = JointOperationHistoryTestDataFactory.recipient
    static let treasury = "0x1111111111111111111111111111111111111111"
    static let actualRefund = Decimal(sign: .plus, exponent: -5, significand: 12)
    static let createdAt = JointOperationHistoryTestDataFactory.createdAt
    static let finishedAt = JointOperationHistoryTestDataFactory.finishedAt
    static let coinRefundCap = Decimal(sign: .plus, exponent: -5, significand: 19)
    static let tokenRefundCap: Decimal = 190_000_000

    func enrich(
        _ records: [TransactionRecord],
        with items: [JointOperationHistoryItem],
        currentToken: TokenItem = coin,
        syntheticWindowStart: Date? = nil
    ) async -> [TransactionRecord] {
        await InjectedDependenciesIsolation.shared.run {
            let previousAuxDataRepository = InjectedValues[\.transactionHistoryAuxDataRepository]
            InjectedValues[\.transactionHistoryAuxDataRepository] = auxDataRepository
            defer { InjectedValues[\.transactionHistoryAuxDataRepository] = previousAuxDataRepository }

            return TransactionHistoryJointOperationEnricher(currentToken: currentToken, feeTokenItem: Self.coin)
                .enrich(records, with: items, syntheticWindowStart: syntheticWindowStart)
        }
    }

    static func item(
        id: String = operationId,
        status: JointAccountOperationStatus,
        txHash: String?,
        safeTransaction: SafeTransaction,
        finishedAt: Date? = finishedAt
    ) -> JointOperationHistoryItem {
        JointOperationHistoryItem(
            operation: JointAccountOperation(
                id: id,
                chainId: 8453,
                safeTransaction: safeTransaction,
                status: status,
                txHash: txHash,
                finishedAt: finishedAt,
                cancelReason: status == .cancelled ? .initiator : nil,
                initiator: JointOperationHistoryTestDataFactory.initiator,
                signatures: [],
                createdAt: nil,
                threshold: nil
            ),
            cryptoAccountId: "crypto-account-1",
            safeAddress: safeAddress,
            createdAt: createdAt,
            threshold: 2
        )
    }

    static func coinSafeTransaction(gasToken: String = SafeGasToken.coinGasTokenRawValue) -> SafeTransaction {
        SafeTransaction(
            to: recipient,
            value: BigUInt(10).power(18),
            data: Data(),
            operation: 0,
            safeTxGas: 65_000,
            baseGas: 30_000,
            gasPrice: 2_000_000_000,
            gasToken: gasToken,
            refundReceiver: treasury,
            nonce: 7
        )
    }

    static func tokenSafeTransaction(gasToken: String = SafeGasToken.coinGasTokenRawValue) throws -> SafeTransaction {
        let transaction = try JointOperationHistoryTestDataFactory.tokenSafeTransaction()

        return SafeTransaction(
            to: transaction.to,
            value: transaction.value,
            data: transaction.data,
            operation: transaction.operation,
            safeTxGas: transaction.safeTxGas,
            baseGas: transaction.baseGas,
            gasPrice: transaction.gasPrice,
            gasToken: gasToken,
            refundReceiver: transaction.refundReceiver,
            nonce: transaction.nonce
        )
    }

    static func record(
        hash: String,
        index: Int = 0,
        isOutgoing: Bool,
        destination: TransactionRecord.Destination.Address,
        status: TransactionRecord.TransactionStatus = .confirmed,
        date: Date = finishedAt,
        fee: Fee = Fee(Amount(with: blockchain, value: 0.0001))
    ) -> TransactionRecord {
        TransactionRecord(
            hash: hash,
            index: index,
            source: .single(.init(address: isOutgoing ? safeAddress : "0xsender", amount: 0)),
            destination: .single(.init(address: destination, amount: 0)),
            fee: fee,
            status: status,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: date,
            tokenTransfers: [],
            nonce: nil
        )
    }

    static func transfer(
        index: Int,
        destinations: [(address: String, amount: Decimal)],
        tokenTransfers: [TransactionRecord.TokenTransfer] = []
    ) -> TransactionRecord {
        TransactionRecord(
            hash: txHash,
            index: index,
            source: .single(.init(address: safeAddress, amount: destinations.reduce(0) { $0 + $1.amount })),
            destination: .multiple(destinations.map { .init(address: .user($0.address), amount: $0.amount) }),
            fee: Fee(Amount(with: blockchain, value: 0.0001)),
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: finishedAt,
            tokenTransfers: tokenTransfers,
            nonce: nil
        )
    }

    static func exchangeInfo() -> ExchangeTransactionInfo {
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: safeAddress,
            payInAddress: recipient,
            payInHash: txHash,
            payOutAddress: "0xpayout",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: coin),
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: createdAt,
            updatedAt: createdAt
        )

        return ExchangeTransactionInfo(transaction: exchange, provider: nil, cryptoCurrencies: [:])
    }
}
