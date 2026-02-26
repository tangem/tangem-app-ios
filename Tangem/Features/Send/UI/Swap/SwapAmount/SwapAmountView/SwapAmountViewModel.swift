//
//  SwapAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemUI
import TangemLocalization
import TangemFoundation

protocol SwapAmountCompactRoutable: AnyObject {
    func userDidTapChangeSourceTokenButton(tokenItem: TokenItem)
    func userDidTapSwapSourceAndReceiveTokensButton()
    func userDidTapChangeReceiveTokenButton(tokenItem: TokenItem)
}

final class SwapAmountViewModel: ObservableObject, Identifiable {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    @Published private(set) var sourceExpressCurrencyViewModel: ExpressCurrencyViewModel
    @Published private(set) var sourceDecimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel

    @Published private(set) var isSwapButtonLoading: Bool = false
    @Published private(set) var isSwapButtonDisabled: Bool = false

    @Published private(set) var receiveExpressCurrencyViewModel: ExpressCurrencyViewModel
    @Published private(set) var receiveCryptoAmountState: LoadableTextView.State = .initialized

    weak var router: SwapAmountCompactRoutable?

    private let initialTokenItem: TokenItem
    private let interactor: SendAmountInteractor

    private weak var stateProvider: SwapModelStateProvider?
    private weak var sourceTokenInput: SendSourceTokenInput?
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()

    private var sourceExpressCurrencyStateCancellable: AnyCancellable?
    private var sourceTokenCancellable: AnyCancellable?
    private var sourceTokenAmountCancellable: AnyCancellable?

    private var receiveTokenCancellable: AnyCancellable?
    private var highPriceImpactCancellable: AnyCancellable?

    init(
        initialTokenItem: TokenItem,
        interactor: SendAmountInteractor,
        stateProvider: SwapModelStateProvider,
        sourceTokenInput: SendSourceTokenInput,
        receiveTokenInput: SendReceiveTokenInput?,
    ) {
        self.initialTokenItem = initialTokenItem
        self.interactor = interactor
        self.stateProvider = stateProvider
        self.sourceTokenInput = sourceTokenInput
        self.receiveTokenInput = receiveTokenInput

        sourceExpressCurrencyViewModel = .init(
            viewType: .send,
            headerType: .action(name: Localization.swappingFromTitle),
            canChangeCurrency: sourceTokenInput.sourceToken.value?.tokenItem != initialTokenItem
        )

        sourceDecimalNumberTextFieldViewModel = .init(
            maximumFractionDigits: sourceTokenInput.sourceToken.value?.tokenItem.decimalCount ?? 0
        )

        receiveExpressCurrencyViewModel = .init(
            viewType: .receive,
            headerType: .action(name: Localization.swappingToTitle),
            canChangeCurrency: receiveTokenInput?.receiveToken.value?.tokenItem != initialTokenItem
        )

        receiveCryptoAmountState = .initialized

        bind()
    }

    func bind() {
        // Buttons updating

        interactor.receivedTokenPublisher
            .map { ($0.value as? SendSourceToken) == nil }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$isSwapButtonDisabled)

        stateProvider?.statePublisher
            .filter { $0.filter(loading: [.autoupdate]) }
            .map { $0.isLoading }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$isSwapButtonLoading)

        sourceExpressCurrencyStateCancellable = stateProvider?.statePublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateSourceExpressCurrencyState(providersState: $1) }

        // Source token / amount updating

        sourceTokenCancellable = interactor.sourceTokenPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateSource(sourceToken: $1) }

        sourceTokenAmountCancellable = sourceDecimalNumberTextFieldViewModel
            .valuePublisher
            .prepend(.none)
            .withWeakCaptureOf(self)
            .map { $0.update(amount: $1) }
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateSourceFiat(amount: $1) }

        // Receive token / amount updating

        receiveTokenCancellable = Publishers.CombineLatest(
            interactor.receivedTokenAmountPublisher,
            interactor.receivedTokenPublisher
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { $0.updateReceive(amount: $1.0, receiveToken: $1.1) }

        highPriceImpactCancellable = interactor
            .highPriceImpactPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.receiveExpressCurrencyViewModel.updateHighPricePercentLabel(highPriceImpact: $1) }
    }

    func textFieldDidTapped() {
        Analytics.log(.swapSendTokenBalanceClicked)
    }

    func userDidTapChangeSourceTokenButton() {
        if let receiveToken = receiveTokenInput?.receiveToken.value?.tokenItem {
            router?.userDidTapChangeSourceTokenButton(tokenItem: receiveToken)
        }
    }

    func userDidTapSwapSourceAndReceiveTokensButton() {
        router?.userDidTapSwapSourceAndReceiveTokensButton()
    }

    func userDidTapChangeReceiveTokenButton() {
        if let sourceToken = sourceTokenInput?.sourceToken.value?.tokenItem {
            router?.userDidTapChangeReceiveTokenButton(tokenItem: sourceToken)
        }
    }

    func userDidTapNetworkFeeInfoButton(_ message: String) {
        alertPresenter.present(alert: .init(title: "", message: message))
    }
}

