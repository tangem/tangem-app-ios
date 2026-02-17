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
        .sink { $0.updateReceive(amount: $1.0.value, tokenItem: $1.1.value?.tokenItem) }
    }

    private func update(token: LoadingResult<SendReceiveToken, any Error>) {
        expressCurrencyViewModel.update(wallet: token.mapValue { $0 as SendGenericToken }, initialWalletId: initialSourceToken.id)
    }

    private func updateReceive(amount: SendAmount?, tokenItem: TokenItem?) {
        expressCurrencyViewModel.updateFiatValue(expectAmount: amount?.fiat, tokenItem: tokenItem)

        guard let expectAmount = amount?.crypto else {
            update(cryptoAmountState: .loaded(text: "0"))
            return
        }

        let decimals = tokenItem?.decimalCount ?? AppConstants.maximumFractionDigitsForBalance

        let formatter = DecimalNumberFormatter(maximumFractionDigits: decimals)
        let formatted: String = formatter.format(value: expectAmount)
        update(cryptoAmountState: .loaded(text: formatted))
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
