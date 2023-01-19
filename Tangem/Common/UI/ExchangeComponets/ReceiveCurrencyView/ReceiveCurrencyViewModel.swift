//
//  ReceiveCurrencyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct ReceiveCurrencyViewModel: Identifiable {
    var id: Int { hashValue }

    private(set) var valueState: State
    private(set) var fiatValueState: State

    let tokenIcon: SwappingTokenIconViewModel

    var balanceString: String? {
        Localization.commonBalance((balance ?? 0).groupedFormatted())
    }

    var value: String {
        valueState.value?.groupedFormatted() ?? "0"
    }

    var fiatValue: String {
        fiatValueState.value?.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode) ?? "0"
    }

    private let balance: Decimal?

    init(
        balance: Decimal?,
        valueState: State,
        fiatValueState: State,
        tokenIcon: SwappingTokenIconViewModel
    ) {
        self.balance = balance
        self.valueState = valueState
        self.fiatValueState = fiatValueState
        self.tokenIcon = tokenIcon
    }

    mutating func update(valueState: State) {
        self.valueState = valueState
    }

    mutating func update(fiatValueState: State) {
        self.fiatValueState = fiatValueState
    }
}

extension ReceiveCurrencyViewModel {
    enum State: Hashable {
        case loading
        case loaded(_ value: Decimal)

        var value: Decimal? {
            switch self {
            case .loaded(let value):
                return value
            default:
                return nil
            }
        }
    }
}

extension ReceiveCurrencyViewModel: Hashable {
    static func == (lhs: ReceiveCurrencyViewModel, rhs: ReceiveCurrencyViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(valueState)
        hasher.combine(fiatValueState)
        hasher.combine(tokenIcon)
    }
}
