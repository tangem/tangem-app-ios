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

    func exchangeHistory(
        walletAddress: String,
        cursor: Any?,
        limit: Int?,
        network: String?,
        tokenId: String?
    ) async throws -> ExchangeHistoryPage

    func onrampHistory(
        walletAddress: String,
        cursor: Any?,
        limit: Int?,
        network: String?,
        tokenId: String?
    ) async throws -> OnrampHistoryPage
}

// MARK: - Convenience extensions

public extension ExpressAPIProvider {
    func exchangeHistory(walletAddress: String, cursor: Any?, limit: Int?) async throws -> ExchangeHistoryPage {
        try await exchangeHistory(
            walletAddress: walletAddress,
            cursor: cursor,
            limit: limit,
            network: nil,
            tokenId: nil
        )
    }

    func onrampHistory(walletAddress: String, cursor: Any?, limit: Int?) async throws -> OnrampHistoryPage {
        try await onrampHistory(
            walletAddress: walletAddress,
            cursor: cursor,
            limit: limit,
            network: nil,
            tokenId: nil
        )
    }
}
