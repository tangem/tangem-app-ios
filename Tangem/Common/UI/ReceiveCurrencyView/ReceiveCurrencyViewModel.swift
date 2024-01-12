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
    @Published private(set) var topViewState: ExpressCurrencyTopView.State
    @Published private(set) var cryptoAmountState: LoadableTextView.State
    @Published private(set) var fiatAmountState: LoadableTextView.State
    @Published private(set) var priceChangePercent: String?
    @Published private(set) var tokenIconState: SwappingTokenIconView.State
    @Published private(set) var symbolState: LoadableTextView.State
    @Published private(set) var canChangeCurrency: Bool

    private var walletDidChangeSubscription: AnyCancellable?
    private var highPriceTask: Task<Void, Error>?

    init(
        topViewState: ExpressCurrencyTopView.State = .idle,
        cryptoAmountState: LoadableTextView.State = .initialized,
        fiatAmountState: LoadableTextView.State = .initialized,
        priceChangePercent: String? = nil,
        tokenIconState: SwappingTokenIconView.State = .loading,
        symbolState: LoadableTextView.State = .loading,
        canChangeCurrency: Bool
    ) {
        self.canChangeCurrency = canChangeCurrency
        self.topViewState = topViewState
        self.cryptoAmountState = cryptoAmountState
        self.fiatAmountState = fiatAmountState
        self.priceChangePercent = priceChangePercent
        self.tokenIconState = tokenIconState
        self.symbolState = symbolState
    }

    func update(wallet: LoadingValue<WalletModel>, initialWalletId: Int) {
        switch wallet {
        case .loading:
            canChangeCurrency = false
            tokenIconState = .loading
            symbolState = .loading
            topViewState = .loading
        case .loaded(let wallet):
            canChangeCurrency = wallet.id != initialWalletId
            tokenIconState = .icon(TokenIconInfoBuilder().build(from: wallet.tokenItem, isCustom: wallet.isCustom))
            symbolState = .loaded(text: wallet.tokenItem.currencySymbol)

            walletDidChangeSubscription = wallet.walletDidChangePublisher.sink { [weak self] state in
                switch state {
                case .created, .loading:
                    self?.topViewState = .loading
                case .idle:
                    let formatted = wallet.balanceValue.map { BalanceFormatter().formatDecimal($0) }
                    self?.topViewState = .formatted(formatted ?? BalanceFormatter.defaultEmptyBalanceString)
                case .noAccount, .failed, .noDerivation:
                    self?.topViewState = .formatted(BalanceFormatter.defaultEmptyBalanceString)
                }
            }
        case .failedToLoad:
            canChangeCurrency = true
            tokenIconState = .notAvailable
            symbolState = .noData
            topViewState = .notAvailable
        }
    }

    func updateReceiveCurrencyValue(expectAmount: Decimal?, tokenItem: TokenItem?) {
        guard let expectAmount else {
            update(cryptoAmountState: .loaded(text: "0"))
            update(fiatAmountState: .loaded(text: BalanceFormatter().formatFiatBalance(0)))
            return
        }

        let decimals = tokenItem?.decimalCount ?? 8
        let formatter = DecimalNumberFormatter(maximumFractionDigits: decimals)
        let formatted = formatter.format(value: expectAmount)
        update(cryptoAmountState: .loaded(text: formatted))

        guard let currencyId = tokenItem?.currencyId else {
            update(fiatAmountState: .loaded(text: BalanceFormatter().formatFiatBalance(0)))
            return
        }

        if let fiatValue = BalanceConverter().convertToFiat(value: expectAmount, from: currencyId) {
            let formatted = BalanceFormatter().formatFiatBalance(fiatValue)
            update(fiatAmountState: .loaded(text: formatted))
            return
        }

        update(fiatAmountState: .loading)

        runTask(in: self) { [currencyId] viewModel in
            let fiatValue = try await BalanceConverter().convertToFiat(value: expectAmount, from: currencyId)
            let formatted = BalanceFormatter().formatFiatBalance(fiatValue)

            try Task.checkCancellation()

            await runOnMain {
                viewModel.update(fiatAmountState: .loaded(text: formatted))
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

    func update(cryptoAmountState: LoadableTextView.State) {
        self.cryptoAmountState = cryptoAmountState
    }

    func update(fiatAmountState: LoadableTextView.State) {
        self.fiatAmountState = fiatAmountState
    }
}

extension ReceiveCurrencyViewModel {
    enum State: Hashable {
        case idle
        case loading
        case formatted(_ value: String)
    }
}
