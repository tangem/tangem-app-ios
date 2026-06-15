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
    @Published private(set) var state: State

    let viewType: ExpressCurrencyViewType

    private var balanceStateCancellable: AnyCancellable?
    private var highPriceTask: Task<Void, Error>?
    private var balanceConvertTask: Task<Void, Error>?

    private let loadableBalanceViewStateBuilder = LoadableBalanceViewStateBuilder()
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()

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
        state = State(
            headerType: headerType,
            balanceState: balanceState,
            fiatAmountState: fiatAmountState,
            priceChangeState: priceChangeState,
            tokenIconState: tokenIconState,
            symbolState: symbolState,
            canChangeCurrency: canChangeCurrency
        )
    }

    func update(wallet: LoadingResult<any SendGenericToken, Error>) {
        state.update(wallet: wallet, viewType: viewType)

        if case .success(let wallet as SendSourceToken) = wallet {
            balanceStateCancellable = wallet.availableBalanceProvider.formattedBalanceTypePublisher
                .withWeakCaptureOf(self)
                .map { $0.loadableBalanceViewStateBuilder.build(type: $1) }
                .receiveOnMain()
                .sink { [weak self] value in
                    self?.state.balanceState = value
                }
        } else {
            balanceStateCancellable = nil
        }
    }

    func updateFiatValue(expectAmount: Decimal?, tokenItem: TokenItem?) {
        guard let expectAmount else {
            update(fiatAmountState: .loaded(text: balanceFormatter.formatFiatBalance(0)))
            return
        }

        guard let currencyId = tokenItem?.currencyId else {
            update(fiatAmountState: .loaded(text: balanceFormatter.formatFiatBalance(0)))
            return
        }

        if let fiatValue = balanceConverter.convertToFiat(expectAmount, currencyId: currencyId) {
            let formatted = balanceFormatter.formatFiatBalance(fiatValue)
            update(fiatAmountState: .loaded(text: formatted))
            return
        }

        update(fiatAmountState: .loading)

        balanceConvertTask?.cancel()
        balanceConvertTask = runTask(in: self) { [currencyId, balanceConverter, balanceFormatter] viewModel in
            let fiatValue = try await balanceConverter.convertToFiat(expectAmount, currencyId: currencyId)
            let formatted = balanceFormatter.formatFiatBalance(fiatValue)

            try Task.checkCancellation()

            await runOnMain {
                viewModel.update(fiatAmountState: .loaded(text: formatted))
            }
        }
    }

    func updateHighPricePercentLabel(highPriceImpact: HighPriceImpactCalculator.Result?) {
        guard let highPriceImpact else {
            state.priceChangeState = nil
            return
        }

        if highPriceImpact.level.isNegligible {
            state.priceChangeState = .info(message: highPriceImpact.infoMessage)
        } else {
            state.priceChangeState = .percent(highPriceImpact.lossesInPercentsFormatted, message: highPriceImpact.infoMessage, isHighLoss: highPriceImpact.isHighLoss)
        }
    }

    func update(errorState: ErrorState?) {
        state.errorState = errorState
    }

    func update(fiatAmountState: LoadableTextView.State) {
        state.fiatAmountState = fiatAmountState
    }

    func update(isFiatAmountHidden: Bool) {
        state.isFiatAmountHidden = isFiatAmountHidden
    }
}

extension ExpressCurrencyViewModel {
    struct State {
        var headerType: SendTokenHeader
        var errorState: ErrorState?
        var balanceState: LoadableBalanceView.State
        var fiatAmountState: LoadableTextView.State
        var priceChangeState: PriceChangeState?
        var tokenIconState: TokenIconState
        var symbolState: LoadableTextView.State
        var canChangeCurrency: Bool
        var isFiatAmountHidden: Bool = false

        mutating func update(
            wallet: LoadingResult<any SendGenericToken, Error>,
            viewType: ExpressCurrencyViewType
        ) {
            switch wallet {
            case .loading:
                canChangeCurrency = false
                tokenIconState = .loading
                symbolState = .loading
                balanceState = .loading(cached: .none)

            case .success(let wallet as SendSourceToken):
                headerType = wallet.header.asSendTokenHeader(actionType: .swap, isSource: viewType == .send)
                canChangeCurrency = true
                symbolState = .loaded(text: wallet.tokenItem.currencySymbol)
                tokenIconState = .icon(TokenIconInfoBuilder().build(from: wallet.tokenItem, isCustom: wallet.isCustom))
                // balanceState is updated via publisher subscription in ViewModel

            case .success(let wallet as SendReceiveToken):
                headerType = .action(name: viewType.actionName())
                canChangeCurrency = true
                symbolState = .loaded(text: wallet.tokenItem.currencySymbol)
                tokenIconState = .icon(TokenIconInfoBuilder().build(from: wallet.tokenItem, isCustom: false))
                balanceState = .empty

            case .success(let wallet):
                assertionFailure("Don't have implementation for \(wallet)")
                headerType = .action(name: viewType.actionName())
                canChangeCurrency = true
                tokenIconState = .notAvailable
                symbolState = .noData
                balanceState = .empty

            case .failure(let error as SwapModel.SwapModelError) where error == .tokenSelectionRequired:
                headerType = .action(name: viewType.actionName())
                canChangeCurrency = true
                tokenIconState = .tokenSelectionRequired
                symbolState = .initialized
                balanceState = .loaded(text: "")

            case .failure:
                headerType = .action(name: viewType.actionName())
                canChangeCurrency = true
                tokenIconState = .notAvailable
                symbolState = .noData
                balanceState = .empty
            }
        }
    }

    enum PriceChangeState: Hashable {
        case info(message: String)
        case percent(_ formatted: String, message: String, isHighLoss: Bool)

        var message: String {
            switch self {
            case .info(let message): message
            case .percent(_, let message, _): message
            }
        }
    }

    enum ErrorState: Hashable {
        case insufficientFunds
        case error(String)
    }

    enum TokenIconState: Hashable {
        case loading
        case notAvailable
        case tokenSelectionRequired
        case icon(TokenIconInfo)
    }
}
