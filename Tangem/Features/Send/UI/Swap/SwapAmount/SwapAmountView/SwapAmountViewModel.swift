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
    func userDidTapChangeSourceTokenButton(receiveToken: SendSourceToken?)
    func userDidTapSwapSourceAndReceiveTokensButton()
    func userDidTapChangeReceiveTokenButton(sourceToken: SendSourceToken?)
}

final class SwapAmountViewModel: ObservableObject, Identifiable {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    @Published private(set) var sourceExpressCurrencyViewModel: ExpressCurrencyViewModel
    @Published private(set) var sourceCryptoDecimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel
    @Published private(set) var sourceFiatDecimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel
    @Published private(set) var sourceFiatFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published private(set) var sourceCalculationType: SendAmountCalculationType = .crypto
    @Published private(set) var isSwapButtonDisabled: Bool = false
    @Published private(set) var isInputDisabled: Bool = true
    @Published private(set) var receiveExpressCurrencyViewModel: ExpressCurrencyViewModel
    @Published private(set) var receiveCryptoAmountState: LoadableTextView.State = .initialized

    var sourceAmountInputPublisher: AnyPublisher<Decimal?, Never> {
        Publishers.Merge(
            sourceCryptoDecimalNumberTextFieldViewModel.valuePublisher(),
            sourceFiatDecimalNumberTextFieldViewModel.valuePublisher()
        )
        .eraseToAnyPublisher()
    }

    weak var router: SwapAmountCompactRoutable?

    private let initialTokenItem: TokenItem
    private let interactor: SendAmountInteractor

    private weak var stateProvider: SwapModelStateProvider?
    private weak var sourceTokenInput: SendSourceTokenInput?
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()
    private let prefixSuffixOptionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory()

    private var sourceExpressCurrencyStateCancellable: AnyCancellable?
    private var sourceTokenCancellable: AnyCancellable?
    private var sourceTokenAmountCancellable: AnyCancellable?
    private var sourceFiatAmountCancellable: AnyCancellable?

    private var isInputDisabledCancellable: AnyCancellable?

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

        sourceCryptoDecimalNumberTextFieldViewModel = .init(
            maximumFractionDigits: sourceTokenInput.sourceToken.value?.tokenItem.decimalCount ?? 0
        )

        let fiatItem = sourceTokenInput.sourceToken.value?.fiatItem
        sourceFiatDecimalNumberTextFieldViewModel = .init(maximumFractionDigits: fiatItem?.fractionDigits ?? 2)
        sourceFiatFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(
            fiatCurrencyCode: fiatItem?.currencyCode ?? AppSettings.shared.selectedCurrencyCode
        )

        receiveExpressCurrencyViewModel = .init(
            viewType: .receive,
            headerType: .action(name: Localization.swappingToTitle),
            canChangeCurrency: receiveTokenInput?.receiveToken.value?.tokenItem != initialTokenItem
        )

        receiveCryptoAmountState = .initialized

        bind(stateProvider: stateProvider)
    }

    func bind(stateProvider: SwapModelStateProvider) {
        // Buttons updating
        interactor.receivedTokenPublisher
            .map { result in
                result.isLoading
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$isSwapButtonDisabled)

        sourceExpressCurrencyStateCancellable = stateProvider.statePublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateSourceExpressCurrencyState(providersState: $1) }

        isInputDisabledCancellable = Publishers.CombineLatest3(
            interactor.sourceTokenPublisher,
            interactor.receivedTokenPublisher,
            stateProvider.statePublisher
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { $0.updateExpressCurrencyInputEnabledState(sourceToken: $1.0, receiveToken: $1.1, providersState: $1.2) }

        // Source token / amount updating

        sourceTokenCancellable = interactor.sourceTokenPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateSource(sourceToken: $1) }

        sourceTokenAmountCancellable = sourceCryptoDecimalNumberTextFieldViewModel
            .valuePublisher(zeroPolicy: .mapToNone)
            .prepend(.none)
            .withWeakCaptureOf(self)
            .filter { viewModel, _ in viewModel.sourceCalculationType == .crypto }
            .map { $0.update(amount: $1) }
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateSourceAlternativeAmount(amount: $1) }

        sourceFiatAmountCancellable = sourceFiatDecimalNumberTextFieldViewModel
            .valuePublisher(zeroPolicy: .mapToNone)
            .withWeakCaptureOf(self)
            .filter { viewModel, _ in viewModel.sourceCalculationType == .fiat }
            .map { $0.update(amount: $1) }
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateSourceAlternativeAmount(amount: $1) }

        // Receive token / amount updating

        receiveTokenCancellable = Publishers.CombineLatest3(
            interactor.receivedTokenAmountPublisher,
            interactor.receivedTokenPublisher,
            interactor.isReceiveAmountApproximatePublisher.prepend(true)
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { $0.updateReceive(amount: $1.0, receiveToken: $1.1, isApproximate: $1.2) }

        highPriceImpactCancellable = interactor
            .highPriceImpactPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.receiveExpressCurrencyViewModel.updateHighPricePercentLabel(highPriceImpact: $1) }
    }

    func textFieldDidTap() {
        Analytics.log(.swapSendTokenBalanceClicked)
    }

    func userDidTapChangeSourceTokenButton() {
        let receiveToken = receiveTokenInput?.receiveToken.value as? SendSourceToken
        router?.userDidTapChangeSourceTokenButton(receiveToken: receiveToken)
    }

    func userDidTapSwapSourceAndReceiveTokensButton() {
        Analytics.log(.swapButtonSwipe)
        router?.userDidTapSwapSourceAndReceiveTokensButton()
    }

    func userDidTapChangeReceiveTokenButton() {
        let sourceToken = sourceTokenInput?.sourceToken.value
        router?.userDidTapChangeReceiveTokenButton(sourceToken: sourceToken)
    }

    func userDidTapNetworkFeeInfoButton(_ message: String) {
        alertPresenter.present(alert: .init(title: "", message: message))
    }

    func userDidTapSwitchCurrencyButton() {
        FeedbackGenerator.heavy()
        update(sourceCalculationType: sourceCalculationType == .crypto ? .fiat : .crypto)
    }

    func update(isReceiveFiatHidden: Bool) {
        receiveExpressCurrencyViewModel.update(isFiatAmountHidden: isReceiveFiatHidden)
    }
}