// MARK: - Private

private extension SwapAmountViewModel {
    private func updateSourceExpressCurrencyState(providersState: SwapModel.ProvidersState) {
        switch providersState {
        case .loaded(_, _, .restriction(.notEnoughBalanceForSwapping, quote: _)):
            sourceExpressCurrencyViewModel.update(errorState: .insufficientFunds)
        case .loaded(_, _, .restriction(.notEnoughAmountForTxValue(_, let isFeeCurrency), _)) where isFeeCurrency,
             .loaded(_, _, .restriction(.notEnoughAmountForFee(let isFeeCurrency), _)) where isFeeCurrency:
            sourceExpressCurrencyViewModel.update(errorState: .insufficientFunds)
        case .loaded(_, _, .restriction(.validationError(.minimumRestrictAmount(let minimumAmount), _), _)):
            let errorText = Localization.transferMinAmountError(minimumAmount.string())
            sourceExpressCurrencyViewModel.update(errorState: .error(errorText))
        default:
            sourceExpressCurrencyViewModel.update(errorState: .none)
        }
    }

    func update(amount: Decimal?) -> SendAmount? {
        try? interactor.update(amount: amount)
    }

    private func updateSource(sourceToken: LoadingResult<SendSourceToken, any Error>) {
        sourceExpressCurrencyViewModel.update(
            wallet: sourceToken.mapValue { $0 as SendGenericToken },
            initialWalletId: .init(tokenItem: initialTokenItem)
        )

        switch sourceToken {
        case .loading:
            sourceExpressCurrencyViewModel.update(fiatAmountState: .loading)

        case .failure:
            let fiatFormatted = balanceFormatter.formatFiatBalance(.zero)
            sourceExpressCurrencyViewModel.update(fiatAmountState: .loaded(text: fiatFormatted))

        case .success(let token):
            sourceDecimalNumberTextFieldViewModel.update(maximumFractionDigits: token.tokenItem.decimalCount)

            let textFieldValue = sourceDecimalNumberTextFieldViewModel.value
            let roundedAmount = textFieldValue?.rounded(scale: token.tokenItem.decimalCount, roundingMode: .down)

            // If we have amount then we should round and update it with new decimalCount
            if roundedAmount != textFieldValue {
                _ = update(amount: roundedAmount)
                sourceDecimalNumberTextFieldViewModel.update(value: roundedAmount)
            }

            sourceExpressCurrencyViewModel.updateFiatValue(expectAmount: roundedAmount, tokenItem: token.tokenItem)
        }
    }

    private func updateSourceFiat(amount: SendAmount?) {
        switch amount {
        case .none:
            let fiatFormatted = balanceFormatter.formatFiatBalance(.zero)
            sourceExpressCurrencyViewModel.update(fiatAmountState: .loaded(text: fiatFormatted))

        case .some(let amount):
            let fiatFormatted = balanceFormatter.formatFiatBalance(amount.fiat)
            sourceExpressCurrencyViewModel.update(fiatAmountState: .loaded(text: fiatFormatted))
        }
    }

    private func updateReceive(amount: LoadingResult<SendAmount, any Error>, receiveToken: LoadingResult<SendReceiveToken, any Error>) {
        receiveExpressCurrencyViewModel.update(
            wallet: receiveToken.mapValue { $0 as SendGenericToken },
            initialWalletId: .init(tokenItem: initialTokenItem)
        )

        switch (receiveToken, amount) {
        case (.loading, _), (_, .loading):
            receiveCryptoAmountState = .loading
            receiveExpressCurrencyViewModel.update(fiatAmountState: .loading)

        case (_, .failure), (.failure, _):
            receiveCryptoAmountState = .loaded(text: "0")

            let fiatFormatted = balanceFormatter.formatFiatBalance(.zero)
            receiveExpressCurrencyViewModel.update(fiatAmountState: .loaded(text: fiatFormatted))

        case (.success(let token), .success(let amount)):
            guard let crypto = amount.crypto else {
                receiveCryptoAmountState = .loaded(text: "0")

                let fiatFormatted = balanceFormatter.formatFiatBalance(.zero)
                receiveExpressCurrencyViewModel.update(fiatAmountState: .loaded(text: fiatFormatted))
                return
            }

            let formatter = DecimalNumberFormatter(maximumFractionDigits: token.tokenItem.decimalCount)
            let cryptoFormatted: String = formatter.format(value: crypto)
            receiveCryptoAmountState = .loaded(text: cryptoFormatted)

            let fiatFormatted = balanceFormatter.formatFiatBalance(amount.fiat)
            receiveExpressCurrencyViewModel.update(fiatAmountState: .loaded(text: fiatFormatted))
        }
    }
}

// MARK: - SendAmountExternalUpdatableViewModel

extension SwapAmountViewModel: SendAmountExternalUpdatableViewModel {
    func externalUpdate(amount: SendAmount?) {
        sourceDecimalNumberTextFieldViewModel.update(value: amount?.crypto)
        updateSourceFiat(amount: amount)
    }
}
