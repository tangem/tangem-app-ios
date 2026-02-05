//
//  ExpressCurrencyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation
import struct TangemUI.TokenIconInfo

final class ExpressCurrencyViewModel: ObservableObject, Identifiable {
    // Header view
    @Published private(set) var viewType: ExpressCurrencyViewType
    @Published private(set) var headerType: ExpressCurrencyHeaderType
    @Published private(set) var errorState: ErrorState?
    @Published private(set) var balanceState: BalanceState

    // Bottom fiat
    @Published private(set) var fiatAmountState: LoadableTextView.State
    @Published private(set) var priceChangeState: PriceChangeState?

    // Trailing
    @Published private(set) var tokenIconState: TokenIconState
    @Published private(set) var symbolState: LoadableTextView.State
    @Published private(set) var canChangeCurrency: Bool

    private var walletDidChangeSubscription: AnyCancellable?
    private var highPriceTask: Task<Void, Error>?
    private var balanceConvertTask: Task<Void, Error>?

    init(
        viewType: ExpressCurrencyViewType,
        headerType: ExpressCurrencyHeaderType,
        balanceState: BalanceState = .idle,
        fiatAmountState: LoadableTextView.State = .initialized,
        priceChangeState: PriceChangeState? = nil,
        tokenIconState: TokenIconState = .loading,
        symbolState: LoadableTextView.State = .loading,
        canChangeCurrency: Bool
    ) {
        self.viewType = viewType
        self.headerType = headerType
        self.balanceState = balanceState
        self.fiatAmountState = fiatAmountState
        self.priceChangeState = priceChangeState
        self.tokenIconState = tokenIconState
        self.symbolState = symbolState
        self.canChangeCurrency = canChangeCurrency
    }

    func update(wallet: LoadingResult<any ExpressGenericWallet, Error>?, initialWalletId: WalletModelId) {
        switch wallet {
        case .loading:
            canChangeCurrency = false
            tokenIconState = .loading
            symbolState = .loading
            balanceState = .loading

        case .success(let wallet as ExpressInteractorSourceWallet):
            headerType = ExpressCurrencyHeaderType(viewType: viewType, tokenHeader: wallet.tokenHeader)
            canChangeCurrency = wallet.id != initialWalletId
            symbolState = .loaded(text: wallet.tokenItem.currencySymbol)
            tokenIconState = .icon(TokenIconInfoBuilder().build(from: wallet.tokenItem, isCustom: wallet.isCustom))
            walletDidChangeSubscription = wallet.availableBalanceProvider.balanceTypePublisher.sink { [weak self] state in
                switch state {
                case .loading:
                    self?.balanceState = .loading
                case .loaded(let balance):
                    let formatted = BalanceFormatter().formatDecimal(balance)
                    self?.balanceState = .formatted(formatted)
                // No balance cases
                case .empty, .failure:
                    self?.balanceState = .formatted(BalanceFormatter.defaultEmptyBalanceString)
                }
            }

        case .success(let wallet as ExpressInteractorTangemPayWallet):
            headerType = .action(name: viewType.actionName())
            canChangeCurrency = false
            symbolState = .loaded(text: wallet.tokenItem.currencySymbol)
            tokenIconState = .icon(TokenIconInfoBuilder().build(from: wallet.tokenItem, isCustom: wallet.isCustom))

            walletDidChangeSubscription = wallet.availableBalanceProvider.formattedBalanceTypePublisher.sink { [weak self] state in
                switch state {
                case .loading:
                    self?.balanceState = .loading
                case .loaded(let formatted):
                    self?.balanceState = .formatted(formatted)
                // No balance cases
                case .failure:
                    self?.balanceState = .formatted(BalanceFormatter.defaultEmptyBalanceString)
                }
            }

        case .success(let wallet as ExpressInteractorDestinationWallet):
            headerType = .action(name: viewType.actionName())
            canChangeCurrency = false
            symbolState = .loaded(text: wallet.tokenItem.currencySymbol)
            tokenIconState = .icon(TokenIconInfoBuilder().build(from: wallet.tokenItem, isCustom: wallet.isCustom))
            // No balance for abstract wallet
            balanceState = .idle

        case .success(let wallet):
            assertionFailure("Don't have implementation for \(wallet)")
            fallthrough

        case .none, .failure:
            headerType = .action(name: viewType.actionName())
            canChangeCurrency = true
            tokenIconState = .notAvailable
            symbolState = .noData
            balanceState = .notAvailable
        }
    }

    func updateFiatValue(expectAmount: Decimal?, tokenItem: TokenItem?) {
        guard let expectAmount else {
            update(fiatAmountState: .loaded(text: BalanceFormatter().formatFiatBalance(0)))
            return
        }

        guard let currencyId = tokenItem?.currencyId else {
            update(fiatAmountState: .loaded(text: BalanceFormatter().formatFiatBalance(0)))
            return
        }

        if let fiatValue = BalanceConverter().convertToFiat(expectAmount, currencyId: currencyId) {
            let formatted = BalanceFormatter().formatFiatBalance(fiatValue)
            update(fiatAmountState: .loaded(text: formatted))
            return
        }

        update(fiatAmountState: .loading)

        balanceConvertTask?.cancel()
        balanceConvertTask = runTask(in: self) { [currencyId] viewModel in
            let fiatValue = try await BalanceConverter().convertToFiat(expectAmount, currencyId: currencyId)
            let formatted = BalanceFormatter().formatFiatBalance(fiatValue)

            try Task.checkCancellation()

            await runOnMain {
                viewModel.update(fiatAmountState: .loaded(text: formatted))
            }
        }
    }

    func updateHighPricePercentLabel(quote: ExpressInteractor.Quote?) {
        guard let highPriceImpact = quote?.highPriceImpact else {
            priceChangeState = nil
            return
        }

        guard highPriceImpact.isHighPriceImpact else {
            priceChangeState = .info(message: highPriceImpact.infoMessage)
            return
        }

        priceChangeState = .percent(highPriceImpact.lossesInPercentsFormatted, message: highPriceImpact.infoMessage)
    }

    func update(errorState: ErrorState?) {
        self.errorState = errorState
    }

    func update(fiatAmountState: LoadableTextView.State) {
        self.fiatAmountState = fiatAmountState
    }
}

extension ExpressCurrencyViewModel {
    enum PriceChangeState: Hashable {
        case info(message: String)
        case percent(_ formatted: String, message: String)

        var message: String {
            switch self {
            case .info(let message): message
            case .percent(_, let message): message
            }
        }
    }

    enum ErrorState: Hashable {
        case insufficientFunds
        case error(String)
    }

    enum BalanceState: Hashable {
        case idle
        case notAvailable
        case loading
        case formatted(String)
    }

    enum TokenIconState: Hashable {
        case loading
        case notAvailable
        case icon(TokenIconInfo)
    }
}
