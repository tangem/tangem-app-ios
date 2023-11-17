//
//  ReceiveCurrencyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ReceiveCurrencyViewModel: ObservableObject, Identifiable {
    @Published var canChangeCurrency: Bool
    @Published var balance: String
    @Published var cryptoAmountState: State
    @Published var fiatAmountState: State
    @Published var tokenIconState: SwappingTokenIconView.State

    var balanceString: String {
        if FeatureProvider.isAvailable(.express) {
            return balance
        }

        return (balanceValue ?? 0).groupedFormatted()
    }

    var cryptoAmountFormatted: String {
        switch cryptoAmountState {
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

    var fiatAmountFormatted: String {
        switch fiatAmountState {
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

    private let balanceValue: Decimal?

    init(
        balanceValue: Decimal? = nil,
        balance: String = "",
        canChangeCurrency: Bool,
        cryptoAmountState: State = .idle,
        fiatAmountState: State = .idle,
        tokenIconState: SwappingTokenIconView.State
    ) {
        self.balanceValue = balanceValue
        self.balance = balance
        self.canChangeCurrency = canChangeCurrency
        self.cryptoAmountState = cryptoAmountState
        self.fiatAmountState = fiatAmountState
        self.tokenIconState = tokenIconState
    }

    func update(cryptoAmountState: State) {
        self.cryptoAmountState = cryptoAmountState
    }

    func update(fiatAmountState: State) {
        self.fiatAmountState = fiatAmountState
    }
}

extension ReceiveCurrencyViewModel {
    enum State: Hashable {
        case idle
        case loading
        case formatted(_ value: String)
        case loaded(_ value: Decimal)
    }
}
