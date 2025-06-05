//
//  NFTPriceFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

final class NFTPriceFormatter: NFTPriceFormatting {
    private static let cryptoFormattingOptions: BalanceFormattingOptions = {
        let maxDigits = 4
        var options = BalanceFormattingOptions.defaultCryptoFormattingOptions
        options.maxFractionDigits = maxDigits
        options.roundingType = .default(roundingMode: .down, scale: maxDigits)

        return options
    }()

    private lazy var balanceFormatter = BalanceFormatter()
    private lazy var balanceConverter = BalanceConverter()

    func formatCryptoPrice(_ cryptoPrice: Decimal, in nftChain: NFTChain) -> String {
        // [REDACTED_TODO_COMMENT]
        let blockchain = NFTChainConverter.convert(nftChain, version: .v2)
        let convertedCryptoPrice = cryptoPrice / blockchain.decimalValue

        return balanceFormatter.formatCryptoBalance(
            convertedCryptoPrice,
            currencyCode: blockchain.currencySymbol,
            formattingOptions: Self.cryptoFormattingOptions
        )
    }

    func convertToFiatAndFormatCryptoPrice(_ cryptoPrice: Decimal, in nftChain: NFTChain) async -> String {
        // [REDACTED_TODO_COMMENT]
        let blockchain = NFTChainConverter.convert(nftChain, version: .v2)
        let convertedCryptoPrice = cryptoPrice / blockchain.decimalValue
        // Errors are intentionally ignored here, `BalanceFormatter.defaultEmptyBalanceString` will be used instead in case of failure
        let fiatValue = try? await balanceConverter.convertToFiat(convertedCryptoPrice, currencyId: blockchain.currencyId)

        return balanceFormatter.formatFiatBalance(fiatValue)
    }
}
