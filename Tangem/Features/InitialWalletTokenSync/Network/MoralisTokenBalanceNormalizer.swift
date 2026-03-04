//
//  MoralisTokenBalanceNormalizer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemFoundation

enum MoralisTokenBalanceNormalizer {
    static func normalize(_ balances: [MoralisTokenBalanceDTO.TokenBalance]) throws -> [MoralisTokenBalance] {
        try balances.map(normalize)
    }
}

private extension MoralisTokenBalanceNormalizer {
    static func normalize(_ balance: MoralisTokenBalanceDTO.TokenBalance) throws -> MoralisTokenBalance {
        guard let normalizedAmount = parseAmount(
            rawBalance: balance.balance,
            formattedBalance: balance.balanceFormatted,
            decimals: balance.decimals
        ) else {
            throw NormalizationError.invalidAmount(
                rawBalance: balance.balance,
                formattedBalance: balance.balanceFormatted,
                decimals: balance.decimals
            )
        }

        return MoralisTokenBalance(
            contractAddress: balance.nativeToken ? nil : balance.tokenAddress,
            symbol: balance.symbol,
            name: balance.name,
            decimals: balance.decimals,
            amount: normalizedAmount,
            isNativeToken: balance.nativeToken
        )
    }

    static func parseAmount(rawBalance: String, formattedBalance: String, decimals: Int) -> Decimal? {
        guard decimals >= 0 else {
            return nil
        }

        if let rawDecimal = Decimal(stringValue: rawBalance) {
            return rawDecimal.moveLeft(decimals: decimals)
        }

        return Decimal(stringValue: formattedBalance)
    }
}

extension MoralisTokenBalanceNormalizer {
    enum NormalizationError: Error {
        case invalidAmount(rawBalance: String, formattedBalance: String, decimals: Int)
    }
}
