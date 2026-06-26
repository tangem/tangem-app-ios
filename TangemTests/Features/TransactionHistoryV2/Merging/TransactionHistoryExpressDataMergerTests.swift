//
//  TransactionHistoryExpressDataMergerTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

private typealias F = ExpressMergeTestFixtures

@Suite("TransactionHistoryExpressDataMerger")
struct TransactionHistoryExpressDataMergerTests {
    // MARK: - Deterministic hash matching

    @Test("Exchange: a pay-in hash match enriches the on-chain record and suppresses the synthetic")
    func exchangeDeterministicPayInHashMatch() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xPayInHash",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xPayIn", F.dec("1.5"))],
            date: F.baseDate
        )
        // An active status would normally produce a synthetic record had nothing matched.
        let exchange = F.exchangeTransaction(
            status: .waiting,
            payInHash: "0xPayInHash",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("1.5"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 1)
        let record = try #require(output.first)
        #expect(record.hash == "0xPayInHash")
        #expect(record.exchangeInfo?.transaction.txId == "exchange-tx")
    }

    @Test("Exchange: a pay-out hash match enriches the on-chain record")
    func exchangeDeterministicPayOutHashMatch() throws {
        let merger = F.makeMerger()

        let onChain = F.bsdkTransaction(
            hash: "0xPayOutHash",
            isOutgoing: false,
            sources: ["0xCounterparty"],
            destinations: [("0xPayOut", F.dec("1"))],
            date: F.baseDate
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            payInHash: nil,
            payOutHash: "0xPayOutHash",
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 1)
        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Onramp: a pay-out hash match enriches the on-chain record")
    func onrampDeterministicPayOutHashMatch() throws {
        let merger = F.makeMerger()

        let onChain = F.bsdkTransaction(
            hash: "0xOnrampHash",
            isOutgoing: false,
            sources: ["0xCounterparty"],
            destinations: [("0xPayOut", F.dec("1"))],
            date: F.baseDate
        )
        let onramp = F.onrampTransaction(
            status: .finished,
            payOutHash: "0xOnrampHash",
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [], onrampTransactions: [onramp])

        #expect(output.count == 1)
        #expect(try #require(output.first).onrampInfo != nil)
    }

    // MARK: - Synthetic transaction gating

    @Test("Exchange: an active deal with no on-chain leg yields a synthetic record")
    func exchangeActiveStatusWithoutMatchYieldsSynthetic() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let exchange = F.exchangeTransaction(
            status: .waiting,
            fromAddress: F.ownerAddress,
            payOutAddress: "0xPayOut",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("2"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 1)
        let synthetic = try #require(output.first)
        #expect(synthetic.type == .contractMethodName(name: "swap"))
        #expect(synthetic.isOutgoing)
        #expect(synthetic.status == .unconfirmed)
        #expect(synthetic.hash == "exchange-tx")
        #expect(synthetic.exchangeInfo != nil)
    }

    @Test("Exchange: a terminal deal with no on-chain leg is dropped (no synthetic)")
    func exchangeTerminalStatusWithoutMatchIsDropped() {
        let merger = F.makeMerger()

        let exchange = F.exchangeTransaction(
            status: .finished,
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("2"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.isEmpty)
    }

    @Test("Onramp: an active deal with no on-chain leg yields a synthetic record")
    func onrampActiveStatusWithoutMatchYieldsSynthetic() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onramp = F.onrampTransaction(
            status: .waitingForPayment,
            toCurrency: F.matchingCurrency(for: token),
            toAmount: F.dec("0.5")
        )

        let output = merger.merge(bsdkTransactions: [], exchangeTransactions: [], onrampTransactions: [onramp])

        #expect(output.count == 1)
        let synthetic = try #require(output.first)
        #expect(synthetic.type == .contractMethodName(name: "onramp"))
        #expect(!synthetic.isOutgoing)
        #expect(synthetic.status == .unconfirmed)
        #expect(synthetic.onrampInfo != nil)
    }

    @Test("Onramp: a terminal deal with no on-chain leg is dropped (no synthetic)")
    func onrampTerminalStatusWithoutMatchIsDropped() {
        let merger = F.makeMerger()

        let onramp = F.onrampTransaction(
            status: .finished,
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("0.5")
        )

        let output = merger.merge(bsdkTransactions: [], exchangeTransactions: [], onrampTransactions: [onramp])

        #expect(output.isEmpty)
    }

    // MARK: - Send heuristic (Exchange)

    @Test("Send heuristic: matches an outgoing transfer to the pay-in address, ignoring change outputs")
    func sendHeuristicMatchesOutgoingToPayInAddress() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [F.ownerAddress],
            // The pay-in leg equals the target amount; the second output is UTXO change and must be ignored.
            destinations: [("0xPayIn", F.dec("1.5")), ("0xChange", F.dec("5"))],
            date: F.baseDate
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            fromAddress: F.ownerAddress,
            payInAddress: "0xPayIn",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("1.5"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 1)
        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Send heuristic: a mismatched source currency prevents matching")
    func sendHeuristicCurrencyMismatchDoesNotMatch() throws {
        let merger = F.makeMerger()

        let onChain = F.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xPayIn", F.dec("1.5"))],
            date: F.baseDate
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            fromAddress: F.ownerAddress,
            payInAddress: "0xPayIn",
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("1.5"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 1)
        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Send heuristic (EVM): an amount outside the (exact) tolerance prevents matching")
    func sendHeuristicEvmAmountOutsideToleranceDoesNotMatch() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xPayIn", F.dec("1.6"))],
            date: F.baseDate
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            fromAddress: F.ownerAddress,
            payInAddress: "0xPayIn",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("1.5"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Send heuristic (UTXO): matches within the 0.1% change tolerance")
    func sendHeuristicUtxoWithinToleranceMatches() throws {
        let token = F.bitcoinToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "btcSend",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("btcPayIn", F.dec("1.0009"))],
            date: F.baseDate
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            fromAddress: F.ownerAddress,
            payInAddress: "btcPayIn",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Send heuristic (UTXO): an amount beyond the 0.1% tolerance prevents matching")
    func sendHeuristicUtxoOutsideToleranceDoesNotMatch() throws {
        let token = F.bitcoinToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "btcSend",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("btcPayIn", F.dec("1.0011"))],
            date: F.baseDate
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            fromAddress: F.ownerAddress,
            payInAddress: "btcPayIn",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Send heuristic (EVM): addresses are compared case-insensitively")
    func sendHeuristicEvmAddressCaseInsensitive() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: ["0xowner"],
            destinations: [("0xpayin", F.dec("1.5"))],
            date: F.baseDate
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            fromAddress: "0xOWNER",
            payInAddress: "0xPAYIN",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("1.5"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Send heuristic: the earliest of several candidates is selected")
    func sendHeuristicSelectsEarliestCandidate() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let early = F.bsdkTransaction(
            hash: "0xEarly",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xPayIn", F.dec("1"))],
            date: F.date(offset: 100)
        )
        let late = F.bsdkTransaction(
            hash: "0xLate",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xPayIn", F.dec("1"))],
            date: F.date(offset: 200)
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            fromAddress: F.ownerAddress,
            payInAddress: "0xPayIn",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [early, late], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(record(in: output, hash: "0xEarly")?.exchangeInfo != nil)
        #expect(record(in: output, hash: "0xLate")?.isEnriched == false)
    }

    @Test("Send heuristic: the sender must be the deal's from-address")
    func sendHeuristicRequiresSenderIsOwner() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: ["0xSomeoneElse"],
            destinations: [("0xPayIn", F.dec("1"))],
            date: F.baseDate
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            fromAddress: F.ownerAddress,
            payInAddress: "0xPayIn",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Send heuristic: a non-positive target amount is rejected (division-by-zero guard)")
    func sendHeuristicZeroAmountIsRejected() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xPayIn", F.dec("0"))],
            date: F.baseDate
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            fromAddress: F.ownerAddress,
            payInAddress: "0xPayIn",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("0"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    // MARK: - Receive heuristic (Exchange)

    @Test("Receive heuristic: matches an incoming transfer to the pay-out address within the 5% tolerance")
    func receiveHeuristicMatchesIncomingToPayOutAddress() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", F.dec("2.05")), ("0xOther", F.dec("9"))],
            date: F.date(offset: 3600)
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            fromAddress: F.ownerAddress,
            payOutAddress: "0xPayOut",
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("1"),
            toCurrency: F.matchingCurrency(for: token),
            toAmount: F.dec("2")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Receive heuristic: a self-transfer (sender is the user) is excluded")
    func receiveHeuristicExcludesSelfTransfer() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: [F.ownerAddress],
            destinations: [("0xPayOut", F.dec("2"))],
            date: F.date(offset: 3600)
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            fromAddress: F.ownerAddress,
            payOutAddress: "0xPayOut",
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("1"),
            toCurrency: F.matchingCurrency(for: token),
            toAmount: F.dec("2")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Receive heuristic: a transfer outside the 24h window is excluded")
    func receiveHeuristicExcludesOutsideTimeWindow() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", F.dec("2"))],
            date: F.date(offset: F.dayInSeconds + 60)
        )
        let exchange = F.exchangeTransaction(
            status: .finished,
            fromAddress: F.ownerAddress,
            payOutAddress: "0xPayOut",
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("1"),
            toCurrency: F.matchingCurrency(for: token),
            toAmount: F.dec("2"),
            createdAt: F.baseDate,
            updatedAt: F.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Receive heuristic: a refunded deal does not match an incoming pay-out")
    func receiveHeuristicSkippedForRefundedDeal() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", F.dec("2"))],
            date: F.date(offset: 3600)
        )
        let exchange = F.exchangeTransaction(
            status: .refunded,
            fromAddress: F.ownerAddress,
            payOutAddress: "0xPayOut",
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("1"),
            toCurrency: F.matchingCurrency(for: token),
            toAmount: F.dec("2"),
            refund: nil
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    // MARK: - Refund heuristic (Exchange)

    @Test("Refund heuristic: matches an incoming refund within the 15% tolerance and time window")
    func refundHeuristicMatchesIncomingRefund() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xRefund",
            isOutgoing: false,
            sources: ["0xProvider"],
            destinations: [("0xAnywhere", F.dec("0.9"))],
            date: F.date(offset: 3600)
        )
        let exchange = F.exchangeTransaction(
            status: .refunded,
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1"),
            refund: F.refundInfo(currency: F.matchingCurrency(for: token))
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Refund heuristic: an amount outside the 15% tolerance prevents matching")
    func refundHeuristicAmountOutsideToleranceDoesNotMatch() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xRefund",
            isOutgoing: false,
            sources: ["0xProvider"],
            destinations: [("0xAnywhere", F.dec("1.2"))],
            date: F.date(offset: 3600)
        )
        let exchange = F.exchangeTransaction(
            status: .refunded,
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1"),
            refund: F.refundInfo(currency: F.matchingCurrency(for: token))
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    // MARK: - Receive heuristic (Onramp)

    @Test("Onramp receive heuristic: matches an incoming pay-out even when the sender is the user")
    func onrampReceiveHeuristicMatchesWithoutSelfTransferCheck() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xOnRecv",
            isOutgoing: false,
            sources: [F.ownerAddress],
            destinations: [("0xPayOut", F.dec("2"))],
            date: F.date(offset: 3600)
        )
        let onramp = F.onrampTransaction(
            status: .finished,
            payOutAddress: "0xPayOut",
            toCurrency: F.matchingCurrency(for: token),
            toAmount: F.dec("2")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [], onrampTransactions: [onramp])

        #expect(try #require(output.first).onrampInfo != nil)
    }

    // MARK: - Tombstoning (no double-matching)

    @Test("A pay-in hash already claimed by one deal is not re-consumed by another")
    func deterministicMatchIsNotDoubleConsumed() throws {
        let merger = F.makeMerger()

        let onChain = F.bsdkTransaction(
            hash: "0xShared",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xPayIn", F.dec("1"))],
            date: F.baseDate
        )
        let first = F.exchangeTransaction(
            txId: "E1",
            status: .finished,
            payInHash: "0xShared",
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )
        // Second deal also points at the shared hash but is an incoming, active deal,
        // so once it fails to re-claim the record it falls back to its own synthetic.
        let second = F.exchangeTransaction(
            txId: "E2",
            status: .waiting,
            fromAddress: "0xNotOwner",
            payInHash: "0xShared",
            payOutAddress: F.ownerAddress,
            payOutHash: nil,
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [first, second], onrampTransactions: [])

        #expect(output.count == 2)
        #expect(record(in: output, hash: "0xShared")?.exchangeInfo?.transaction.txId == "E1")
        let synthetic = try #require(record(in: output, hash: "E2"))
        #expect(synthetic.exchangeInfo?.transaction.txId == "E2")
    }

    @Test("Heuristic matching honours the consumed-id set, preventing a second claim of the same record")
    func heuristicMatchHonoursConsumedSet() throws {
        let token = F.ethereumToken
        let merger = F.makeMerger(currentToken: token)

        let onChain = F.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xPayIn", F.dec("1"))],
            date: F.baseDate
        )
        let makeExchange = { (txId: String) in
            F.exchangeTransaction(
                txId: txId,
                status: .finished,
                fromAddress: F.ownerAddress,
                payInAddress: "0xPayIn",
                fromCurrency: F.matchingCurrency(for: token),
                fromAmount: F.dec("1"),
                toCurrency: F.unrelatedCurrency,
                toAmount: F.dec("1")
            )
        }

        let output = merger.merge(
            bsdkTransactions: [onChain],
            exchangeTransactions: [makeExchange("E1"), makeExchange("E2")],
            onrampTransactions: []
        )

        #expect(output.count == 1)
        #expect(try #require(output.first).exchangeInfo?.transaction.txId == "E1")
    }

    // MARK: - Pass-through and ordering

    @Test("On-chain records not matched by any deal are passed through unchanged")
    func unmatchedRecordsArePassedThrough() throws {
        let merger = F.makeMerger()

        let onChain = F.bsdkTransaction(
            hash: "0xRandom",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xElsewhere", F.dec("1"))],
            date: F.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [], onrampTransactions: [])

        #expect(output.count == 1)
        let record = try #require(output.first)
        #expect(record.hash == "0xRandom")
        #expect(!record.isEnriched)
    }

    @Test("Records are sorted by date DESC, then nonce DESC, then hash ASC")
    func recordsAreSortedByDateNonceHash() {
        let merger = F.makeMerger()

        let newerNoNonce = F.bsdkTransaction(
            hash: "0xB",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xElsewhere", F.dec("1"))],
            date: F.date(offset: 1000),
            nonce: nil
        )
        let older = F.bsdkTransaction(
            hash: "0xZ",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xElsewhere", F.dec("1"))],
            date: F.date(offset: 0),
            nonce: nil
        )
        let newerNonceC = F.bsdkTransaction(
            hash: "0xC",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xElsewhere", F.dec("1"))],
            date: F.date(offset: 1000),
            nonce: 5
        )
        let newerNonceA = F.bsdkTransaction(
            hash: "0xA",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xElsewhere", F.dec("1"))],
            date: F.date(offset: 1000),
            nonce: 5
        )

        let output = merger.merge(
            bsdkTransactions: [newerNoNonce, older, newerNonceC, newerNonceA],
            exchangeTransactions: [],
            onrampTransactions: []
        )

        // Newer date first; within the same date higher nonce wins; ties broken by hash ascending.
        #expect(output.map(\.hash) == ["0xA", "0xC", "0xB", "0xZ"])
    }

    @Test("A record with no date sorts ahead of dated records")
    func recordWithoutDateSortsFirst() {
        let merger = F.makeMerger()

        let dated = F.bsdkTransaction(
            hash: "0xDated",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xElsewhere", F.dec("1"))],
            date: F.date(offset: 1000)
        )
        let undated = F.bsdkTransaction(
            hash: "0xUndated",
            isOutgoing: true,
            sources: [F.ownerAddress],
            destinations: [("0xElsewhere", F.dec("1"))],
            date: nil
        )

        let output = merger.merge(bsdkTransactions: [dated, undated], exchangeTransactions: [], onrampTransactions: [])

        #expect(output.first?.hash == "0xUndated")
    }

    // MARK: - Helpers

    private func record(in output: [TransactionRecord], hash: String) -> TransactionRecord? {
        output.first { $0.hash == hash }
    }
}
