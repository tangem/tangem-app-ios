//
//  LoadableBalanceViewStateBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUI

struct LoadableBalanceViewStateBuilder {
    let formatter = BalanceFormatter()

    func build(type: FormattedTokenBalanceType, icon: LoadableBalanceView.State.Icon? = nil) -> LoadableBalanceView.State {
        switch type {
        case .loading(.cache(let cached)):
            .loading(cached: .string(cached.balance)) // Shining text
        case .loading(.empty):
            .loading(cached: .none) // Usual skeleton
        case .failure(.empty(let string)):
            .failed(cached: .string(string))
        case .failure(.cache(let cache)):
            .failed(cached: .string(cache.balance), icon: icon)
        case .loaded(let string):
            .loaded(text: .string(string))
        }
    }

    func build(type: FormattedTokenBalanceType, textBuilder builder: @escaping (String) -> String) -> LoadableBalanceView.State {
        switch type {
        case .loading(.cache(let cached)):
            .loading(cached: .builder(builder: builder, sensitive: cached.balance)) // Shining text
        case .loading(.empty):
            .loading(cached: .none) // Usual skeleton
        case .failure(.empty(let string)):
            .failed(cached: .builder(builder: builder, sensitive: string))
        case .failure(.cache(let cache)):
            .failed(cached: .builder(builder: builder, sensitive: cache.balance))
        case .loaded(let string):
            .loaded(text: .builder(builder: builder, sensitive: string))
        }
    }

    func buildAttributedTotalBalance(type: FormattedTokenBalanceType) -> LoadableBalanceView.State {
        switch type {
        case .loading(.cache(let cached)):
            let attributed = formatter.formatAttributedTotalBalance(fiatBalance: cached.balance)
            return .loading(cached: .attributed(attributed)) // Shining text
        case .loading(.empty):
            return .loading(cached: .none) // Usual skeleton
        case .failure(let cachedType):
            let attributed = formatter.formatAttributedTotalBalance(fiatBalance: cachedType.value)
            return .failed(cached: .attributed(attributed), icon: .none)
        case .loaded(let string):
            let attributed = formatter.formatAttributedTotalBalance(fiatBalance: string)
            return .loaded(text: .attributed(attributed))
        }
    }

    func buildTotalBalance(
        state: TotalBalanceState,
        currencyCode: String = AppSettings.shared.selectedCurrencyCode
    ) -> LoadableBalanceView.State {
        switch state {
        case .empty:
            return .empty
        case .loading(.none):
            return .loading(cached: .none)
        case .loading(.some(let cached)):
            let formatted = formatter.formatFiatBalance(cached, currencyCode: currencyCode)
            return .loading(cached: .string(formatted))
        case .failed(.none, _):
            return .failed(cached: .string(Localization.commonUnreachable))
        case .failed(.some(let cached), _):
            let formatted = formatter.formatFiatBalance(cached, currencyCode: currencyCode)
            return .failed(cached: .string(formatted), icon: .trailing)
        case .loaded(let balance):
            let formatted = formatter.formatFiatBalance(balance, currencyCode: currencyCode)
            return .loaded(text: .string(formatted))
        }
    }
}
