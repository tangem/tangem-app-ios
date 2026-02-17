//
//  SwapAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemLocalization

protocol SwapAmountCompactRoutable: AnyObject {
    func userDidTapChangeSourceTokenButton()
    func userDidTapSwapSourceAndReceiveTokensButton()
    func userDidTapChangeReceiveTokenButton()
}

final class SwapAmountViewModel: ObservableObject, Identifiable {
    @Published private(set) var swapSourceTokenViewModel: SwapSourceTokenViewModel
    @Published private(set) var isSwapButtonLoading: Bool = false
    @Published private(set) var isSwapButtonDisabled: Bool = false
    @Published private(set) var swapReceiveTokenViewModel: SwapReceiveTokenViewModel

    weak var router: SwapAmountCompactRoutable?

    private let initialSourceToken: SendSourceToken
    private var sourceTokenCancellable: AnyCancellable?
    private var receiveTokenCancellable: AnyCancellable?

    init(
        initialSourceToken: SendSourceToken,
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput,
    ) {
        self.initialSourceToken = initialSourceToken

        swapSourceTokenViewModel = SwapSourceTokenViewModel(
            initialSourceToken: initialSourceToken,
            expressCurrencyViewModel: .init(
                viewType: .send,
                headerType: .action(name: Localization.swappingFromTitle),
                canChangeCurrency: sourceTokenInput.sourceToken.value?.tokenItem != initialSourceToken.tokenItem
            ),
            decimalNumberTextFieldViewModel: .init(maximumFractionDigits: sourceTokenInput.sourceToken.value?.tokenItem.decimalCount ?? 0)
        )

        swapReceiveTokenViewModel = SwapReceiveTokenViewModel(
            initialSourceToken: initialSourceToken,
            expressCurrencyViewModel: .init(
                viewType: .receive,
                headerType: .action(name: Localization.swappingToTitle),
                canChangeCurrency: receiveTokenInput.receiveToken.value?.tokenItem != initialSourceToken.tokenItem
            )
        )

        swapSourceTokenViewModel.bind(sourceInput: sourceTokenInput, sourceAmountInput: sourceTokenAmountInput)
        swapReceiveTokenViewModel.bind(receiveTokenInput: receiveTokenInput, receiveTokenAmountInput: receiveTokenAmountInput)
    }

    func userDidTapChangeSourceTokenButton() {
        router?.userDidTapChangeSourceTokenButton()
    }

    func userDidTapSwapSourceAndReceiveTokensButton() {
        router?.userDidTapSwapSourceAndReceiveTokensButton()
    }

    func userDidTapChangeReceiveTokenButton() {
        router?.userDidTapChangeReceiveTokenButton()
    }
}
