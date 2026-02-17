//
//  SwapReceiveTokenViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

class SwapReceiveTokenViewModel: ObservableObject, Identifiable {
    @Published private(set) var expressCurrencyViewModel: ExpressCurrencyViewModel
    @Published private(set) var cryptoAmountState: LoadableTextView.State

    private let initialSourceToken: SendSourceToken
    private var receiveTokenCancellable: AnyCancellable?
    private var receiveTokenAmountCancellable: AnyCancellable?

    init(
        initialSourceToken: SendSourceToken,
        expressCurrencyViewModel: ExpressCurrencyViewModel,
        cryptoAmountState: LoadableTextView.State = .initialized
    ) {
        self.initialSourceToken = initialSourceToken
        self.expressCurrencyViewModel = expressCurrencyViewModel
        self.cryptoAmountState = cryptoAmountState
    }

    func bind(receiveTokenInput: SendReceiveTokenInput, receiveTokenAmountInput: SendReceiveTokenAmountInput) {
        receiveTokenCancellable = receiveTokenInput
            .receiveTokenPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { $0.update(token: $1) }

        receiveTokenAmountCancellable = Publishers.CombineLatest(
            receiveTokenAmountInput.receiveAmountPublisher,
            receiveTokenInput.receiveTokenPublisher
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { $0.updateReceive(amount: $1.0, sourceToken: $1.1) }
    }

    private func update(token: LoadingResult<SendReceiveToken, any Error>) {
        expressCurrencyViewModel.update(wallet: token.mapValue { $0 as SendGenericToken }, initialWalletId: initialSourceToken.id)
    }

    private func updateReceive(amount: LoadingResult<SendAmount, any Error>, sourceToken: LoadingResult<SendReceiveToken, any Error>) {
        switch (sourceToken, amount) {
        case (.loading, _), (_, .loading):
            update(cryptoAmountState: .loading)
            expressCurrencyViewModel.update(fiatAmountState: .loading)

        case (_, .failure), (.failure, _):
            update(cryptoAmountState: .loaded(text: "0"))
            expressCurrencyViewModel.updateFiatValue(expectAmount: .none, tokenItem: .none)

        case (.success(let token), .success(let amount)):
            guard let crypto = amount.crypto else {
                update(cryptoAmountState: .loaded(text: "0"))
                expressCurrencyViewModel.updateFiatValue(expectAmount: .none, tokenItem: .none)
                return
            }

            let formatter = DecimalNumberFormatter(maximumFractionDigits: token.tokenItem.decimalCount)
            let formatted: String = formatter.format(value: crypto)

            update(cryptoAmountState: .loaded(text: formatted))
            expressCurrencyViewModel.updateFiatValue(expectAmount: amount.fiat, tokenItem: token.tokenItem)
        }
    }

    private func update(cryptoAmountState: LoadableTextView.State) {
        self.cryptoAmountState = cryptoAmountState
    }
}

extension SwapReceiveTokenViewModel {
    enum State: Hashable {
        case idle
        case loading
        case formatted(_ value: String)
    }
}