// MARK: - Private

private extension SwapAmountViewModel {
    func updateSourceExpressCurrencyState(providersState: SwapModel.ProvidersState) {
        switch providersState {
        case .loaded(_, .restriction(.notEnoughBalanceForSwapping, quote: _)):
            sourceExpressCurrencyViewModel.update(errorState: .insufficientFunds)
        case .loaded(_, .restriction(.notEnoughAmountForTxValue(_, let isFeeCurrency), _)) where isFeeCurrency,
             .loaded(_, .restriction(.notEnoughAmountForFee(let isFeeCurrency), _)) where isFeeCurrency:
            sourceExpressCurrencyViewModel.update(errorState: .insufficientFunds)
        case .loaded(_, .restriction(.validationError(.minimumRestrictAmount(let minimumAmount)), _)):
            let errorText = Localization.transferMinAmountError(minimumAmount.string())
            sourceExpressCurrencyViewModel.update(errorState: .error(errorText))
        default:
            sourceExpressCurrencyViewModel.update(errorState: .none)
        }
    }

    func updateExpressCurrencyInputEnabledState(
        sourceToken: LoadingResult<SendSourceToken, Error>,
        receiveToken: LoadingResult<SendReceiveToken, Error>,
        providersState: SwapModel.ProvidersState
    ) {
        switch (sourceToken, receiveToken, providersState) {
        case (.success, .success, .loaded(.swap(_, let providers), .idle)):
            isInputDisabled = providers.isEmpty
        case (_, .failure, _), (.failure, _, _):
            isInputDisabled = true
        default:
            isInputDisabled = false
        }
    }

    func update(amount: Decimal?) -> SendAmount? {
        try? interactor.update(sourceAmount: amount)
    }

    func update(sourceCalculationType newType: SendAmountCalculationType) {
        guard sourceCalculationType != newType else {
            return
        }

        sourceCalculationType = newType
        sourceExpressCurrencyViewModel.cancelPendingFiatConversion()

        let amount = try? interactor.update(sourceType: newType)
        sourceCryptoDecimalNumberTextFieldViewModel.update(value: amount?.crypto)
        sourceFiatDecimalNumberTextFieldViewModel.update(value: amount?.fiat)
        updateSourceAlternativeAmount(amount: amount)
    }

