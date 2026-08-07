//
//  TransactionHistoryExpressDataMergerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

@Suite("TransactionHistoryExpressDataMerger")
struct TransactionHistoryExpressDataMergerTests {
    // MARK: - Deterministic hash matching

    @Test("Exchange: a pay-in hash match enriches the on-chain record and suppresses the synthetic")
    func exchangeDeterministicPayInHashMatch() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xPayInHash",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", try #require(Decimal(stringValue: "1.5")))],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        // An active status would normally produce a synthetic record had nothing matched.
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waiting,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: "0xPayInHash",
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: try #require(Decimal(stringValue: "1.5")),
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 1)
        let record = try #require(output.first)
        #expect(record.hash == "0xPayInHash")
        #expect(record.exchangeInfo?.transaction.txId == "exchange-tx")
    }

    @Test("Exchange: a pay-out hash match enriches the on-chain record")
    func exchangeDeterministicPayOutHashMatch() throws {
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xPayOutHash",
            isOutgoing: false,
            sources: ["0xCounterparty"],
            destinations: [("0xPayOut", 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: "0xPayOutHash",
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 1)
        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Onramp: a pay-out hash match enriches the on-chain record")
    func onrampDeterministicPayOutHashMatch() throws {
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xOnrampHash",
            isOutgoing: false,
            sources: ["0xCounterparty"],
            destinations: [("0xPayOut", 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "onramp-tx",
            status: .finished,
            payOutAddress: "0xPayOut",
            payOutHash: "0xOnrampHash",
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [], onrampTransactions: [onramp])

        #expect(output.count == 1)
        #expect(try #require(output.first).onrampInfo != nil)
    }

    // MARK: - Synthetic transaction gating

    @Test("Exchange: an active deal with no on-chain leg yields a synthetic record")
    func exchangeActiveStatusWithoutMatchYieldsSynthetic() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waiting,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 2,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
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
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 2,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.isEmpty)
    }

    @Test("Onramp: an active deal with no on-chain leg yields a synthetic record")
    func onrampActiveStatusWithoutMatchYieldsSynthetic() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )
        let targetAmount = try #require(Decimal(stringValue: "0.5"))

        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "onramp-tx",
            status: .waitingForPayment,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: targetAmount,
            toActualAmount: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
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
    func onrampTerminalStatusWithoutMatchIsDropped() throws {
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )
        let targetAmount = try #require(Decimal(stringValue: "0.5"))

        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "onramp-tx",
            status: .finished,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: targetAmount,
            toActualAmount: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [], exchangeTransactions: [], onrampTransactions: [onramp])

        #expect(output.isEmpty)
    }

    // MARK: - Send heuristic (Exchange)

    @Test("Send heuristic: matches an outgoing transfer to the pay-in address, ignoring change outputs")
    func sendHeuristicMatchesOutgoingToPayInAddress() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            // The pay-in leg equals the target amount; the second output is UTXO change and must be ignored.
            destinations: [("0xPayIn", try #require(Decimal(stringValue: "1.5"))), ("0xChange", 5)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: try #require(Decimal(stringValue: "1.5")),
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 1)
        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Send heuristic: a mismatched source currency prevents matching")
    func sendHeuristicCurrencyMismatchDoesNotMatch() throws {
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", try #require(Decimal(stringValue: "1.5")))],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: try #require(Decimal(stringValue: "1.5")),
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 1)
        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Send heuristic (EVM): an amount outside the (exact) tolerance prevents matching")
    func sendHeuristicEvmAmountOutsideToleranceDoesNotMatch() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", try #require(Decimal(stringValue: "1.6")))],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: try #require(Decimal(stringValue: "1.5")),
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Send heuristic (UTXO): matches within the 0.1% change tolerance")
    func sendHeuristicUtxoWithinToleranceMatches() throws {
        let token = ExpressMergeTestDataFactory.bitcoinToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "btcSend",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("btcPayIn", try #require(Decimal(stringValue: "1.0009")))],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.bitcoinToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "btcPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Send heuristic (UTXO): an amount beyond the 0.1% tolerance prevents matching")
    func sendHeuristicUtxoOutsideToleranceDoesNotMatch() throws {
        let token = ExpressMergeTestDataFactory.bitcoinToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "btcSend",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("btcPayIn", try #require(Decimal(stringValue: "1.0011")))],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.bitcoinToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "btcPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Send heuristic (EVM): addresses are compared case-insensitively")
    func sendHeuristicEvmAddressCaseInsensitive() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: ["0xowner"],
            destinations: [("0xpayin", try #require(Decimal(stringValue: "1.5")))],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: "0xOWNER",
            payInAddress: "0xPAYIN",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: try #require(Decimal(stringValue: "1.5")),
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Send heuristic: the earliest of several candidates is selected")
    func sendHeuristicSelectsEarliestCandidate() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let early = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xEarly",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", 1)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(100),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let late = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xLate",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", 1)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(200),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [early, late], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(record(in: output, hash: "0xEarly")?.exchangeInfo != nil)
        #expect(record(in: output, hash: "0xLate")?.isEnriched == false)
    }

    @Test("Send heuristic: the sender must be the deal's from-address")
    func sendHeuristicRequiresSenderIsOwner() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: ["0xSomeoneElse"],
            destinations: [("0xPayIn", 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Send heuristic: a non-positive target amount is rejected (division-by-zero guard)")
    func sendHeuristicZeroAmountIsRejected() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", 0)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 0,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Send heuristic: a nil from-address falls back to the owner address for the sender check")
    func sendHeuristicFallsBackToOwnerAddressWhenFromAddressNil() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress], // sent by the owner
            destinations: [("0xPayIn", 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: nil, // no explicit sender -> falls back to the owner address
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Send heuristic: the target amount uses the actual amount when present")
    func sendHeuristicUsesActualAmountAsTarget() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        // The on-chain amount matches the actual amount, not the (different) expected amount.
        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", 2)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 1,
            fromActualAmount: 2,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    // MARK: - Receive heuristic (Exchange)

    @Test("Receive heuristic: matches an incoming transfer to the pay-out address within the 5% tolerance")
    func receiveHeuristicMatchesIncomingToPayOutAddress() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", try #require(Decimal(stringValue: "2.05"))), ("0xOther", 9)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Receive heuristic: a self-transfer (sender is the user) is excluded")
    func receiveHeuristicExcludesSelfTransfer() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayOut", 2)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Receive heuristic: a transfer outside the 24h window is excluded")
    func receiveHeuristicExcludesOutsideTimeWindow() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", 2)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(ExpressMergeTestDataFactory.dayInSeconds + 60),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Receive heuristic: a refunded deal does not match an incoming pay-out")
    func receiveHeuristicSkippedForRefundedDeal() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", 2)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .refunded,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Receive heuristic: a nil from-address falls back to the owner address when excluding self-transfers")
    func receiveHeuristicExcludesSelfTransferViaOwnerAddressFallback() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: [ExpressMergeTestDataFactory.ownerAddress], // "self" sender
            destinations: [("0xPayOut", 2)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: nil, // falls back to the owner address for the self-transfer check
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Receive heuristic: the 24h window is anchored on createdAt, not updatedAt")
    func receiveHeuristicWindowIsAnchoredOnCreatedAt() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        // Just past createdAt + 24h, but well within updatedAt + 24h.
        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", 2)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(ExpressMergeTestDataFactory.dayInSeconds + 3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(10 * ExpressMergeTestDataFactory.dayInSeconds)
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Receive heuristic: an amount outside the 5% tolerance prevents matching")
    func receiveHeuristicExcludesAmountOutsideTolerance() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", try #require(Decimal(stringValue: "2.2")))],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Receive heuristic: an amount exactly at the 5% tolerance boundary still matches")
    func receiveHeuristicMatchesAtToleranceBoundary() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        // |2.1 - 2| == 0.1 == 5% of 2.
        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", try #require(Decimal(stringValue: "2.1")))],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Receive heuristic: a mismatched destination currency prevents matching")
    func receiveHeuristicCurrencyMismatchDoesNotMatch() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", 2)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 2,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Receive heuristic: the target amount uses the actual amount when present")
    func receiveHeuristicUsesActualAmountAsTarget() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        // The on-chain amount matches the actual amount, not the (different) expected amount.
        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", 3)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: 3,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    // MARK: - Refund heuristic (Exchange)

    @Test("Refund heuristic: matches an incoming refund within the 15% tolerance and time window")
    func refundHeuristicMatchesIncomingRefund() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRefund",
            isOutgoing: false,
            sources: ["0xProvider"],
            destinations: [("0xAnywhere", try #require(Decimal(stringValue: "0.9")))],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .refunded,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: ExpressMergeTestDataFactory.refundInfo(currency: ExpressMergeTestDataFactory.matchingCurrency(for: token), address: "0xRefund"),
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Refund heuristic: an amount outside the 15% tolerance prevents matching")
    func refundHeuristicAmountOutsideToleranceDoesNotMatch() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRefund",
            isOutgoing: false,
            sources: ["0xProvider"],
            destinations: [("0xAnywhere", try #require(Decimal(stringValue: "1.2")))],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .refunded,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: ExpressMergeTestDataFactory.refundInfo(currency: ExpressMergeTestDataFactory.matchingCurrency(for: token), address: "0xRefund"),
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Refund heuristic: the window extends to updatedAt + 24h (unlike the receive heuristic)")
    func refundHeuristicWindowIsAnchoredOnUpdatedAt() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        // Past createdAt + 24h (so the receive window would reject it) but within updatedAt + 24h.
        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRefund",
            isOutgoing: false,
            sources: ["0xProvider"],
            destinations: [("0xAnywhere", try #require(Decimal(stringValue: "0.9")))],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(ExpressMergeTestDataFactory.dayInSeconds + 3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .refunded,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: ExpressMergeTestDataFactory.refundInfo(currency: ExpressMergeTestDataFactory.matchingCurrency(for: token), address: "0xRefund"),
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(10 * ExpressMergeTestDataFactory.dayInSeconds)
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(try #require(output.first).exchangeInfo != nil)
    }

    @Test("Refund heuristic: a refunded swap enriches both the on-chain deposit and refund legs")
    func refundedSwapEnrichesBothDepositAndRefundLegs() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let deposit = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xDeposit",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let refund = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRefund",
            isOutgoing: false,
            sources: ["0xProvider"],
            destinations: [("0xAnywhere", try #require(Decimal(stringValue: "0.95")))],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        // Refunded swap on the from-token: the deposit matches the send heuristic and the refund
        // matches the refund heuristic, which runs regardless of the earlier send/receive match.
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .refunded,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: ExpressMergeTestDataFactory.refundInfo(currency: ExpressMergeTestDataFactory.matchingCurrency(for: token), address: "0xRefund"),
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [deposit, refund], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 2)
        #expect(record(in: output, hash: "0xDeposit")?.exchangeInfo != nil)
        #expect(record(in: output, hash: "0xRefund")?.exchangeInfo != nil)
    }

    // MARK: - Receive heuristic (Onramp)

    @Test("Onramp receive heuristic: matches an incoming pay-out even when the sender is the user")
    func onrampReceiveHeuristicMatchesWithoutSelfTransferCheck() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xOnRecv",
            isOutgoing: false,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayOut", 2)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "onramp-tx",
            status: .finished,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [], onrampTransactions: [onramp])

        #expect(try #require(output.first).onrampInfo != nil)
    }

    @Test("Onramp receive heuristic: the 24h window is anchored on createdAt, not updatedAt")
    func onrampReceiveHeuristicWindowIsAnchoredOnCreatedAt() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        // Just past createdAt + 24h, but well within updatedAt + 24h.
        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xOnRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", 2)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(ExpressMergeTestDataFactory.dayInSeconds + 3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "onramp-tx",
            status: .finished,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(10 * ExpressMergeTestDataFactory.dayInSeconds)
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [], onrampTransactions: [onramp])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Onramp receive heuristic: an amount outside the 5% tolerance prevents matching")
    func onrampReceiveHeuristicExcludesAmountOutsideTolerance() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xOnRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", try #require(Decimal(stringValue: "2.2")))],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "onramp-tx",
            status: .finished,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [], onrampTransactions: [onramp])

        #expect(!(try #require(output.first).isEnriched))
    }

    @Test("Onramp receive heuristic: a mismatched destination currency prevents matching")
    func onrampReceiveHeuristicCurrencyMismatchDoesNotMatch() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xOnRecv",
            isOutgoing: false,
            sources: ["0xSender"],
            destinations: [("0xPayOut", 2)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "onramp-tx",
            status: .finished,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 2,
            toActualAmount: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [], onrampTransactions: [onramp])

        #expect(!(try #require(output.first).isEnriched))
    }

    // MARK: - Tombstoning (no double-matching)

    @Test("A pay-in hash already claimed by one deal is not re-consumed by another")
    func deterministicMatchIsNotDoubleConsumed() throws {
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xShared",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let first = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "E1",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: "0xShared",
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )
        // Second deal also points at the shared hash but is an incoming, active deal,
        // so once it fails to re-claim the record it falls back to its own synthetic.
        let second = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "E2",
            status: .waiting,
            fromAddress: "0xNotOwner",
            payInAddress: "0xPayIn",
            payInHash: "0xShared",
            payOutAddress: ExpressMergeTestDataFactory.ownerAddress,
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [first, second], onrampTransactions: [])

        #expect(output.count == 2)
        #expect(record(in: output, hash: "0xShared")?.exchangeInfo?.transaction.txId == "E1")
        let synthetic = try #require(record(in: output, hash: "E2"))
        #expect(synthetic.exchangeInfo?.transaction.txId == "E2")
    }

    @Test("Heuristic matching honours the consumed-id set, preventing a second claim of the same record")
    func heuristicMatchHonoursConsumedSet() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let makeExchange = { (txId: String) in
            ExpressMergeTestDataFactory.exchangeTransaction(
                txId: txId,
                status: .finished,
                fromAddress: ExpressMergeTestDataFactory.ownerAddress,
                payInAddress: "0xPayIn",
                payInHash: nil,
                payOutAddress: "0xPayOut",
                payOutHash: nil,
                fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
                fromAmount: 1,
                fromActualAmount: nil,
                toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
                toAmount: 1,
                toActualAmount: nil,
                refund: nil,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
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
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xRandom",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xElsewhere", 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [], onrampTransactions: [])

        #expect(output.count == 1)
        let record = try #require(output.first)
        #expect(record.hash == "0xRandom")
        #expect(!record.isEnriched)
    }

    @Test("Records are sorted by date DESC, then nonce DESC, then hash ASC")
    func recordsAreSortedByDateNonceHash() {
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let newerNoNonce = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xB",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xElsewhere", 1)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(1000),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let older = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xZ",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xElsewhere", 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let newerNonceC = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xC",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xElsewhere", 1)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(1000),
            index: 0,
            nonce: 5,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let newerNonceA = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xA",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xElsewhere", 1)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(1000),
            index: 0,
            nonce: 5,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
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
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let dated = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xDated",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xElsewhere", 1)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(1000),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let undated = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xUndated",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xElsewhere", 1)],
            date: nil,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )

        let output = merger.merge(bsdkTransactions: [dated, undated], exchangeTransactions: [], onrampTransactions: [])

        #expect(output.first?.hash == "0xUndated")
    }

    @Test("Records sharing a hash (and date/nonce) are ordered by index ascending")
    func recordsWithSameHashAreSortedByIndexAscending() {
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let indexOne = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSame",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xElsewhere", 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 1,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let indexZero = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSame",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xElsewhere", 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )

        // Fed in reverse to prove the sort reorders them.
        let output = merger.merge(bsdkTransactions: [indexOne, indexZero], exchangeTransactions: [], onrampTransactions: [])

        #expect(output.map(\.index) == [0, 1])
    }

    // MARK: - Helpers

    private func record(in output: [TransactionRecord], hash: String) -> TransactionRecord? {
        output.first { $0.hash == hash }
    }
}
