//
//  TransactionHistoryIndexInfoRecord.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

/// Aggregated type for joining different records from different tables.
/// See https://swiftpackageindex.com/groue/GRDB.swift/master/documentation/grdb/recordrecommendedpractices for details.
public struct TransactionHistoryIndexInfoRecord {
    public let indexRecord: TransactionHistoryIndexRecord
    public let exchangeTransaction: ExchangeRecords?
    public let onrampTransaction: OnrampRecords?

    public init(
        indexRecord: TransactionHistoryIndexRecord,
        exchangeTransaction: ExchangeRecords?,
        onrampTransaction: OnrampRecords?
    ) {
        self.indexRecord = indexRecord
        self.exchangeTransaction = exchangeTransaction
        self.onrampTransaction = onrampTransaction
    }
}

// MARK: - Fetching helpers

public extension TransactionHistoryIndexInfoRecord {
    /// - Note: `address` and `contractAddress` are stored normalized, so the caller must normalize them before filtering.
    static func query(address: String, network: String, contractAddress: String) -> QueryInterfaceRequest<Self> {
        TransactionHistoryIndexRecord
            .filter { $0.address == address && $0.network == network && $0.contract == contractAddress }
            .order { [$0.dateTime.desc, $0.entityID.desc] }
            .including(optional: TransactionHistoryIndexRecord
                .expressEntity
                .forKey(CodingKeys.exchangeTransaction)
                .including(optional: ExpressExchangeTransactionRecord
                    .provider
                    .forKey(ExchangeRecords.CodingKeys.provider))
                .including(optional: ExpressExchangeTransactionRecord
                    .fromCryptoCurrency
                    .forKey(ExchangeRecords.CodingKeys.fromCryptoCurrency))
                .including(optional: ExpressExchangeTransactionRecord
                    .toCryptoCurrency
                    .forKey(ExchangeRecords.CodingKeys.toCryptoCurrency))
                .including(optional: ExpressExchangeTransactionRecord
                    .refundCryptoCurrency
                    .forKey(ExchangeRecords.CodingKeys.refundCryptoCurrency))
            )
            .including(optional: TransactionHistoryIndexRecord
                .onrampEntity
                .forKey(CodingKeys.onrampTransaction)
                .including(optional: ExpressOnrampTransactionRecord
                    .provider
                    .forKey(OnrampRecords.CodingKeys.provider))
                .including(optional: ExpressOnrampTransactionRecord
                    .fiatCurrency
                    .forKey(OnrampRecords.CodingKeys.fiatCurrency))
                .including(optional: ExpressOnrampTransactionRecord
                    .cryptoCurrency
                    .forKey(OnrampRecords.CodingKeys.cryptoCurrency))
            )
            .asRequest(of: Self.self)
    }
}

// MARK: - Auxiliary types

public extension TransactionHistoryIndexInfoRecord {
    struct ExchangeRecords {
        public let transaction: ExpressExchangeTransactionRecord
        public let provider: ExpressProviderRecord?
        public let fromCryptoCurrency: CryptoCurrencyRecord?
        public let toCryptoCurrency: CryptoCurrencyRecord?
        public let refundCryptoCurrency: CryptoCurrencyRecord?

        public init(
            transaction: ExpressExchangeTransactionRecord,
            provider: ExpressProviderRecord?,
            fromCryptoCurrency: CryptoCurrencyRecord?,
            toCryptoCurrency: CryptoCurrencyRecord?,
            refundCryptoCurrency: CryptoCurrencyRecord?
        ) {
            self.transaction = transaction
            self.provider = provider
            self.fromCryptoCurrency = fromCryptoCurrency
            self.toCryptoCurrency = toCryptoCurrency
            self.refundCryptoCurrency = refundCryptoCurrency
        }

        /// Swift compiler automatically synthesizes CodingKeys enum with `private` access level,
        /// so we need to explicitly declare it to make it accessible outside of this type.
        enum CodingKeys: String, CodingKey {
            case transaction
            case provider
            case fromCryptoCurrency
            case toCryptoCurrency
            case refundCryptoCurrency
        }
    }

    struct OnrampRecords {
        public let transaction: ExpressOnrampTransactionRecord
        public let provider: ExpressProviderRecord?
        public let fiatCurrency: FiatCurrencyRecord?
        public let cryptoCurrency: CryptoCurrencyRecord?

        public init(
            transaction: ExpressOnrampTransactionRecord,
            provider: ExpressProviderRecord?,
            fiatCurrency: FiatCurrencyRecord?,
            cryptoCurrency: CryptoCurrencyRecord?
        ) {
            self.transaction = transaction
            self.provider = provider
            self.fiatCurrency = fiatCurrency
            self.cryptoCurrency = cryptoCurrency
        }

        /// Swift compiler automatically synthesizes CodingKeys enum with `private` access level,
        /// so we need to explicitly declare it to make it accessible outside of this type.
        enum CodingKeys: String, CodingKey {
            case transaction
            case provider
            case fiatCurrency
            case cryptoCurrency
        }
    }
}

// MARK: - Decodable protocol conformance

extension TransactionHistoryIndexInfoRecord: Decodable {}

extension TransactionHistoryIndexInfoRecord.ExchangeRecords: Decodable {}

extension TransactionHistoryIndexInfoRecord.OnrampRecords: Decodable {}

// MARK: - FetchableRecord protocol conformance

extension TransactionHistoryIndexInfoRecord: FetchableRecord {}

extension TransactionHistoryIndexInfoRecord.ExchangeRecords: FetchableRecord {}

extension TransactionHistoryIndexInfoRecord.OnrampRecords: FetchableRecord {}
