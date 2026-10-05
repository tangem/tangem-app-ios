//
//  TransactionHistoryTransferClassifierTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import BlockchainSdk

/// The expected behavior follows the transaction merge spec:
/// https://app.notion.com/p/tangem/3db5d34eb67880729c01c8952a5a3c6f
@Suite("TransactionHistoryTransferClassifier")
struct TransactionHistoryTransferClassifierTests {
    // MARK: - The gasless fee

    @Test(
        "Whichever entry point the executor was reached through, what it pays a collector is the fee",
        arguments: ["0x6234d42b", "0x4b072692", "0xf9b181bf", "0x0779afe6"]
    )
    func everyGaslessMethodPayingACollectorIsExtracted(methodId: String) {
        let fee = transfer(index: 0, from: Self.owner, to: Self.knownCollector, amount: 1, methodId: methodId)

        let (standalone, mergeable, gaslessFees) = makeClassifier().classify([fee])

        #expect(gaslessFees == [fee])
        #expect(standalone.isEmpty)
        #expect(mergeable.isEmpty)
    }

    @Test("Both collectors the spec names are known without asking the service", arguments: [
        "0xFc719364BcCdc92D055d8C3164eF1ab4f5A9182c",
        "0xAf722F46145fbb106379d506ED3a5B96f110c8E5",
    ])
    func everyKnownCollectorIsRecognized(collector: String) {
        let fee = transfer(index: 0, from: Self.owner, to: collector, amount: 1, methodId: Self.gaslessMethodId)

        #expect(makeClassifier().classify([fee]).gaslessFees == [fee])
    }

    @Test("A collector deployed after the release still gets recognized once the service names it")
    func theServiceReportedCollectorIsRecognized() {
        let fee = transfer(index: 0, from: Self.owner, to: Self.serviceCollector, amount: 1, methodId: Self.gaslessMethodId)

        let extractedWithoutService = makeClassifier(serviceFeeRecipientAddress: nil).classify([fee])
        let extractedWithService = makeClassifier(serviceFeeRecipientAddress: Self.serviceCollector).classify([fee])

        #expect(extractedWithoutService.gaslessFees.isEmpty)
        #expect(extractedWithService.gaslessFees == [fee])
    }

    @Test("The fee is set aside, the transfer it paid for is merged without it")
    func theFeeIsTakenOutOfTheTransaction() {
        let payment = transfer(index: 0, from: Self.owner, to: Self.pool, amount: 10, methodId: Self.gaslessMethodId)
        let fee = transfer(index: 1, from: Self.owner, to: Self.knownCollector, amount: 1, methodId: Self.gaslessMethodId)

        let (standalone, mergeable, gaslessFees) = makeClassifier().classify([payment, fee])

        #expect(gaslessFees == [fee])
        #expect(standalone.isEmpty)
        #expect(mergeable == [payment])
    }

    /// Both halves of the rule have to hold: the method alone would take an ordinary Yield-mode send for a fee,
    /// and the address alone would take any payment that ever reached a collector for one.
    @Test("Neither half of the rule identifies a fee on its own")
    func neitherMethodNorAddressAloneMakesAFee() {
        let gaslessTransferElsewhere = transfer(
            index: 0,
            from: Self.owner,
            to: Self.pool,
            amount: 1,
            methodId: Self.gaslessMethodId
        )
        let plainTransferToACollector = transfer(index: 1, from: Self.owner, to: Self.knownCollector, amount: 1)

        let (standalone, mergeable, gaslessFees) = makeClassifier().classify([gaslessTransferElsewhere, plainTransferToACollector])

        #expect(gaslessFees.isEmpty)
        #expect(standalone.isEmpty)
        #expect(mergeable == [gaslessTransferElsewhere, plainTransferToACollector])
    }

    /// The relayer sends what goes through the executor and pays its gas, while the Yield module's `send` is signed
    /// and paid for by the wallet even when a gasless fee is taken from it.
    @Test(
        "Only a call through the executor was sent and paid for by the relayer",
        arguments: zip(["0x6234d42b", "0x4b072692", "0xf9b181bf", "0x0779afe6"], [true, true, true, false])
    )
    func onlyTheExecutorIsRelayed(methodId: String, isExecutorCall: Bool) {
        #expect(GaslessTransactionFeeMatcher.isExecutorCall(.contractMethodIdentifier(id: methodId)) == isExecutorCall)
    }

