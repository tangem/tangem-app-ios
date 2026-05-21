//
//  ExpressAPIProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressAPIProvider {
    /// Requests from Express API `exchangeAvailable` state for currencies included in filter
    /// - Returns: All `ExpressCurrency` that available to exchange specified by filter
    func assets(currencies: Set<ExpressWalletCurrency>) async throws -> [ExpressAsset]
    func pairs(from: Set<ExpressWalletCurrency>, to: Set<ExpressWalletCurrency>) async throws -> [ExpressPair]

    func providers(branch: ExpressBranch) async throws -> [ExpressProvider]
    func exchangeQuote(item: ExpressSwappableQuoteItem) async throws -> ExpressQuote
    func exchangeData(item: ExpressSwappableDataItem) async throws -> ExpressTransactionData
    func exchangeStatus(transactionId: String) async throws -> ExpressTransaction
    func exchangeSent(result: ExpressTransactionSentResult) async throws

    func onrampCurrencies() async throws -> [OnrampFiatCurrency]
    func onrampCountries() async throws -> [OnrampCountry]
    func onrampCountryByIP() async throws -> OnrampCountry
    func onrampPaymentMethods() async throws -> [OnrampPaymentMethod]
    func onrampPairs(from: OnrampFiatCurrency, to: [ExpressWalletCurrency], country: OnrampCountry) async throws -> [OnrampPair]
    func onrampQuote(item: OnrampQuotesRequestItem) async throws -> OnrampQuote
    func onrampData(item: OnrampRedirectDataRequestItem) async throws -> OnrampRedirectData
    func onrampNativePaymentData(item: OnrampNativePaymentRequestItem) async throws -> OnrampDataResult
    func onrampStatus(transactionId: String) async throws -> OnrampTransaction

    /// Fetches a delta page of swap-history records for `walletAddress`. Pass `nil` `cursor` for an
    /// initial sync; pass the previously persisted opaque cursor otherwise. `network` and `tokenId`
    /// scope the result to a specific asset (foreground-sync only) — non-foreground callers should
    /// use the 3-arg convenience overload below.
    func exchangeHistory(
        walletAddress: String,
        cursor: String?,
        limit: Int?,
        network: String?,
        tokenId: String?
    ) async throws -> ExchangeHistoryPage

    /// Fetches a delta page of onramp-history records for `walletAddress`. Pagination/filter contract
    /// mirrors `exchangeHistory(walletAddress:cursor:limit:network:tokenId:)`.
    func onrampHistory(
        walletAddress: String,
        cursor: String?,
        limit: Int?,
        network: String?,
        tokenId: String?
    ) async throws -> OnrampHistoryPage
}

// MARK: - Convenience overloads

/// Most callers (initial sync, delta sync, post-broadcast sync, pagination) don't scope to a specific
/// asset — only foreground sync from an asset detail screen passes `network`/`tokenId`. These 3-arg
/// overloads keep those common call sites tidy. Default-value syntax on the protocol method itself
/// isn't supported in Swift, hence the explicit extension.
public extension ExpressAPIProvider {
    func exchangeHistory(walletAddress: String, cursor: String?, limit: Int?) async throws -> ExchangeHistoryPage {
        try await exchangeHistory(
            walletAddress: walletAddress,
            cursor: cursor,
            limit: limit,
            network: nil,
            tokenId: nil
        )
    }

    func onrampHistory(walletAddress: String, cursor: String?, limit: Int?) async throws -> OnrampHistoryPage {
        try await onrampHistory(
            walletAddress: walletAddress,
            cursor: cursor,
            limit: limit,
            network: nil,
            tokenId: nil
        )
    }
}
