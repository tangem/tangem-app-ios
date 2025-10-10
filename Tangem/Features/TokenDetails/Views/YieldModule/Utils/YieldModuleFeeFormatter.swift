//
//  YieldModuleFeeFormatter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct YieldModuleFeeFormatter {
    private let feeCurrency: TokenItem
    private let token: TokenItem
    private let maximumFee: Decimal

    // MARK: - Dependencies

    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()

    // MARK: - Init

    init(feeCurrency: TokenItem, token: TokenItem, maximumFee: Decimal) {
        self.feeCurrency = feeCurrency
        self.token = token
        self.maximumFee = maximumFee
    }

    // MARK: - Public Implementation

    func createFeeString(from networkFee: Decimal) async -> String? {
        if let id = feeCurrency.id,
           let converted = try? await balanceConverter.convertToFiat(networkFee, currencyId: id) {
            let formattedFiatFee = balanceFormatter.formatFiatBalance(converted, currencyCode: AppConstants.usdCurrencyCode)
            let formattedCryptoFee = balanceFormatter.formatCryptoBalance(networkFee, currencyCode: feeCurrency.currencySymbol)
            let resultString = "\(formattedCryptoFee) \(AppConstants.dotSign) \(formattedFiatFee)"
            return resultString
        }

        return nil
    }

    func makeFeeInTokenString(from networkFee: Decimal) async -> String? {
        guard let (tokenAmount, fiatAmount) = await convertFeeToToken(networkFee: networkFee) else {
            return nil
        }

        let formattedFiatFee = balanceFormatter.formatFiatBalance(fiatAmount, currencyCode: AppConstants.usdCurrencyCode)
        let formattedCryptoFee = balanceFormatter.formatCryptoBalance(
            tokenAmount, currencyCode: token.currencySymbol,
            formattingOptions: .defaultFiatFormattingOptions
        )

        return "\(formattedCryptoFee) · \(formattedFiatFee)"
    }

    // MARK: - Private Implementation

    private func convertFeeToToken(networkFee: Decimal) async -> (token: Decimal, fiat: Decimal)? {
        guard let feeCurrencyId = feeCurrency.id,
              let tokenId = token.id,
              let coinToFiat = try? await balanceConverter.convertToFiat(networkFee, currencyId: feeCurrencyId),
              let fiatToToken = balanceConverter.convertFromFiat(coinToFiat, currencyId: tokenId)
        else {
            return nil
        }

        return (fiatToToken, coinToFiat)
    }
}
