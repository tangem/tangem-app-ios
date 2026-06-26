//
//  ExpressMergeTestFixtures.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

/// Shared builders for the Express transaction-history merging tests.
///
/// The expected behavior modeled here follows the Express sync & merge spec:
/// https://app.notion.com/p/tangem/Express-36d5d34eb67880fa8082dcdb732c4364
enum ExpressMergeTestFixtures {
    static let ownerAddress = "0xOwner"
    static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    static let dayInSeconds: TimeInterval = 60 * 60 * 24

    // MARK: - Tokens

    static var ethereumToken: TokenItem {
        .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    }

    static var bitcoinToken: TokenItem {
        .blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))
    }

    // MARK: - Currencies

    /// The `ExpressCurrency` that equals `token`'s express currency, so the currency-gated matchers fire.
    static func matchingCurrency(for token: TokenItem) -> ExpressCurrency {
        token.expressCurrency.asCurrency
    }

    static let unrelatedCurrency = ExpressCurrency(contractAddress: "0xUnrelated", network: "unrelated-network")

    // MARK: - Dates

    static func date(offset: TimeInterval) -> Date {
        baseDate.addingTimeInterval(offset)
    }

    // MARK: - Decimal

    static func dec(_ string: String) -> Decimal {
        Decimal(stringValue: string)!
    }

    // MARK: - Merger

    static func makeMerger(
        currentToken: TokenItem = Self.ethereumToken,
        ownerAddress: String = Self.ownerAddress,
        feeTokenItem: TokenItem? = nil
    ) -> TransactionHistoryExpressDataMerger {
        TransactionHistoryExpressDataMerger(
            ownerAddress: ownerAddress,
            currentToken: currentToken,
            feeTokenItem: feeTokenItem ?? currentToken
        )
    }

    static func makeFactory(
        currentToken: TokenItem = Self.ethereumToken,
        ownerAddress: String = Self.ownerAddress,
        feeTokenItem: TokenItem? = nil
    ) -> TransactionHistorySyntheticTransactionFactory {
        TransactionHistorySyntheticTransactionFactory(
            ownerAddress: ownerAddress,
            currentToken: currentToken,
            feeTokenItem: feeTokenItem ?? currentToken
        )
    }

    // MARK: - On-chain (BSDK) transaction

    static func bsdkTransaction(
        hash: String,
        isOutgoing: Bool,
        sources: [String],
        destinations: [(address: String, amount: Decimal)],
        date: Date?,
        nonce: Int? = nil,
        status: TransactionRecord.TransactionStatus = .confirmed,
        feeToken: TokenItem = Self.ethereumToken
    ) -> TransactionRecord {
        TransactionRecord(
            hash: hash,
            index: 0,
            source: .multiple(sources.map { TransactionRecord.Source(address: $0, amount: 0) }),
            destination: .multiple(destinations.map { TransactionRecord.Destination(address: .user($0.address), amount: $0.amount) }),
            fee: feeToken.zeroFee,
            status: status,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: date,
            tokenTransfers: [],
            nonce: nonce
        )
    }

    // MARK: - Exchange (swap) transaction

    static func exchangeTransaction(
        txId: String = "exchange-tx",
        status: ExpressTransactionStatus,
        fromAddress: String? = Self.ownerAddress,
        payInAddress: String = "0xPayIn",
        payInHash: String? = nil,
        payOutAddress: String = "0xPayOut",
        payOutHash: String? = nil,
        fromCurrency: ExpressCurrency,
        fromAmount: Decimal,
        fromActualAmount: Decimal? = nil,
        toCurrency: ExpressCurrency,
        toAmount: Decimal,
        toActualAmount: Decimal? = nil,
        refund: RefundInfo? = nil,
        createdAt: Date = Self.baseDate,
        updatedAt: Date = Self.baseDate
    ) -> ExchangeTransaction {
        ExchangeTransaction(
            txId: txId,
            providerId: "test-provider",
            status: status,
            rateType: nil,
            externalTx: nil,
            fromAddress: fromAddress,
            payIn: PayInInfo(address: payInAddress, extraId: nil, hash: payInHash),
            payOut: PayOutInfo(address: payOutAddress, hash: payOutHash),
            refund: refund,
            from: ExpressHistoryAsset(currency: fromCurrency, amount: fromAmount, actualAmount: fromActualAmount, decimals: 18),
            to: ExpressHistoryAsset(currency: toCurrency, amount: toAmount, actualAmount: toActualAmount, decimals: 18),
            createdAt: createdAt,
            updatedAt: updatedAt,
            payTill: nil,
            averageDuration: nil
        )
    }

    static func refundInfo(currency: ExpressCurrency, address: String = "0xRefund") -> RefundInfo {
        RefundInfo(address: address, extraId: nil, currency: currency)
    }

    // MARK: - Onramp transaction

    static func onrampTransaction(
        txId: String = "onramp-tx",
        status: OnrampTransactionStatus,
        payOutAddress: String = "0xPayOut",
        payOutHash: String? = nil,
        toCurrency: ExpressCurrency,
        toAmount: Decimal?,
        toActualAmount: Decimal? = nil,
        createdAt: Date = Self.baseDate,
        updatedAt: Date = Self.baseDate
    ) -> OnrampTransaction {
        OnrampTransaction(
            txId: txId,
            providerId: "test-provider",
            status: status,
            failReason: nil,
            externalTx: nil,
            payOut: PayOutInfo(address: payOutAddress, hash: payOutHash),
            from: OnrampHistoryFiatAsset(currencyCode: "EUR", amount: dec("100")),
            to: OnrampHistoryCryptoAsset(currency: toCurrency, amount: toAmount, actualAmount: toActualAmount, decimals: 18),
            paymentMethod: "card",
            countryCode: "DE",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - TransactionRecord enrichment helpers

extension TransactionRecord {
    var isEnriched: Bool {
        extraInfo != nil
    }

    var exchangeInfo: ExchangeTransactionInfo? {
        if case .exchange(let info) = extraInfo {
            return info
        }

        return nil
    }

    var onrampInfo: OnrampTransactionInfo? {
        if case .onramp(let info) = extraInfo {
            return info
        }

        return nil
    }

    var singleDestinationAddress: String? {
        let destinations = destination.destinations
        guard destinations.count == 1 else {
            return nil
        }

        return destinations[0].address.string
    }

    var singleSourceAddress: String? {
        let sources = source.sources
        guard sources.count == 1 else {
            return nil
        }

        return sources[0].address
    }

    var singleDestinationAmount: Decimal? {
        let destinations = destination.destinations
        guard destinations.count == 1 else {
            return nil
        }

        return destinations[0].amount
    }
}
