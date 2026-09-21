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
        #expect(synthetic.hash == "ExpressSyntheticTx_exchange-tx")
        #expect(synthetic.exchangeInfo != nil)
    }

    @Test("Exchange: a terminal deal with no on-chain leg still yields a synthetic record")
    func exchangeTerminalStatusWithoutMatchYieldsSynthetic() throws {
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

        #expect(output.count == 1)
        let synthetic = try #require(output.first)
        #expect(synthetic.hash == "ExpressSyntheticTx_exchange-tx")
        #expect(synthetic.exchangeInfo != nil)
    }

    @Test("Exchange: a `created` deal without a pay-in hash yields no synthetic record")
    func exchangeCreatedStatusWithoutPayInHashYieldsNoSynthetic() {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .created,
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

        #expect(output.isEmpty)
    }

    @Test("Exchange: a `created` deal with a pay-in hash yields a synthetic record")
    func exchangeCreatedStatusWithPayInHashYieldsSynthetic() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .created,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: "0xPayInHash",
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
        #expect(synthetic.hash == "ExpressSyntheticTx_exchange-tx")
        #expect(synthetic.exchangeInfo != nil)
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

    @Test("Onramp: a terminal deal with no on-chain leg still yields a synthetic record")
    func onrampTerminalStatusWithoutMatchYieldsSynthetic() throws {
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

        #expect(output.count == 1)
        let synthetic = try #require(output.first)
        #expect(synthetic.hash == "ExpressSyntheticTx_onramp-tx")
        #expect(synthetic.onrampInfo != nil)
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

        // The deal doesn't claim the on-chain transfer, so it contributes a synthetic record of its own
        #expect(output.count == 2)
        #expect(!(try #require(output.first { $0.hash == "0xSend" }).isEnriched))
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

        // The deal doesn't claim the on-chain transfer, so it contributes a synthetic record of its own
        #expect(output.count == 2)
        #expect(!(try #require(output.first { $0.hash == "btcSend" }).isEnriched))
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

    @Test("Send heuristic: the sender must be one of the wallet's addresses")
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

    @Test("Send heuristic: a nil from-address doesn't affect the sender check")
    func sendHeuristicIgnoresNilFromAddressForSenderCheck() throws {
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
            fromAddress: nil, // the sender check reads the wallet addresses either way
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

    @Test("Receive heuristic: a nil from-address doesn't affect the self-transfer check")
    func receiveHeuristicExcludesSelfTransferRegardlessOfFromAddress() throws {
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
            fromAddress: nil, // the self-transfer check reads the wallet addresses either way
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
        let synthetic = try #require(record(in: output, hash: "ExpressSyntheticTx_E2"))
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

        // `E1` claims the on-chain transfer, `E2` can't re-claim it and contributes a synthetic record instead
        #expect(output.count == 2)
        #expect(try #require(output.first { $0.hash == "0xSend" }).exchangeInfo?.transaction.txId == "E1")
        #expect(try #require(output.first { $0.hash == "ExpressSyntheticTx_E2" }).exchangeInfo?.transaction.txId == "E2")
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

    // MARK: - Multi-address wallets and normalized currencies

    @Test("Send heuristic (UTXO): matches a transfer spent from a derived address the deal never recorded")
    func sendHeuristicMatchesSpendFromDerivedAddress() throws {
        let token = ExpressMergeTestDataFactory.bitcoinToken
        // Express records the wallet's default address, which on chains with dynamic addresses is the first
        // unused one and therefore never an input of the transaction that funded the deal.
        let defaultAddress = "bc1qDefault"
        let derivedAddress = "bc1qDerived"
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            walletAddresses: [defaultAddress, derivedAddress],
            feeTokenItem: token
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSend",
            isOutgoing: true,
            sources: [derivedAddress],
            destinations: [("bc1qPayIn", 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waiting,
            fromAddress: defaultAddress,
            payInAddress: "bc1qPayIn",
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

        // A miss would leave the on-chain record unenriched and add a synthetic one next to it
        #expect(output.count == 1)
        #expect(try #require(output.first).isEnriched)
    }

    @Test("Receive heuristic: a self-transfer is excluded even when the deal's from-address is on another network")
    func receiveHeuristicExcludesSelfTransferWithForeignFromAddress() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        // The pay-out leg is on the current network while the from-address belongs to the source one,
        // so it can never equal any of this transaction's inputs
        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xReceive",
            isOutgoing: false,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [(ExpressMergeTestDataFactory.ownerAddress, 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waiting,
            fromAddress: "bc1qSourceNetwork",
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: ExpressMergeTestDataFactory.ownerAddress,
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(!(try #require(record(in: output, hash: "0xReceive")).isEnriched))
    }

    @Test("Send heuristic: a checksummed contract address still matches the stored lower-cased one")
    func sendHeuristicMatchesChecksummedContractAddress() throws {
        let token = ExpressMergeTestDataFactory.ethereumUSDTToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
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
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waiting,
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

        #expect(output.count == 1)
        #expect(try #require(output.first).isEnriched)
    }

    @Test("Receive heuristic: a checksummed contract address still matches the stored lower-cased one")
    func receiveHeuristicMatchesChecksummedContractAddress() throws {
        let token = ExpressMergeTestDataFactory.ethereumUSDTToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xReceive",
            isOutgoing: false,
            sources: ["0xCounterparty"],
            destinations: [(ExpressMergeTestDataFactory.ownerAddress, 1)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: ExpressMergeTestDataFactory.ethereumToken
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waiting,
            fromAddress: "0xSender",
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: ExpressMergeTestDataFactory.ownerAddress,
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 1)
        #expect(try #require(output.first).isEnriched)
    }

    // MARK: - Leg claiming

    @Test("Exchange: a fee transfer sharing the pay-in transaction is not claimed as the swap leg")
    func exchangeDoesNotClaimFeeTransferSharingThePayInHash() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        // A gasless transaction pays its fee with a second transfer of the same token within the same
        // on-chain transaction, so both transfers share the pay-in hash and differ only in index.
        let feeTransfer = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xPayInHash",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xFeeRecipient", try #require(Decimal(stringValue: "0.5")))],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let swapTransfer = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xPayInHash",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", 43)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 1,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: "0xPayInHash",
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 43,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [feeTransfer, swapTransfer], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 2)
        #expect(record(in: output, index: 1)?.exchangeInfo?.transaction.txId == "exchange-tx")
        #expect(record(in: output, index: 0)?.isEnriched == false)
    }

    @Test("Exchange: a co-traveller transferring the deal's amount elsewhere is not claimed as the swap leg")
    func exchangeDoesNotClaimCoTravellerCarryingTheSameAmount() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        // Both transfers move exactly the deal's amount, but only one of them sends it to the pay-in address;
        // comparing the whole transferred amount alone would claim the other one as a second leg.
        let swapTransfer = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xPayInHash",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", 43)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let unrelatedTransfer = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xPayInHash",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xSomeoneElse", 43)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 1,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: "0xPayInHash",
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 43,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [swapTransfer, unrelatedTransfer], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 2)
        #expect(record(in: output, index: 0)?.exchangeInfo?.transaction.txId == "exchange-tx")
        #expect(record(in: output, index: 1)?.isEnriched == false)
    }

    @Test("Exchange: the pay-in transaction is not claimed as the leg of the token being bought")
    func exchangeDoesNotClaimPayInTransactionForDestinationToken() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        // Both legs of a DEX swap live on the same blockchain, so the swap call the user sent also shows up
        // in the history of the token being bought — where it carries none of the received amount.
        let swapCall = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSwapHash",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xRouter", 0)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xRouter",
            payInHash: "0xSwapHash",
            payOutAddress: ExpressMergeTestDataFactory.ownerAddress,
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 549,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [swapCall], exchangeTransactions: [exchange], onrampTransactions: [])

        // The pay-out leg has no on-chain record of its own (it arrives as an internal transfer),
        // so the deal is represented by a synthetic record instead of the pay-in transaction.
        #expect(output.count == 2)
        #expect(record(in: output, hash: "0xSwapHash")?.isEnriched == false)
        #expect(record(in: output, hash: "ExpressSyntheticTx_exchange-tx")?.exchangeInfo != nil)
    }

    @Test("Exchange: a hashless DEX deal claims the received leg instead of duplicating it with a synthetic")
    func exchangeClaimsReceivedLegOfHashlessDeal() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )
        let receivedAmount = try #require(Decimal(stringValue: "28.432395"))

        // A DEX deal reports neither leg's hash, so the pay-out leg can only be matched by the receive
        // heuristic — which needs the record to name the pay-out address as its destination.
        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSwapHash",
            isOutgoing: false,
            sources: ["0xExecutor"],
            destinations: [(ExpressMergeTestDataFactory.ownerAddress, receivedAmount)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(12),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waitingTxHash,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xRouter",
            payInHash: nil,
            payOutAddress: ExpressMergeTestDataFactory.ownerAddress,
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 374,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: receivedAmount,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(output.count == 1)
        #expect(record(in: output, hash: "0xSwapHash")?.exchangeInfo?.transaction.txId == "exchange-tx")
    }

    @Test("Receive heuristic: matches the pay-out leg even when the record doesn't name the pay-out address")
    func receiveHeuristicMatchesWhenPayOutAddressIsMissingFromTheRecord() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )
        let receivedAmount = try #require(Decimal(stringValue: "28.432395"))

        // The record carries the token contract instead of the counterparty as its destination, which is what
        // some providers report for a token transfer made by a contract call.
        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSwapHash",
            isOutgoing: false,
            sources: ["0xExecutor"],
            destinations: [("0xTokenContract", receivedAmount)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(12),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waitingTxHash,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xRouter",
            payInHash: nil,
            payOutAddress: ExpressMergeTestDataFactory.ownerAddress,
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 374,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: receivedAmount,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        // No synthetic record next to an unenriched on-chain one
        #expect(output.count == 1)
        #expect(record(in: output, hash: "0xSwapHash")?.exchangeInfo?.transaction.txId == "exchange-tx")
    }

    @Test("Receive heuristic: an unrelated incoming transfer outside the window is not claimed as the pay-out leg")
    func receiveHeuristicDoesNotClaimUnrelatedTransferWithoutPayOutAddress() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )
        let receivedAmount = try #require(Decimal(stringValue: "28.432395"))

        // Same shape as above, but the transfer arrived a day and an hour after the deal was created.
        let onChain = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xUnrelated",
            isOutgoing: false,
            sources: ["0xExecutor"],
            destinations: [("0xTokenContract", receivedAmount)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(ExpressMergeTestDataFactory.dayInSeconds + 3600),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waitingTxHash,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xRouter",
            payInHash: nil,
            payOutAddress: ExpressMergeTestDataFactory.ownerAddress,
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 374,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: receivedAmount,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [onChain], exchangeTransactions: [exchange], onrampTransactions: [])

        #expect(record(in: output, hash: "0xUnrelated")?.isEnriched == false)
        #expect(record(in: output, hash: "ExpressSyntheticTx_exchange-tx")?.exchangeInfo != nil)
    }

    @Test("Exchange: a hash the deal named itself stays claimed even when no amount lines up")
    func exchangeClaimsDeterministicallyMatchedHashWithMismatchingAmounts() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )

        // Neither transfer carries the reported amount and the two don't add up to it either, which is not
        // enough to reject a hash the deal itself pointed at
        let firstTransfer = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xPayInHash",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPayIn", 20)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let secondTransfer = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xPayInHash",
            isOutgoing: true,
            sources: [ExpressMergeTestDataFactory.ownerAddress],
            destinations: [("0xPoolB", 30)],
            date: ExpressMergeTestDataFactory.baseDate,
            index: 1,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xPayIn",
            payInHash: "0xPayInHash",
            payOutAddress: ExpressMergeTestDataFactory.ownerAddress,
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 100,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(bsdkTransactions: [firstTransfer, secondTransfer], exchangeTransactions: [exchange], onrampTransactions: [])

        // Both records are enriched instead of being shown as plain transfers next to a synthetic swap row
        #expect(output.count == 2)
        #expect(output.allSatisfy { $0.exchangeInfo?.transaction.txId == "exchange-tx" })
    }

    @Test("Receive heuristic: matches the pay-out leg even when other records occupy the pay-out address")
    func receiveHeuristicMatchesWhenPayOutAddressIndexHoldsOtherRecords() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: token
        )
        let receivedAmount = try #require(Decimal(stringValue: "47.881127"))

        // The pay-out leg carries the token contract as its destination, so it is missing from the address
        // index — which still exists, because an ordinary transfer did land on the pay-out address.
        let ordinaryTransfer = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xOrdinary",
            isOutgoing: false,
            sources: ["0xSomeone"],
            destinations: [(ExpressMergeTestDataFactory.ownerAddress, 5)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(60),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let payOutLeg = ExpressMergeTestDataFactory.bsdkTransaction(
            hash: "0xSwapHash",
            isOutgoing: false,
            sources: ["0xExecutor"],
            destinations: [("0xTokenContract", receivedAmount)],
            date: ExpressMergeTestDataFactory.baseDate.addingTimeInterval(12),
            index: 0,
            nonce: nil,
            status: .confirmed,
            feeToken: token
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .finished,
            fromAddress: ExpressMergeTestDataFactory.ownerAddress,
            payInAddress: "0xRouter",
            payInHash: nil,
            payOutAddress: ExpressMergeTestDataFactory.ownerAddress,
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 374,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: receivedAmount,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let output = merger.merge(
            bsdkTransactions: [ordinaryTransfer, payOutLeg],
            exchangeTransactions: [exchange],
            onrampTransactions: []
        )

        // The pay-out leg is enriched instead of being shown as an operation next to a synthetic swap row
        #expect(output.count == 2)
        #expect(record(in: output, hash: "0xSwapHash")?.exchangeInfo?.transaction.txId == "exchange-tx")
        #expect(record(in: output, hash: "0xOrdinary")?.isEnriched == false)
    }

    // MARK: - Helpers

    private func record(in output: [TransactionRecord], hash: String) -> TransactionRecord? {
        output.first { $0.hash == hash }
    }

    private func record(in output: [TransactionRecord], index: Int) -> TransactionRecord? {
        output.first { $0.index == index }
    }
}
