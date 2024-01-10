//
//  ReceiveCurrencyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

class ReceiveCurrencyViewModel: ObservableObject, Identifiable {
    @Published private(set) var canChangeCurrency: Bool
    @Published private(set) var balance: State
    @Published private(set) var cryptoAmountState: State
    @Published private(set) var fiatAmountState: State
    @Published private(set) var priceChangePercent: String?
    @Published private(set) var tokenIconState: SwappingTokenIconView.State
    @Published private(set) var isAvailable: Bool = true

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

    var cryptoAmountFormatted: String {
        switch cryptoAmountState {
        case .idle:
            return ""
        case .loading:
            return "0"
        case .loaded(let value):
            let formatter = DecimalNumberFormatter(maximumFractionDigits: 8)
            return formatter.format(value: value)
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

    private var walletDidChangeSubscription: AnyCancellable?
    private var highPriceTask: Task<Void, Error>?

    init(
        balance: State = .idle,
        canChangeCurrency: Bool,
        cryptoAmountState: State = .idle,
        fiatAmountState: State = .idle,
        tokenIconState: SwappingTokenIconView.State
    ) {
        self.balance = balance
        self.canChangeCurrency = canChangeCurrency
        self.cryptoAmountState = cryptoAmountState
        self.fiatAmountState = fiatAmountState
        self.tokenIconState = tokenIconState
    }

    func update(wallet: LoadingValue<WalletModel>, initialWalletId: Int) {
        switch wallet {
        case .loading:
            canChangeCurrency = false
            tokenIconState = .loading
            isAvailable = true
        case .loaded(let wallet):
            isAvailable = true
            canChangeCurrency = wallet.id != initialWalletId
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
        case .failedToLoad:
            canChangeCurrency = true
            tokenIconState = .notAvailable
            isAvailable = false
        }
    }

    func updateReceiveCurrencyValue(expectAmount: Decimal?, tokenItem: TokenItem?) {
        guard let expectAmount else {
            update(cryptoAmountState: .formatted("0"))
            update(fiatAmountState: .formatted(BalanceFormatter().formatFiatBalance(0)))
            return
        }

        let decimals = tokenItem?.decimalCount ?? 8
        let formatter = DecimalNumberFormatter(maximumFractionDigits: decimals)
        let formatted = formatter.format(value: expectAmount)
        update(cryptoAmountState: .formatted(formatted))

        guard let currencyId = tokenItem?.currencyId else {
            update(fiatAmountState: .formatted(BalanceFormatter().formatFiatBalance(0)))
            return
        }

        if let fiatValue = BalanceConverter().convertToFiat(value: expectAmount, from: currencyId) {
            let formatted = BalanceFormatter().formatFiatBalance(fiatValue)
            update(fiatAmountState: .formatted(formatted))
            return
        }

        update(fiatAmountState: .loading)

        runTask(in: self) { [currencyId] viewModel in
            let fiatValue = try await BalanceConverter().convertToFiat(value: expectAmount, from: currencyId)
            let formatted = BalanceFormatter().formatFiatBalance(fiatValue)

            try Task.checkCancellation()

            await runOnMain {
                viewModel.update(fiatAmountState: .formatted(formatted))
            }
        }
    }

    func updateHighPricePercentLabel(quote: ExpressQuote?, sourceCurrencyId: String?, destinationCurrencyId: String?) {
        guard let fromAmount = quote?.fromAmount,
              let expectAmount = quote?.expectAmount,
              let sourceCurrencyId,
              let destinationCurrencyId else {
            priceChangePercent = nil
            return
        }

        highPriceTask = runTask(in: self) { viewModel in
            let priceImpactCalculator = HighPriceImpactCalculator(sourceCurrencyId: sourceCurrencyId, destinationCurrencyId: destinationCurrencyId)
            let result = try await priceImpactCalculator.isHighPriceImpact(
                converting: fromAmount,
                to: expectAmount
            )

            guard result.isHighPriceImpact else {
                await runOnMain {
                    viewModel.priceChangePercent = nil
                }
                return
            }

            let percentFormatter = PercentFormatter()
            let formatted = percentFormatter.expressRatePercentFormat(value: -result.lossesInPercents)
            await runOnMain {
                viewModel.priceChangePercent = formatted
            }
        }
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

        @available(*, deprecated, renamed: "formatted", message: "Have to be formatted outside")
        case loaded(_ value: Decimal)
    }
}
