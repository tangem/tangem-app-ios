//
//  TransactionHistorySyntheticTransactionFactoryTests.swift
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

@Suite("TransactionHistorySyntheticTransactionFactory")
struct TransactionHistorySyntheticTransactionFactoryTests {
    // MARK: - Exchange direction resolution

    @Test("Exchange: when the owner is the from-address it is treated as an outgoing pay-in leg")
    func exchangeOutgoingLeg() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: token,
            ownerAddress: "0xOwner",
            feeTokenItem: token
        )

        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "tx-1",
            status: .waiting,
            fromAddress: "0xOwner",
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

        let record = factory.makeSyntheticTransaction(from: exchange)

        #expect(record.isOutgoing)
        #expect(record.singleSourceAddress == "0xOwner")
        #expect(record.singleDestinationAddress == "0xPayIn")
        #expect(record.singleDestinationAmount == 2)
        #expect(record.hash == "0xPayInHash")
        #expect(record.type == .contractMethodName(name: "swap"))
        #expect(record.date == ExpressMergeTestDataFactory.baseDate)
        #expect(record.index == 0)
        #expect(record.nonce == nil)
        #expect(record.tokenTransfers.isEmpty)
        #expect(record.fee.amount.value == 0)
        #expect(record.exchangeInfo?.transaction.txId == "tx-1")
    }

    @Test("Exchange: when the owner is the pay-out address it is treated as an incoming pay-out leg")
    func exchangeIncomingLeg() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: token,
            ownerAddress: "0xPayOut",
            feeTokenItem: token
        )

        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "tx-2",
            status: .sending,
            fromAddress: "0xSender",
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: "0xPayOutHash",
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 3,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let record = factory.makeSyntheticTransaction(from: exchange)

        #expect(!record.isOutgoing)
        // The source address of the pay-out leg is unknown at this point.
        #expect(record.singleSourceAddress == String.unknown)
        #expect(record.singleDestinationAddress == "0xPayOut")
        #expect(record.singleDestinationAmount == 3)
        #expect(record.hash == "0xPayOutHash")
        #expect(record.exchangeInfo != nil)
    }

    @Test("Exchange: with the owner on neither leg, direction falls back to the current token's currency")
    func exchangeAmbiguousDirectionResolvedByCurrency() {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: token,
            ownerAddress: "0xOwner",
            feeTokenItem: token
        )

        let outgoing = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waiting,
            fromAddress: "0xA",
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xB",
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
        let incoming = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waiting,
            fromAddress: "0xA",
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xB",
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

        // The current token is on the `from` side -> outgoing; otherwise -> incoming.
        #expect(factory.makeSyntheticTransaction(from: outgoing).isOutgoing)
        #expect(!factory.makeSyntheticTransaction(from: incoming).isOutgoing)
    }

    @Test("Exchange: a self-swap (owner on both legs) also resolves direction by currency")
    func exchangeSelfSwapResolvedByCurrency() {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: token,
            ownerAddress: "0xOwner",
            feeTokenItem: token
        )

        let selfSwap = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waiting,
            fromAddress: "0xOwner",
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xOwner",
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

        #expect(factory.makeSyntheticTransaction(from: selfSwap).isOutgoing)
    }

    // MARK: - Exchange field mapping

    @Test("Exchange: the actual amount is preferred over the expected amount when present")
    func exchangePrefersActualAmount() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: token,
            ownerAddress: "0xOwner",
            feeTokenItem: token
        )
        let targetAmount = try #require(Decimal(stringValue: "1.5"))

        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waiting,
            fromAddress: "0xOwner",
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 2,
            fromActualAmount: targetAmount,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        #expect(factory.makeSyntheticTransaction(from: exchange).singleDestinationAmount == targetAmount)
    }

    @Test("Exchange: the hash falls back to the txId when the leg hash is absent")
    func exchangeHashFallsBackToTxId() {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: token,
            ownerAddress: "0xOwner",
            feeTokenItem: token
        )

        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "tx-fallback",
            status: .waiting,
            fromAddress: "0xOwner",
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

        #expect(factory.makeSyntheticTransaction(from: exchange).hash == "tx-fallback")
    }

    @Test("Exchange (outgoing): a nil from-address falls back to the owner address as the source")
    func exchangeOutgoingLegFallsBackToOwnerAddressWhenFromAddressNil() {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: token,
            ownerAddress: "0xOwner",
            feeTokenItem: token
        )

        // Owner is on neither leg by address, and the current token is the `from` currency,
        // so direction resolves to outgoing and the source falls back to the owner address.
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .waiting,
            fromAddress: nil,
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

        let record = factory.makeSyntheticTransaction(from: exchange)

        #expect(record.isOutgoing)
        #expect(record.singleSourceAddress == "0xOwner")
    }

    @Test("Exchange (incoming): the actual amount is preferred over the expected amount when present")
    func exchangeIncomingLegPrefersActualAmount() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: token,
            ownerAddress: "0xPayOut",
            feeTokenItem: token
        )
        let targetAmount = try #require(Decimal(stringValue: "2.5"))

        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: .sending,
            fromAddress: "0xSender",
            payInAddress: "0xPayIn",
            payInHash: nil,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 2,
            toActualAmount: targetAmount,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let record = factory.makeSyntheticTransaction(from: exchange)

        #expect(!record.isOutgoing)
        #expect(record.singleDestinationAmount == targetAmount)
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
        (.paused, .unconfirmed),
    ])
    func exchangeStatusMapping(_ testCase: (ExpressTransactionStatus, TransactionRecord.TransactionStatus)) {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: token,
            ownerAddress: "0xOwner",
            feeTokenItem: token
        )

        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "exchange-tx",
            status: testCase.0,
            fromAddress: "0xOwner",
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

        #expect(factory.makeSyntheticTransaction(from: exchange).status == testCase.1)
    }

    // MARK: - Onramp field mapping

    @Test("Onramp: a synthetic record is always incoming and maps the pay-out leg")
    func onrampMapsIncomingPayOutLeg() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: token,
            ownerAddress: "0xOwner",
            feeTokenItem: token
        )
        let targetAmount = try #require(Decimal(stringValue: "0.7"))

        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "on-1",
            status: .sending,
            payOutAddress: "0xPayOut",
            payOutHash: "0xOnHash",
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: targetAmount,
            toActualAmount: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let record = factory.makeSyntheticTransaction(from: onramp)

        #expect(!record.isOutgoing)
        #expect(record.singleSourceAddress == String.unknown)
        #expect(record.singleDestinationAddress == "0xPayOut")
        #expect(record.singleDestinationAmount == targetAmount)
        #expect(record.hash == "0xOnHash")
        #expect(record.type == .contractMethodName(name: "onramp"))
        #expect(record.date == ExpressMergeTestDataFactory.baseDate)
        #expect(record.index == 0)
        #expect(record.nonce == nil)
        #expect(record.tokenTransfers.isEmpty)
        #expect(record.fee.amount.value == 0)
        #expect(record.onrampInfo != nil)
    }

    @Test("Onramp: the amount falls back to zero when neither actual nor expected amount is present")
    func onrampAmountFallsBackToZero() {
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "onramp-tx",
            status: .waitingForPayment,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: nil,
            toActualAmount: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        #expect(factory.makeSyntheticTransaction(from: onramp).singleDestinationAmount == 0)
    }

    @Test("Onramp: the actual amount is preferred over the expected amount when present")
    func onrampPrefersActualAmount() throws {
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )
        let toAmount = try #require(Decimal(stringValue: "0.5"))
        let targetAmount = try #require(Decimal(stringValue: "0.55"))

        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "onramp-tx",
            status: .paid,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: toAmount,
            toActualAmount: targetAmount,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        #expect(factory.makeSyntheticTransaction(from: onramp).singleDestinationAmount == targetAmount)
    }

    @Test("Onramp: the hash falls back to the txId when the pay-out hash is absent")
    func onrampHashFallsBackToTxId() {
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "on-fallback",
            status: .paid,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        #expect(factory.makeSyntheticTransaction(from: onramp).hash == "on-fallback")
    }

    // MARK: - Onramp status mapping

    @Test("Onramp: status is mapped to the synthetic record status", arguments: [
        (OnrampTransactionStatus.finished, TransactionRecord.TransactionStatus.confirmed),
        (.refunded, .confirmed),
        (.failed, .failed),
        (.unknown, .unconfirmed),
        (.created, .unconfirmed),
        (.expired, .unconfirmed),
        (.waitingForPayment, .unconfirmed),
        (.paymentProcessing, .unconfirmed),
        (.verifying, .unconfirmed),
        (.paid, .unconfirmed),
        (.sending, .unconfirmed),
        (.refunding, .unconfirmed),
        (.paused, .unconfirmed),
    ])
    func onrampStatusMapping(_ testCase: (OnrampTransactionStatus, TransactionRecord.TransactionStatus)) {
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: ExpressMergeTestDataFactory.ethereumToken,
            ownerAddress: ExpressMergeTestDataFactory.ownerAddress,
            feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
        )

        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "onramp-tx",
            status: testCase.0,
            payOutAddress: "0xPayOut",
            payOutHash: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        #expect(factory.makeSyntheticTransaction(from: onramp).status == testCase.1)
    }
}