    // MARK: - Yield mode

    /// The wallet is the sender of these two, so the address says nothing and only the method does.
    @Test(
        "Entering and leaving Yield mode are operations of their own, an ordinary contract call is not",
        arguments: ["0x79be55f7", "0xc65e6dcf"]
    )
    func switchingYieldModeIsTakenOutOfTheMerge(methodId: String) {
        let yieldModeSwitch = transfer(index: 0, from: Self.owner, to: Self.aave, amount: 5, methodId: methodId)
        let ordinaryCall = transfer(index: 1, from: Self.owner, to: Self.pool, amount: 5, methodId: "0xe21fd0e9")

        let (standalone, mergeable, _) = makeClassifier().classify([yieldModeSwitch, ordinaryCall])

        #expect(standalone == [yieldModeSwitch])
        #expect(mergeable == [ordinaryCall])
    }

    @Test("What a Yield contract moves is an operation of its own and leaves the merge")
    func aYieldContractTransferIsExtracted() {
        let withdrawal = transfer(index: 0, from: Self.aave, to: Self.owner, amount: 20, isFromYieldContract: true)
        let payment = transfer(index: 1, from: Self.owner, to: Self.pool, amount: 20)

        let (standalone, mergeable, _) = makeClassifier().classify([withdrawal, payment])

        #expect(standalone == [withdrawal])
        #expect(mergeable == [payment])
    }

    // MARK: - Wiring

    @Test("The history that reaches the screen folds the gasless transaction into one row that carries its fee")
    func theMergeRoutineFoldsAGaslessTransaction() throws {
        let token = ExpressMergeTestDataFactory.ethereumUSDTToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: Self.owner,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let output = merger.merge(
            bsdkTransactions: [
                transfer(index: 0, from: Self.owner, to: Self.pool, amount: 10, methodId: Self.gaslessMethodId),
                transfer(index: 1, from: Self.owner, to: Self.pool, amount: 5, methodId: Self.gaslessMethodId),
                transfer(index: 2, from: Self.owner, to: Self.knownCollector, amount: 1, methodId: Self.gaslessMethodId),
            ],
            exchangeTransactions: [],
            onrampTransactions: []
        )

        let folded = try #require(output.singleElement)
        #expect(try #require(folded.source.sources.singleElement).amount == 15)
        #expect(folded.fee.amount.value == 1)
        #expect(folded.fee.amount.currencySymbol == "USDT")
    }

    /// Paying the fee in a token other than the one sent leaves nothing but the fee in this token's history.
    @Test("A fee its transaction left alone in the history keeps a row of its own")
    func aLoneGaslessFeeKeepsItsRow() throws {
        let token = ExpressMergeTestDataFactory.ethereumUSDTToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: Self.owner,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )
        let fee = transfer(index: 0, from: Self.owner, to: Self.knownCollector, amount: 1, methodId: Self.gaslessMethodId)

        let output = merger.merge(bsdkTransactions: [fee], exchangeTransactions: [], onrampTransactions: [])

