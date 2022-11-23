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

    private(set) var state: State

    let tokenIcon: TokenIconViewModel
    let didTapTokenView: () -> Void
    
    var tokenName: String { tokenIcon.name }

    var value: String {
        guard let value = state.value as? NSDecimalNumber else {
            return "0"
        }

        return NumberFormatter.grouped.string(from: value) ?? "0"
    }

    var fiatValue: String {
        state.fiatValue?.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode) ?? "0"
    }

    init(
        state: State,
        tokenIcon: TokenIconViewModel,
        didTapTokenView: @escaping () -> Void
    ) {
        self.state = state
        self.tokenIcon = tokenIcon
        self.didTapTokenView = didTapTokenView
    }

    mutating func updateState(_ state: State) {
        self.state = state
    }
}

extension ReceiveCurrencyViewModel {
    enum State: Hashable {
        case loading
        case loaded(_ value: Decimal, fiatValue: Decimal)

        var value: Decimal? {
            switch self {
            case .loaded(let value, _):
                return value
            default:
                return nil
            }
        }

        var fiatValue: Decimal? {
            switch self {
            case .loaded(_, let fiatValue):
                return fiatValue
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
        hasher.combine(state)
        hasher.combine(tokenIcon)
    }
}

