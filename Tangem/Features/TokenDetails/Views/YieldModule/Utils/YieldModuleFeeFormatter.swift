//
//  YieldModuleFeeFormatter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct YieldFormattedFee {
    let fiatFee: String
    let cryptoFee: String
}

enum YieldModuleFormatterFee: Error {
    case cannotFormatFee
}

struct YieldModuleFeeFormatter {
    private let feeCurrency: TokenItem
    private let token: TokenItem

    // MARK: - Dependencies

    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()

    // MARK: - Init

    init(feeCurrency: TokenItem, token: TokenItem) {
        self.feeCurrency = feeCurrency
        self.token = token
    }

    // MARK: - Public Implementation

    func convertToFiat(_ value: Decimal) async throws -> Decimal {
        guard let feeCurrencyId = feeCurrency.currencyId else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        return try await balanceConverter.convertToFiat(value, currencyId: feeCurrencyId)
    }

    func formatDecimal(_ value: Decimal) -> String {
        balanceFormatter.formatDecimal(value)
    }

    func createCurrentNetworkFeeString(networkFee: Decimal) -> String {
        balanceFormatter.formatFiatBalance(networkFee, currencyCode: AppConstants.usdCurrencyCode)
    }

    func makeFormattedMaximumFee(maxFeeNative: Decimal) async throws -> YieldFormattedFee {
        guard let feeCurrencyId = feeCurrency.currencyId, let tokenId = token.id else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        let coinToFiat = try await balanceConverter.convertToFiat(maxFeeNative, currencyId: feeCurrencyId)

        guard let fiatToToken = balanceConverter.convertFromFiat(coinToFiat, currencyId: tokenId) else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        let formattedFiatFee = balanceFormatter.formatFiatBalance(
            coinToFiat,
            currencyCode: AppConstants.usdCurrencyCode
        )

        let formattedCryptoFee = balanceFormatter.formatCryptoBalance(
            fiatToToken,
            currencyCode: token.currencySymbol
        )

        return YieldFormattedFee(fiatFee: formattedFiatFee, cryptoFee: formattedCryptoFee)
    }

    func makeFormattedMinimalFee(from minAmountInCrypto: Decimal) async throws -> YieldFormattedFee {
        guard let tokenCurrencyId = token.id else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        let minAmountInFiat = try await balanceConverter.convertToFiat(minAmountInCrypto, currencyId: tokenCurrencyId)
        let formattedCryptoAmount = balanceFormatter.formatCryptoBalance(minAmountInCrypto, currencyCode: token.currencySymbol)
        let formattedFiatAmount = balanceFormatter.formatFiatBalance(minAmountInFiat, currencyCode: AppConstants.usdCurrencyCode)

        return YieldFormattedFee(fiatFee: formattedFiatAmount, cryptoFee: formattedCryptoAmount)
    }

    func formatCryptoBalance(_ balance: Decimal, prefix: String? = nil) -> String {
        balanceFormatter.formatCryptoBalance(balance, currencyCode: (prefix ?? "") + token.currencySymbol)
    }

    func createFeeString(from networkFee: Decimal) async throws -> String {
        guard let id = feeCurrency.currencyId else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        let converted = try await balanceConverter.convertToFiat(networkFee, currencyId: id)
        let formattedFiatFee = balanceFormatter.formatFiatBalance(converted, currencyCode: AppConstants.usdCurrencyCode)
        return formattedFiatFee
    }

    // MARK: - Private Implementation

    private func convertFeeToToken(networkFee: Decimal) async throws -> (token: Decimal, fiat: Decimal) {
        guard let feeCurrencyId = feeCurrency.currencyId, let tokenId = token.id else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        let coinToFiat = try await balanceConverter.convertToFiat(networkFee, currencyId: feeCurrencyId)

        guard let fiatToToken = balanceConverter.convertFromFiat(coinToFiat, currencyId: tokenId) else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        return (fiatToToken, coinToFiat)
    }
}
