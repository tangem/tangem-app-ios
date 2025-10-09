//
//  YieldModuleFeeFormatter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

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

    func formatCryptoBalance(_ balance: Decimal, prefix: String? = nil) -> String {
        (prefix ?? "") + balanceFormatter.formatCryptoBalance(balance, currencyCode: token.currencySymbol)
    }

    func createFeeString(from networkFee: Decimal) async throws -> String {
        guard let id = feeCurrency.id else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        let converted = try await balanceConverter.convertToFiat(networkFee, currencyId: id)
        let formattedFiatFee = balanceFormatter.formatFiatBalance(converted, currencyCode: AppConstants.usdCurrencyCode)
        let formattedCryptoFee = balanceFormatter.formatCryptoBalance(networkFee, currencyCode: feeCurrency.currencySymbol)
        let resultString = "\(formattedCryptoFee) \(AppConstants.dotSign) \(formattedFiatFee)"
        return resultString
    }

    func makeFeeInTokenString(from networkFee: Decimal) async throws -> String {
        let (tokenAmount, fiatAmount) = try await convertFeeToToken(networkFee: networkFee)
        let formattedFiatFee = balanceFormatter.formatFiatBalance(fiatAmount, currencyCode: AppConstants.usdCurrencyCode)
        let formattedCryptoFee = balanceFormatter.formatCryptoBalance(
            tokenAmount, currencyCode: token.currencySymbol,
            formattingOptions: .defaultFiatFormattingOptions
        )

        return "\(formattedCryptoFee) \(AppConstants.dotSign) \(formattedFiatFee)"
    }

    // MARK: - Private Implementation

    private func convertFeeToToken(networkFee: Decimal) async throws -> (token: Decimal, fiat: Decimal) {
        guard let feeCurrencyId = feeCurrency.id, let tokenId = token.id else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        let coinToFiat = try await balanceConverter.convertToFiat(networkFee, currencyId: feeCurrencyId)

        guard let fiatToToken = balanceConverter.convertFromFiat(coinToFiat, currencyId: tokenId) else {
            throw YieldModuleFormatterFee.cannotFormatFee
        }

        return (fiatToToken, coinToFiat)
    }
}