        #expect(output == [fee])
    }

    /// A gasless send from Yield mode withdraws both what it sends and what it pays from Aave, all in one
    /// transaction: the send row carries the fee, and each withdrawal stays a row of its own.
    @Test("A gasless send from Yield mode is the send with its fee and the withdrawals that funded it")
    func aGaslessYieldSendKeepsItsWithdrawalsAndCarriesItsFee() throws {
        let token = ExpressMergeTestDataFactory.ethereumUSDTToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: Self.owner,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )
        let sendWithdrawal = transfer(
            index: 0,
            from: Self.aave,
            to: Self.owner,
            amount: 0.03,
            methodId: Self.gaslessMethodId,
            isFromYieldContract: true
        )
        let send = transfer(index: 1, from: Self.owner, to: Self.pool, amount: 0.03, methodId: Self.gaslessMethodId)
        let feeWithdrawal = transfer(
            index: 2,
            from: Self.aave,
            to: Self.owner,
            amount: 0.087865,
            methodId: Self.gaslessMethodId,
            isFromYieldContract: true
        )
        let fee = transfer(index: 3, from: Self.owner, to: Self.knownCollector, amount: 0.022519, methodId: Self.gaslessMethodId)

        let output = merger.merge(
            bsdkTransactions: [sendWithdrawal, send, feeWithdrawal, fee],
            exchangeTransactions: [],
            onrampTransactions: []
        )

        #expect(output.count == 3)
        #expect(!output.contains { $0.hasDestination(address: Self.knownCollector) })

        let sendRow = try #require(output.first { $0.isOutgoing })
        #expect(sendRow.fee.amount.value == 0.022519)
        #expect(sendRow.fee.amount.currencySymbol == "USDT")

        let withdrawals = output.filter(\.isFromYieldContract)
        #expect(withdrawals.count == 2)
        #expect(withdrawals.allSatisfy { $0.fee == ExpressMergeTestDataFactory.ethereumToken.zeroFee })
    }

    /// The money a withdrawal frees is spent by the very transaction that freed it, so folding the two together
    /// would net them to nothing and the history would show a transaction that moved zero.
    @Test("A withdrawal from Aave is not folded into the payment it funds")
    func aYieldWithdrawalSurvivesTheMerge() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: Self.owner,
            feeTokenItem: token
        )

        let output = merger.merge(
            bsdkTransactions: [
                transfer(index: 0, from: Self.aave, to: Self.owner, amount: 20, isFromYieldContract: true),
                transfer(index: 1, from: Self.owner, to: Self.pool, amount: 20),
            ],
            exchangeTransactions: [],
            onrampTransactions: []
        )

        #expect(output.count == 2)

        let payment = try #require(output.first { !$0.isFromYieldContract })
        #expect(try #require(payment.source.sources.singleElement).amount == 20)
    }
}

// MARK: - Fixtures

private extension TransactionHistoryTransferClassifierTests {
    static let owner = "0xowner"
    static let pool = "0xpool"
    static let aave = "0xaave"
    static let knownCollector = "0xFc719364BcCdc92D055d8C3164eF1ab4f5A9182c"
    static let serviceCollector = "0xServiceCollector"
    static let gaslessMethodId = "0x6234d42b"
    static let hash = "0xHash"

    func makeClassifier(serviceFeeRecipientAddress: String? = nil) -> TransactionHistoryTransferClassifier {
        let smartContractMethodMapper = StubClassifierSmartContractMethodMapper()

        return TransactionHistoryTransferClassifier(
            smartContractMethodMapper: smartContractMethodMapper,
            gaslessFeeMatcher: GaslessTransactionFeeMatcher(
                smartContractMethodMapper: smartContractMethodMapper,
                serviceFeeRecipientAddress: serviceFeeRecipientAddress
            )
        )
    }

    func transfer(
        hash: String = TransactionHistoryTransferClassifierTests.hash,
        index: Int,
        from: String,
        to: String,
        amount: Decimal,
        methodId: String? = nil,
        isFromYieldContract: Bool = false
    ) -> TransactionRecord {
        let type: TransactionRecord.TransactionType = methodId.map { .contractMethodIdentifier(id: $0) } ?? .transfer

        return TransactionRecord(
            hash: hash,
            index: index,
            source: .single(.init(address: from, amount: amount)),
            destination: .single(.init(address: .user(to), amount: amount)),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: from == Self.owner,
            type: type,
            date: ExpressMergeTestDataFactory.baseDate,
            tokenTransfers: [],
            isFromYieldContract: isFromYieldContract,
            nonce: nil
        )
    }
}

// MARK: - Stubs

/// Mirrors the names the shipped `contract_methods.json` gives the methods these tests use.
private struct StubClassifierSmartContractMethodMapper: SmartContractMethodMapper {
    private static let names = [
        "0x6234d42b": "gaslessTransaction",
        "0x79be55f7": "yieldEnter",
        "0xc65e6dcf": "yieldWithdraw",
    ]

    func getName(for method: String) -> String? {
        Self.names[method]
    }
}
