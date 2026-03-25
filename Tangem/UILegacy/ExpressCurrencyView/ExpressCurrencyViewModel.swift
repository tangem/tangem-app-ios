//
//  ExpressCurrencyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import TangemUI

final class ExpressCurrencyViewModel: ObservableObject, Identifiable {
    // Header view
    @Published private(set) var viewType: ExpressCurrencyViewType
    @Published private(set) var headerType: SendTokenHeader
    @Published private(set) var errorState: ErrorState?
    @Published private(set) var balanceState: LoadableBalanceView.State

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

    private let loadableBalanceViewStateBuilder = LoadableBalanceViewStateBuilder()

    init(
        viewType: ExpressCurrencyViewType,
        headerType: SendTokenHeader,
        balanceState: LoadableBalanceView.State = .empty,
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

    func update(wallet: LoadingResult<any SendGenericToken, Error>, initialWalletId: WalletModelId) {
        switch wallet {
        case .loading:
            canChangeCurrency = false
            tokenIconState = .loading
            symbolState = .loading
            balanceState = .loading(cached: .none)

        case .success(let wallet as SendSourceToken):
            headerType = wallet.header.asSendTokenHeader(actionType: .swap, isSource: viewType == .send)
            canChangeCurrency = wallet.id != initialWalletId
            symbolState = .loaded(text: wallet.tokenItem.currencySymbol)
            tokenIconState = .icon(TokenIconInfoBuilder().build(from: wallet.tokenItem, isCustom: wallet.isCustom))
            wallet.availableBalanceProvider.formattedBalanceTypePublisher
                .withWeakCaptureOf(self)
                .map { $0.loadableBalanceViewStateBuilder.build(type: $1) }
                .receiveOnMain()
                .assign(to: &$balanceState)

        case .success(let wallet as SendReceiveToken):
            headerType = .action(name: viewType.actionName())
            canChangeCurrency = false
            symbolState = .loaded(text: wallet.tokenItem.currencySymbol)
            tokenIconState = .icon(TokenIconInfoBuilder().build(from: wallet.tokenItem, isCustom: false))
            // No balance for abstract wallet
            balanceState = .empty

        case .success(let wallet):
            assertionFailure("Don't have implementation for \(wallet)")
            fallthrough

        case .failure:
            headerType = .action(name: viewType.actionName())
            canChangeCurrency = true
            tokenIconState = .notAvailable
            symbolState = .noData
            balanceState = .empty
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

    func updateHighPricePercentLabel(highPriceImpact: HighPriceImpactCalculator.Result?) {
        guard let highPriceImpact else {
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
