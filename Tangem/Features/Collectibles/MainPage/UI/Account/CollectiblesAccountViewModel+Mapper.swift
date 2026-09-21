//
//  CollectiblesAccountViewModel+Mapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUI

extension CollectiblesAccountViewModel {
    enum Mapper {
        private static let balanceFormatter = BalanceFormatter()

        static func map(
            fiat: FormattedTokenBalanceType,
            usdc: TokenBalanceType,
            isRefreshing: Bool
        ) -> CollectiblesAccountView.Summary {
            CollectiblesAccountView.Summary(
                fiatBalance: fiatBalanceState(settled(fiat, usdc: usdc)),
                fiatBalancePlainText: fiat.value,
                cryptoBalanceText: cryptoBalanceText(usdc.value),
                collectionCountText: collectionCountText(Constants.collectionCardsCount),
                isWithdrawalAvailable: usdc.mayHaveFunds,
                isBalanceUpdating: isRefreshing || usdc.isLoading
            )
        }
    }
}

private extension CollectiblesAccountViewModel.Mapper {
    // MARK: - Private logic

    static func settled(_ fiat: FormattedTokenBalanceType, usdc: TokenBalanceType) -> FormattedTokenBalanceType {
        guard case .loading(let cached) = fiat, usdc.isFailure else {
            return fiat
        }

        return .failure(cached)
    }

    static func fiatBalanceState(_ balance: FormattedTokenBalanceType) -> LoadableBalanceView.State {
        switch balance {
        case .loading(.empty):
            .loading(cached: .none)
        case .loading(.cache(let cached)):
            .loading(cached: .attributed(attributedFiatBalance(cached.balance)))
        case .failure(let cached):
            .failed(cached: .attributed(attributedFiatBalance(cached.value)), icon: .none)
        case .loaded(let balance):
            .loaded(text: .attributed(attributedFiatBalance(balance)))
        }
    }

    static func attributedFiatBalance(_ balance: String) -> AttributedString {
        balanceFormatter.formatAttributedTotalBalance(fiatBalance: balance, formattingOptions: .mainHeaderRedesign)
    }

    static func cryptoBalanceText(_ balance: Decimal?) -> String {
        guard let balance else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        let amount = balanceFormatter.formatDecimal(balance, formattingOptions: .defaultCryptoFormattingOptions)

        return "\(amount) \(CollectiblesChainEnvironment.usdcTokenItem.currencySymbol)"
    }

    static func collectionCountText(_ count: Int) -> String {
        guard count > 0 else {
            return Localization.collectiblesAccountCollectionEmpty
        }

        return Localization.collectiblesAccountCollectionCardsCount(count)
    }

    enum Constants {
        // [REDACTED_TODO_COMMENT]
        static let collectionCardsCount = 25
    }
}
