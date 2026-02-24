//
//  SendAmountFinishViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemUI
import TangemFoundation
import TangemExpress

class SendAmountFinishViewModel: ObservableObject, Identifiable {
    var viewType: ViewType { getViewType() }

    @Published private var tokenHeader: SendTokenHeader
    @Published private var tokenIconInfo: TokenIconInfo
    @Published private var amountDecimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel
    @Published private var amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published private var alternativeAmount: String?

    @Published private var receiveSmallAmountViewModel: SendAmountFinishSmallAmountViewModel?
    @Published private var sendSwapProviderFinishViewModel: SendSwapProviderFinishViewModel?

    private let prefixSuffixOptionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory()
    private var bag: Set<AnyCancellable> = []

    init(
        initialSourceToken: SendSourceToken,
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput? = nil,
        receiveTokenAmountInput: SendReceiveTokenAmountInput? = nil,
        swapProvidersInput: SendSwapProvidersInput? = nil,
    ) {
        tokenHeader = initialSourceToken.header
        tokenIconInfo = initialSourceToken.tokenIconInfo
        amountDecimalNumberTextFieldViewModel = .init(maximumFractionDigits: initialSourceToken.tokenItem.decimalCount)
        amountFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(
            cryptoCurrencyCode: initialSourceToken.tokenItem.currencySymbol
        )
        alternativeAmount = sourceTokenAmountInput.sourceAmount.value?.formatAlternative(
            currencySymbol: initialSourceToken.tokenItem.currencySymbol,
            decimalCount: initialSourceToken.tokenItem.decimalCount
        )

        bind(
            sourceTokenInput: sourceTokenInput,
            sourceTokenAmountInput: sourceTokenAmountInput,
            receiveTokenInput: receiveTokenInput,
            receiveTokenAmountInput: receiveTokenAmountInput,
            swapProvidersInput: swapProvidersInput
        )
    }
}

// MARK: - Private

private extension SendAmountFinishViewModel {
    func getViewType() -> ViewType {
        guard let receiveSmallAmountViewModel, let sendSwapProviderFinishViewModel else {
            return .one(
                .init(
                    tokenHeader: tokenHeader,
                    tokenIconInfo: tokenIconInfo,
                    amountDecimalNumberTextFieldViewModel: amountDecimalNumberTextFieldViewModel,
                    amountFieldOptions: amountFieldOptions,
                    alternativeAmount: alternativeAmount
                )
            )
        }

        return .double(
            source: .init(
                tokenHeader: tokenHeader,
                tokenIconInfo: tokenIconInfo,
                amountDecimalNumberTextFieldViewModel: amountDecimalNumberTextFieldViewModel,
                amountFieldOptions: amountFieldOptions,
                alternativeAmount: alternativeAmount
            ),
            destination: receiveSmallAmountViewModel,
            provider: sendSwapProviderFinishViewModel
        )
    }

    func bind(
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput?,
        receiveTokenAmountInput: SendReceiveTokenAmountInput?,
        swapProvidersInput: SendSwapProvidersInput?
    ) {
        Publishers.CombineLatest(
            sourceTokenInput.sourceTokenPublisher.compactMap { $0.value },
            sourceTokenAmountInput.sourceAmountPublisher
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { $0.updateView(sourceToken: $1.0, sourceAmount: $1.1) }
        .store(in: &bag)

        guard let receiveTokenInput, let receiveTokenAmountInput, let swapProvidersInput else {
            return
        }

        Publishers.CombineLatest(
            receiveTokenInput.receiveTokenPublisher,
            receiveTokenAmountInput.receiveAmountPublisher
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { $0.updateView(receiveToken: $1.0.value, receiveAmount: $1.1) }
        .store(in: &bag)

        Publishers.CombineLatest(
            sourceTokenInput.sourceTokenPublisher.compactMap { $0.value },
            swapProvidersInput.selectedExpressProviderPublisher.map { $0?.value },
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { $0.updateView(sourceToken: $1.0, provider: $1.1) }
        .store(in: &bag)
    }

    private func updateView(sourceToken: SendSourceToken, sourceAmount: LoadingResult<SendAmount, any Error>) {
        tokenIconInfo = sourceToken.tokenIconInfo
        amountDecimalNumberTextFieldViewModel = .init(maximumFractionDigits: sourceToken.tokenItem.decimalCount)
        alternativeAmount = sourceAmount.value?.formatAlternative(
            currencySymbol: sourceToken.tokenItem.currencySymbol,
            decimalCount: sourceToken.tokenItem.decimalCount
        )

        switch sourceAmount.value?.type {
        case .typical(let crypto, _):
            amountFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(
                cryptoCurrencyCode: sourceToken.tokenItem.currencySymbol
            )
            amountDecimalNumberTextFieldViewModel.update(value: crypto)
        case .alternative(let fiat, _):
            amountFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(
                fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode
            )
            amountDecimalNumberTextFieldViewModel.update(value: fiat)
        case nil:
            break
        }
    }

    private func updateView(receiveToken: SendReceiveToken?, receiveAmount: LoadingResult<SendAmount, any Error>) {
        switch (receiveToken, receiveAmount) {
        case (.none, _):
            receiveSmallAmountViewModel = nil
        case (.some(let token), .success(let receiveAmount)):
            let textField = DecimalNumberTextFieldViewModel(
                maximumFractionDigits: token.tokenItem.decimalCount
            )
            textField.update(value: receiveAmount.crypto)

            receiveSmallAmountViewModel = .init(
                tokenHeader: tokenHeader,
                tokenIconInfo: token.tokenIconInfo,
                amountDecimalNumberTextFieldViewModel: textField,
                amountFieldOptions: prefixSuffixOptionsFactory.makeCryptoOptions(
                    cryptoCurrencyCode: token.tokenItem.currencySymbol
                ),
                alternativeAmount: receiveAmount.formatAlternative(
                    currencySymbol: token.tokenItem.currencySymbol,
                    decimalCount: token.tokenItem.decimalCount
                )
            )
        case (.some, .failure), (.some, .loading):
            // Do nothing to avoid incorrect view state
            break
        }
    }

    private func updateView(sourceToken: SendSourceToken, provider: ExpressAvailableProvider?) {
        guard let provider else {
            sendSwapProviderFinishViewModel = nil
            return
        }

        sendSwapProviderFinishViewModel = .init(tokenItem: sourceToken.tokenItem, provider: provider)
    }
}

extension SendAmountFinishViewModel {
    enum ViewType {
        case one(SendAmountFinishLargeAmountViewModel)
        case double(
            source: SendAmountFinishSmallAmountViewModel,
            destination: SendAmountFinishSmallAmountViewModel,
            provider: SendSwapProviderFinishViewModel
        )
    }
}