    func updateSource(sourceToken: LoadingResult<SendSourceToken, any Error>) {
        sourceExpressCurrencyViewModel.update(wallet: sourceToken.mapValue { $0 as SendGenericToken })

        switch sourceToken {
        case .loading:
            sourceExpressCurrencyViewModel.update(isSwitchCurrencyAvailable: false)
            sourceExpressCurrencyViewModel.update(alternativeAmountState: .loading)

        case .failure:
            update(sourceCalculationType: .crypto)
            sourceExpressCurrencyViewModel.update(isSwitchCurrencyAvailable: false)

            let fiatFormatted = balanceFormatter.formatFiatBalance(.zero)
            sourceExpressCurrencyViewModel.update(alternativeAmountState: .loaded(text: fiatFormatted))

        case .success(let token):
            let isSwitchCurrencyAvailable = FeatureProvider.isAvailable(.swapFiatCalculation) && token.possibleToConvertToFiat
            sourceExpressCurrencyViewModel.update(isSwitchCurrencyAvailable: isSwitchCurrencyAvailable)

            if !isSwitchCurrencyAvailable {
                update(sourceCalculationType: .crypto)
            }

            sourceCryptoDecimalNumberTextFieldViewModel.update(maximumFractionDigits: token.tokenItem.decimalCount)
            sourceFiatDecimalNumberTextFieldViewModel.update(maximumFractionDigits: token.fiatItem.fractionDigits)
            sourceFiatFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(fiatCurrencyCode: token.fiatItem.currencyCode)

            switch sourceCalculationType {
            case .crypto:
                let textFieldValue = sourceCryptoDecimalNumberTextFieldViewModel.value
                let roundedAmount = textFieldValue?.rounded(scale: token.tokenItem.decimalCount, roundingMode: .down)

                // If we have amount then we should round and update it with new decimalCount
                if roundedAmount != textFieldValue {
                    _ = update(amount: roundedAmount)
                    sourceCryptoDecimalNumberTextFieldViewModel.update(value: roundedAmount)
                }

                sourceExpressCurrencyViewModel.updateFiatValue(expectAmount: roundedAmount, tokenItem: token.tokenItem)

            case .fiat:
                let fiatValue = sourceFiatDecimalNumberTextFieldViewModel.value

                // The nil pass invalidates the interactor's fiat-to-crypto conversion cache,
                // which would otherwise return the previous token's crypto amount
                _ = update(amount: nil)
                let amount = update(amount: fiatValue)

                sourceCryptoDecimalNumberTextFieldViewModel.update(value: amount?.crypto)
                updateSourceAlternativeAmount(amount: amount)
            }
        }
    }

    func updateSourceAlternativeAmount(amount: SendAmount?) {
        switch sourceCalculationType {
        case .crypto:
            let fiatFormatted = switch amount {
            case .none: balanceFormatter.formatFiatBalance(.zero)
            case .some(let amount): balanceFormatter.formatFiatBalance(amount.fiat)
            }

            sourceExpressCurrencyViewModel.update(alternativeAmountState: .loaded(text: fiatFormatted))

        case .fiat:
            let tokenItem = sourceTokenInput?.sourceToken.value?.tokenItem ?? initialTokenItem
            let formatter = DecimalNumberFormatter(maximumFractionDigits: tokenItem.decimalCount)
            let cryptoFormatted: String = formatter.format(value: amount?.crypto ?? .zero)
            sourceExpressCurrencyViewModel.update(alternativeAmountState: .loaded(text: cryptoFormatted))
        }
    }

    func updateReceive(
        amount: LoadingResult<SendAmount, any Error>,
        receiveToken: LoadingResult<SendReceiveToken, any Error>,
        isApproximate: Bool
    ) {
        receiveExpressCurrencyViewModel.update(wallet: receiveToken.mapValue { $0 as SendGenericToken })

        switch (receiveToken, amount) {
        case (.loading, _), (_, .loading):
            receiveCryptoAmountState = .loading
            receiveExpressCurrencyViewModel.update(alternativeAmountState: .loading)

        case (_, .failure), (.failure, _):
            receiveCryptoAmountState = .loaded(text: SwapAmountFormatter.formatAmount("0", isApproximate: isApproximate))

            let fiatFormatted = balanceFormatter.formatFiatBalance(.zero)
            receiveExpressCurrencyViewModel.update(alternativeAmountState: .loaded(text: fiatFormatted))

        case (.success(let token), .success(let amount)):
            guard let crypto = amount.crypto else {
                receiveCryptoAmountState = .loaded(text: SwapAmountFormatter.formatAmount("0", isApproximate: isApproximate))

                let fiatFormatted = balanceFormatter.formatFiatBalance(.zero)
                receiveExpressCurrencyViewModel.update(alternativeAmountState: .loaded(text: fiatFormatted))
                return
            }

            let formatter = DecimalNumberFormatter(maximumFractionDigits: token.tokenItem.decimalCount)
            let cryptoFormatted: String = formatter.format(value: crypto)
            receiveCryptoAmountState = .loaded(text: SwapAmountFormatter.formatAmount(cryptoFormatted, isApproximate: isApproximate))

            let fiatFormatted = balanceFormatter.formatFiatBalance(amount.fiat)
            receiveExpressCurrencyViewModel.update(alternativeAmountState: .loaded(text: fiatFormatted))
        }
    }
}

// MARK: - SendAmountExternalUpdatableViewModel

extension SwapAmountViewModel: SendAmountExternalUpdatableViewModel {
    func externalUpdate(amount: SendAmount?) {
        sourceCryptoDecimalNumberTextFieldViewModel.update(value: amount?.crypto)
        sourceFiatDecimalNumberTextFieldViewModel.update(value: amount?.fiat)
        updateSourceAlternativeAmount(amount: amount)
    }
}
