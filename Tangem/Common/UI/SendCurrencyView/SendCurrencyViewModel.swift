//
//  SendCurrencyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendCurrencyViewModel: ObservableObject, Identifiable {
    @Published private(set) var headerState: HeaderState = .header
    @Published private(set) var fiatValue: State
    @Published private(set) var canChangeCurrency: Bool
    @Published private(set) var maximumFractionDigits: Int
    @Published private(set) var balance: State
    @Published private(set) var tokenIconState: SwappingTokenIconView.State

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

    private var walletDidChangeSubscription: AnyCancellable?

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

    func update(wallet: WalletModel, initialWalletId: Int) {
        canChangeCurrency = wallet.id != initialWalletId
        maximumFractionDigits = wallet.decimalCount
        tokenIconState = .icon(
            TokenIconInfoBuilder().build(from: wallet.tokenItem, isCustom: wallet.isCustom),
            symbol: wallet.tokenItem.currencySymbol
        )

        walletDidChangeSubscription = wallet.walletDidChangePublisher.sink { [weak self] state in
            switch state {
            case .created, .loading:
                self?.balance = .loading
            case .idle:
                let formatted = wallet.balanceValue.map { BalanceFormatter().formatDecimal($0) }
                self?.balance = .formatted(formatted ?? BalanceFormatter.defaultEmptyBalanceString)
            case .noAccount, .failed, .noDerivation:
                self?.balance = .formatted(BalanceFormatter.defaultEmptyBalanceString)
            }
        }
    }

    func updateSendFiatValue(amount: Decimal?, tokenItem: TokenItem) {
        guard let amount = amount else {
            update(fiatValue: .formatted(BalanceFormatter().formatFiatBalance(0)))
            return
        }

        guard let currencyId = tokenItem.currencyId else {
            update(fiatValue: .formatted(BalanceFormatter.defaultEmptyBalanceString))
            return
        }

        if let fiatValue = BalanceConverter().convertToFiat(value: amount, from: currencyId) {
            let formatted = BalanceFormatter().formatFiatBalance(fiatValue)
            update(fiatValue: .formatted(formatted))
            return
        }

        fiatValue = .loading

        runTask(in: self) { [currencyId] viewModel in
            let fiatValue = try await BalanceConverter().convertToFiat(value: amount, from: currencyId)
            let formatted = BalanceFormatter().formatFiatBalance(fiatValue)
            try Task.checkCancellation()

            await runOnMain {
                viewModel.update(fiatValue: .formatted(formatted))
            }
        }
    }

    func update(fiatValue: State) {
        self.fiatValue = fiatValue
    }

    func update(headerState: HeaderState) {
        // [REDACTED_TODO_COMMENT]
        self.headerState = headerState
    }
}

extension SendCurrencyViewModel {
    enum HeaderState {
        case header
        case insufficientFunds
    }

    enum State: Hashable {
        case idle
        case loading
        case formatted(_ value: String)

        @available(*, deprecated, renamed: "formatted", message: "Have to be formatted outside")
        case loaded(_ value: Decimal)
    }
}
