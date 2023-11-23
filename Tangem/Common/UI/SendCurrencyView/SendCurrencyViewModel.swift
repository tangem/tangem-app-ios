//
//  SendCurrencyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class SendCurrencyViewModel: ObservableObject, Identifiable {
    @Published var maximumFractionDigits: Int
    @Published var canChangeCurrency: Bool
    @Published var balance: State
    @Published var fiatValue: State
    @Published var tokenIconState: SwappingTokenIconView.State

    var balanceString: String {
        switch balance {
        case .idle:
            return ""
        case .loading:
            return "0"
        case .loaded(let value):
            return value.groupedFormatted()
        case .formatted(let value):
            return value
        }
    }

    var fiatValueString: String {
        switch fiatValue {
        case .idle:
            return ""
        case .loading:
            return "0"
        case .loaded(let value):
            return value.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
        case .formatted(let value):
            return value
        }
    }

    init(
        balance: State = .idle,
        fiatValue: State = .idle,
        maximumFractionDigits: Int,
        canChangeCurrency: Bool,
        tokenIconState: SwappingTokenIconView.State
    ) {
        self.balance = balance
        self.fiatValue = fiatValue
        self.maximumFractionDigits = maximumFractionDigits
        self.canChangeCurrency = canChangeCurrency
        self.tokenIconState = tokenIconState
    }

    func textFieldDidTapped() {
        Analytics.log(.swapSendTokenBalanceClicked)
    }

    func update(balance: State) {
        self.balance = balance
    }

    func update(fiatValue: State) {
        self.fiatValue = fiatValue
    }

    func update(maximumFractionDigits: Int) {
        self.maximumFractionDigits = maximumFractionDigits
    }
}

extension SendCurrencyViewModel {
    enum State: Hashable {
        case idle
        case loading
        case formatted(_ value: String)

        @available(*, deprecated, renamed: "formatted", message: "Have to be formatted outside")
        case loaded(_ value: Decimal)
    }
}
