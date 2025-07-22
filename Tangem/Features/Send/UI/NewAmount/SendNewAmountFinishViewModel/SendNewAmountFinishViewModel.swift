//
//  SendNewAmountFinishViewModel.swift
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

class SendNewAmountFinishViewModel: ObservableObject, Identifiable {
    var viewType: ViewType { getViewType() }

    @Published private var walletName: String
    @Published private var tokenIconInfo: TokenIconInfo
    @Published private var amountDecimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published private var amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published private var alternativeAmount: String?

    @Published private var receiveSmallAmountViewModel: SendNewAmountFinishSmallAmountViewModel?
    @Published private var sendSwapProviderFinishViewModel: SendSwapProviderFinishViewModel?

    private let prefixSuffixOptionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory()
    private var bag: Set<AnyCancellable> = []

    init(
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput,
        swapProvidersInput: SendSwapProvidersInput,
    ) {
        walletName = sourceTokenInput.sourceToken.wallet
        tokenIconInfo = sourceTokenInput.sourceToken.tokenIconInfo
        amountDecimalNumberTextFieldViewModel = .init(maximumFractionDigits: sourceTokenInput.sourceToken.tokenItem.decimalCount)
        amountFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(
            cryptoCurrencyCode: sourceTokenInput.sourceToken.tokenItem.currencySymbol
        )
        alternativeAmount = sourceTokenAmountInput.sourceAmount.value??.formatAlternative(
            currencySymbol: sourceTokenInput.sourceToken.tokenItem.currencySymbol,
            decimalCount: sourceTokenInput.sourceToken.tokenItem.decimalCount
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

private extension SendNewAmountFinishViewModel {
    func getViewType() -> ViewType {
        guard let receiveSmallAmountViewModel, let sendSwapProviderFinishViewModel else {
            return .one(
                .init(
                    tokenIconInfo: tokenIconInfo,
                    amountDecimalNumberTextFieldViewModel: amountDecimalNumberTextFieldViewModel,
                    amountFieldOptions: amountFieldOptions,
                    alternativeAmount: alternativeAmount
                )
            )
        }

        return .double(
            source: .init(
                title: walletName,
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
        receiveTokenInput: SendReceiveTokenInput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput,
        swapProvidersInput: SendSwapProvidersInput
    ) {
        Publishers.CombineLatest(
            sourceTokenInput.sourceTokenPublisher,
            sourceTokenAmountInput.sourceAmountPublisher
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { $0.updateView(sourceToken: $1.0, sourceAmount: $1.1) }
        .store(in: &bag)

        Publishers.CombineLatest(
            receiveTokenInput.receiveTokenPublisher,
            receiveTokenAmountInput.receiveAmountPublisher
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { $0.updateView(receiveToken: $1.0, receiveAmount: $1.1) }
        .store(in: &bag)

        Publishers.CombineLatest(
            sourceTokenInput.sourceTokenPublisher,
            swapProvidersInput.selectedExpressProviderPublisher,
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { $0.updateView(sourceToken: $1.0, provider: $1.1) }
        .store(in: &bag)
    }

    private func updateView(sourceToken: SendSourceToken, sourceAmount: LoadingResult<SendAmount?, any Error>) {
        tokenIconInfo = sourceToken.tokenIconInfo
        amountDecimalNumberTextFieldViewModel = .init(maximumFractionDigits: sourceToken.tokenItem.decimalCount)
        alternativeAmount = sourceAmount.value??.formatAlternative(
            currencySymbol: sourceToken.tokenItem.currencySymbol,
            decimalCount: sourceToken.tokenItem.decimalCount
        )

        switch sourceAmount.value??.type {
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

    private func updateView(receiveToken: SendReceiveTokenType, receiveAmount: LoadingResult<SendAmount?, any Error>) {
        switch receiveToken {
        case .same:
            receiveSmallAmountViewModel = nil
        case .swap(let token):
            let textField = DecimalNumberTextField.ViewModel(
                maximumFractionDigits: token.tokenItem.decimalCount
            )
            textField.update(value: receiveAmount.value??.crypto)

            receiveSmallAmountViewModel = .init(
                title: token.wallet,
                tokenIconInfo: token.tokenIconInfo,
                amountDecimalNumberTextFieldViewModel: textField,
                amountFieldOptions: prefixSuffixOptionsFactory.makeCryptoOptions(
                    cryptoCurrencyCode: token.tokenItem.currencySymbol
                ),
                alternativeAmount: receiveAmount.value??.formatAlternative(
                    currencySymbol: token.tokenItem.currencySymbol,
                    decimalCount: token.tokenItem.decimalCount
                )
            )
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

extension SendNewAmountFinishViewModel {
    enum ViewType {
        case one(SendNewAmountFinishLargeAmountViewModel)
        case double(
            source: SendNewAmountFinishSmallAmountViewModel,
            destination: SendNewAmountFinishSmallAmountViewModel,
            provider: SendSwapProviderFinishViewModel
        )
    }
}
