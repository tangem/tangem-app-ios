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
    private var sourceTokenAmountOutputCancellable: AnyCancellable?

    private let balanceConverter = BalanceConverter()

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

    func setup(sourceInput: SendSourceTokenInput, sourceTokenAmountOutput: SendSourceTokenAmountOutput) {
        sourceTokenAmountOutputCancellable = Publishers.CombineLatest(
            sourceInput.sourceTokenPublisher.compactMap { $0.value?.tokenItem },
            decimalNumberTextFieldViewModel.valuePublisher
        )
        .withWeakCaptureOf(self)
        .asyncMap { await $0.mapToSendAmount(crypto: $1.1, tokenItem: $1.0) }
        .sink { [weak sourceTokenAmountOutput] amount in
            sourceTokenAmountOutput?.sourceAmountDidChanged(amount: amount)
        }
    }

    private func update(token: LoadingResult<SendSourceToken, any Error>) {
        expressCurrencyViewModel.update(wallet: token.mapValue { $0 as SendGenericToken }, initialWalletId: initialSourceToken.id)

        if let tokenItem = token.value?.tokenItem {
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
        }
    }

    private func updateSendFiatValue(amount: SendAmount?, tokenItem: TokenItem?) {
        expressCurrencyViewModel.updateFiatValue(expectAmount: amount?.crypto, tokenItem: tokenItem)
    }

    private func mapToSendAmount(crypto: Decimal?, tokenItem: TokenItem?) async -> SendAmount? {
        guard let crypto else {
            return nil
        }

        guard let currencyId = tokenItem?.currencyId else {
            return SendAmount(type: .typical(crypto: crypto, fiat: .none))
        }

        do {
            let fiat = try await balanceConverter.convertToFiat(crypto, currencyId: currencyId)
            return SendAmount(type: .typical(crypto: crypto, fiat: fiat))
        } catch {
            return SendAmount(type: .typical(crypto: crypto, fiat: .none))
        }
    }
}
