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

    func convertToFiat(_ value: Decimal, currency: CurrencyType) async throws -> Decimal {
        let currencyId = try currencyId(for: currency)
        return try await balanceConverter.convertToFiat(value, currencyId: currencyId)
    }

    func formatDecimal(_ value: Decimal) -> String {
        balanceFormatter.formatDecimal(value)
    }

    func makeFormattedMaximumFee(maxFeeNative: Decimal) async throws -> YieldFormattedFee {
        guard let feeCurrencyId = feeCurrency.currencyId, let tokenId = token.id else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        let coinToFiat = try await balanceConverter.convertToFiat(maxFeeNative, currencyId: feeCurrencyId)

        guard let fiatToToken = balanceConverter.convertToCryptoFrom(fiatValue: coinToFiat, currencyId: tokenId) else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        let selectedCurrencyCode = await AppSettings.shared.selectedCurrencyCode
        let formattedFiatFee = balanceFormatter.formatFiatBalance(
            coinToFiat,
            currencyCode: selectedCurrencyCode
        )

        let formattedCryptoFee = balanceFormatter.formatCryptoBalance(
            fiatToToken,
            currencyCode: token.currencySymbol
        )

        return YieldFormattedFee(fiatFee: formattedFiatFee, cryptoFee: formattedCryptoFee)
    }

    func makeFormattedMinimalFee(from minAmountInFiat: Decimal) async throws -> YieldFormattedFee {
        guard let tokenId = token.id,
              let minAmountInToken = balanceConverter.convertToCryptoFrom(fiatValue: minAmountInFiat, currencyId: tokenId)
        else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        let selectedCurrencyCode = await AppSettings.shared.selectedCurrencyCode
        let minAmountInFiatFormatted = balanceFormatter.formatFiatBalance(minAmountInFiat, currencyCode: selectedCurrencyCode)
        let minAmountInTokenFormatted = balanceFormatter.formatCryptoBalance(minAmountInToken, currencyCode: token.currencySymbol)

        return YieldFormattedFee(fiatFee: minAmountInFiatFormatted, cryptoFee: minAmountInTokenFormatted)
    }

    func formatCryptoBalance(_ balance: Decimal, prefix: String? = nil) -> String {
        balanceFormatter.formatCryptoBalance(balance, currencyCode: (prefix ?? "") + token.currencySymbol)
    }

    func createFeeString(from networkFee: Decimal) async throws -> String {
        guard let id = feeCurrency.currencyId else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        let selectedCurrencyCode = await AppSettings.shared.selectedCurrencyCode
        let converted = try await balanceConverter.convertToFiat(networkFee, currencyId: id)
        let formattedFiatFee = balanceFormatter.formatFiatBalance(converted, currencyCode: selectedCurrencyCode)
        return formattedFiatFee
    }

    // MARK: - Private Implementation

    private func currencyId(for currency: CurrencyType) throws -> String {
        switch currency {
        case .fee:
            guard let id = feeCurrency.currencyId else {
                throw YieldModuleFormatterFee.cannotFormatFee
            }
            return id

        case .token:
            guard let id = token.id else {
                throw YieldModuleFormatterFee.cannotFormatFee
            }
            return id
        }
    }
}

extension YieldModuleFeeFormatter {
    enum CurrencyType {
        case fee
        case token
    }
}
