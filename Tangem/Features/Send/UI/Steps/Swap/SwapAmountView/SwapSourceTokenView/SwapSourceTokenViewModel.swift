//
//  SwapSourceTokenViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

class SwapSourceTokenViewModel: ObservableObject, Identifiable {
    @Published private(set) var expressCurrencyViewModel: ExpressCurrencyViewModel
    @Published private(set) var decimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel

    private let initialSourceToken: SendSourceToken
    private var sourceTokenCancellable: AnyCancellable?
    private var sourceTokenAmountCancellable: AnyCancellable?

    init(
        initialSourceToken: SendSourceToken,
        expressCurrencyViewModel: ExpressCurrencyViewModel,
        decimalNumberTextFieldViewModel: DecimalNumberTextFieldViewModel
    ) {
        self.initialSourceToken = initialSourceToken
        self.expressCurrencyViewModel = expressCurrencyViewModel
        self.decimalNumberTextFieldViewModel = decimalNumberTextFieldViewModel
    }

    func textFieldDidTapped() {
        Analytics.log(.swapSendTokenBalanceClicked)
    }

    func bind(sourceInput: SendSourceTokenInput, sourceAmountInput: SendSourceTokenAmountInput) {
        sourceTokenCancellable = sourceInput
            .sourceTokenPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { $0.update(token: $1) }

        sourceTokenAmountCancellable = Publishers.CombineLatest(
            sourceAmountInput.sourceAmountPublisher,
            sourceInput.sourceTokenPublisher
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { $0.updateSendFiatValue(amount: $1.0.value, tokenItem: $1.1.value?.tokenItem) }
    }

    private func update(token: LoadingResult<SendSourceToken, any Error>) {
        expressCurrencyViewModel.update(wallet: token.mapValue { $0 as SendGenericToken }, initialWalletId: initialSourceToken.id)

        if let tokenItem = token.value?.tokenItem {
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
        }
    }

    private func updateSendFiatValue(amount: SendAmount?, tokenItem: TokenItem?) {
        expressCurrencyViewModel.updateFiatValue(expectAmount: amount?.fiat, tokenItem: tokenItem)
    }
}
