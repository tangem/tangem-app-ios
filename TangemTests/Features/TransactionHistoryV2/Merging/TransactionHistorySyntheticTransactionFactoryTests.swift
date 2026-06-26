//
//  TransactionHistorySyntheticTransactionFactoryTests.swift
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

@Suite("TransactionHistorySyntheticTransactionFactory")
struct TransactionHistorySyntheticTransactionFactoryTests {
    // MARK: - Exchange direction resolution

    @Test("Exchange: when the owner is the from-address it is treated as an outgoing pay-in leg")
    func exchangeOutgoingLeg() throws {
        let token = F.ethereumToken
        let factory = F.makeFactory(currentToken: token, ownerAddress: "0xOwner")

        let exchange = F.exchangeTransaction(
            txId: "tx-1",
            status: .waiting,
            fromAddress: "0xOwner",
            payInAddress: "0xPayIn",
            payInHash: "0xPayInHash",
            payOutAddress: "0xPayOut",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("2"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        let record = factory.makeSyntheticTransaction(from: exchange)

        #expect(record.isOutgoing)
        #expect(record.singleSourceAddress == "0xOwner")
        #expect(record.singleDestinationAddress == "0xPayIn")
        #expect(record.singleDestinationAmount == F.dec("2"))
        #expect(record.hash == "0xPayInHash")
        #expect(record.type == .contractMethodName(name: "swap"))
        #expect(record.date == F.baseDate)
        #expect(record.index == 0)
        #expect(record.nonce == nil)
        #expect(record.tokenTransfers.isEmpty)
        #expect(record.fee.amount.value == 0)
        #expect(record.exchangeInfo?.transaction.txId == "tx-1")
    }

    @Test("Exchange: when the owner is the pay-out address it is treated as an incoming pay-out leg")
    func exchangeIncomingLeg() throws {
        let token = F.ethereumToken
        let factory = F.makeFactory(currentToken: token, ownerAddress: "0xPayOut")

        let exchange = F.exchangeTransaction(
            txId: "tx-2",
            status: .sending,
            fromAddress: "0xSender",
            payOutAddress: "0xPayOut",
            payOutHash: "0xPayOutHash",
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("1"),
            toCurrency: F.matchingCurrency(for: token),
            toAmount: F.dec("3")
        )

        let record = factory.makeSyntheticTransaction(from: exchange)

        #expect(!record.isOutgoing)
        // The source address of the pay-out leg is unknown at this point.
        #expect(record.singleSourceAddress == String.unknown)
        #expect(record.singleDestinationAddress == "0xPayOut")
        #expect(record.singleDestinationAmount == F.dec("3"))
        #expect(record.hash == "0xPayOutHash")
        #expect(record.exchangeInfo != nil)
    }

    @Test("Exchange: with the owner on neither leg, direction falls back to the current token's currency")
    func exchangeAmbiguousDirectionResolvedByCurrency() {
        let token = F.ethereumToken
        let factory = F.makeFactory(currentToken: token, ownerAddress: "0xOwner")

        let outgoing = F.exchangeTransaction(
            status: .waiting,
            fromAddress: "0xA",
            payOutAddress: "0xB",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )
        let incoming = F.exchangeTransaction(
            status: .waiting,
            fromAddress: "0xA",
            payOutAddress: "0xB",
            fromCurrency: F.unrelatedCurrency,
            fromAmount: F.dec("1"),
            toCurrency: F.matchingCurrency(for: token),
            toAmount: F.dec("1")
        )

        // The current token is on the `from` side -> outgoing; otherwise -> incoming.
        #expect(factory.makeSyntheticTransaction(from: outgoing).isOutgoing)
        #expect(!factory.makeSyntheticTransaction(from: incoming).isOutgoing)
    }

    @Test("Exchange: a self-swap (owner on both legs) also resolves direction by currency")
    func exchangeSelfSwapResolvedByCurrency() {
        let token = F.ethereumToken
        let factory = F.makeFactory(currentToken: token, ownerAddress: "0xOwner")

        let selfSwap = F.exchangeTransaction(
            status: .waiting,
            fromAddress: "0xOwner",
            payOutAddress: "0xOwner",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        #expect(factory.makeSyntheticTransaction(from: selfSwap).isOutgoing)
    }

    // MARK: - Exchange field mapping

    @Test("Exchange: the actual amount is preferred over the expected amount when present")
    func exchangePrefersActualAmount() {
        let token = F.ethereumToken
        let factory = F.makeFactory(currentToken: token, ownerAddress: "0xOwner")

        let exchange = F.exchangeTransaction(
            status: .waiting,
            fromAddress: "0xOwner",
            payInAddress: "0xPayIn",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("2"),
            fromActualAmount: F.dec("1.5"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        #expect(factory.makeSyntheticTransaction(from: exchange).singleDestinationAmount == F.dec("1.5"))
    }

    @Test("Exchange: the hash falls back to the txId when the leg hash is absent")
    func exchangeHashFallsBackToTxId() {
        let token = F.ethereumToken
        let factory = F.makeFactory(currentToken: token, ownerAddress: "0xOwner")

        let exchange = F.exchangeTransaction(
            txId: "tx-fallback",
            status: .waiting,
            fromAddress: "0xOwner",
            payInHash: nil,
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        #expect(factory.makeSyntheticTransaction(from: exchange).hash == "tx-fallback")
    }

    // MARK: - Exchange status mapping

    @Test("Exchange: status is mapped to the synthetic record status", arguments: [
        (ExpressTransactionStatus.finished, TransactionRecord.TransactionStatus.confirmed),
        (.refunded, .confirmed),
        (.failed, .failed),
        (.txFailed, .failed),
        (.unknown, .unconfirmed),
        (.preview, .unconfirmed),
        (.created, .unconfirmed),
        (.exchangeTxSent, .unconfirmed),
        (.waiting, .unconfirmed),
        (.waitingTxHash, .unconfirmed),
        (.expired, .unconfirmed),
        (.confirming, .unconfirmed),
        (.exchanging, .unconfirmed),
        (.sending, .unconfirmed),
        (.verifying, .unconfirmed),
    ])
    func exchangeStatusMapping(_ testCase: (ExpressTransactionStatus, TransactionRecord.TransactionStatus)) {
        let token = F.ethereumToken
        let factory = F.makeFactory(currentToken: token, ownerAddress: "0xOwner")

        let exchange = F.exchangeTransaction(
            status: testCase.0,
            fromAddress: "0xOwner",
            fromCurrency: F.matchingCurrency(for: token),
            fromAmount: F.dec("1"),
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        #expect(factory.makeSyntheticTransaction(from: exchange).status == testCase.1)
    }

    // MARK: - Onramp field mapping

    @Test("Onramp: a synthetic record is always incoming and maps the pay-out leg")
    func onrampMapsIncomingPayOutLeg() throws {
        let token = F.ethereumToken
        let factory = F.makeFactory(currentToken: token, ownerAddress: "0xOwner")

        let onramp = F.onrampTransaction(
            txId: "on-1",
            status: .sending,
            payOutAddress: "0xPayOut",
            payOutHash: "0xOnHash",
            toCurrency: F.matchingCurrency(for: token),
            toAmount: F.dec("0.7")
        )

        let record = factory.makeSyntheticTransaction(from: onramp)

        #expect(!record.isOutgoing)
        #expect(record.singleSourceAddress == String.unknown)
        #expect(record.singleDestinationAddress == "0xPayOut")
        #expect(record.singleDestinationAmount == F.dec("0.7"))
        #expect(record.hash == "0xOnHash")
        #expect(record.type == .contractMethodName(name: "onramp"))
        #expect(record.date == F.baseDate)
        #expect(record.index == 0)
        #expect(record.nonce == nil)
        #expect(record.tokenTransfers.isEmpty)
        #expect(record.fee.amount.value == 0)
        #expect(record.onrampInfo != nil)
    }

    @Test("Onramp: the amount falls back to zero when neither actual nor expected amount is present")
    func onrampAmountFallsBackToZero() {
        let factory = F.makeFactory()

        let onramp = F.onrampTransaction(
            status: .waitingForPayment,
            toCurrency: F.unrelatedCurrency,
            toAmount: nil,
            toActualAmount: nil
        )

        #expect(factory.makeSyntheticTransaction(from: onramp).singleDestinationAmount == 0)
    }

    @Test("Onramp: the actual amount is preferred over the expected amount when present")
    func onrampPrefersActualAmount() {
        let factory = F.makeFactory()

        let onramp = F.onrampTransaction(
            status: .paid,
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("0.5"),
            toActualAmount: F.dec("0.55")
        )

        #expect(factory.makeSyntheticTransaction(from: onramp).singleDestinationAmount == F.dec("0.55"))
    }

    @Test("Onramp: the hash falls back to the txId when the pay-out hash is absent")
    func onrampHashFallsBackToTxId() {
        let factory = F.makeFactory()

        let onramp = F.onrampTransaction(
            txId: "on-fallback",
            status: .paid,
            payOutHash: nil,
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        #expect(factory.makeSyntheticTransaction(from: onramp).hash == "on-fallback")
    }

    // MARK: - Onramp status mapping

    @Test("Onramp: status is mapped to the synthetic record status", arguments: [
        (OnrampTransactionStatus.finished, TransactionRecord.TransactionStatus.confirmed),
        (.failed, .failed),
        (.unknown, .unconfirmed),
        (.created, .unconfirmed),
        (.expired, .unconfirmed),
        (.waitingForPayment, .unconfirmed),
        (.paymentProcessing, .unconfirmed),
        (.verifying, .unconfirmed),
        (.paid, .unconfirmed),
        (.sending, .unconfirmed),
        (.paused, .unconfirmed),
    ])
    func onrampStatusMapping(_ testCase: (OnrampTransactionStatus, TransactionRecord.TransactionStatus)) {
        let factory = F.makeFactory()

        let onramp = F.onrampTransaction(
            status: testCase.0,
            toCurrency: F.unrelatedCurrency,
            toAmount: F.dec("1")
        )

        #expect(factory.makeSyntheticTransaction(from: onramp).status == testCase.1)
    }
}
