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

    init(
        initialTokenItem: TokenItem,
        sourceTokenInput: SendSourceTokenInput,
        receiveTokenInput: SendReceiveTokenInput
    ) {
        swapSourceTokenViewModel = SwapSourceTokenViewModel(
            expressCurrencyViewModel: .init(
                viewType: .send,
                headerType: .action(name: Localization.swappingFromTitle),
                canChangeCurrency: sourceTokenInput.sourceToken.value?.tokenItem != initialTokenItem
            ),
            decimalNumberTextFieldViewModel: .init(maximumFractionDigits: sourceTokenInput.sourceToken.value?.tokenItem.decimalCount ?? 0)
        )

        swapReceiveTokenViewModel = SwapReceiveTokenViewModel(
            expressCurrencyViewModel: .init(
                viewType: .receive,
                headerType: .action(name: Localization.swappingToTitle),
                canChangeCurrency: receiveTokenInput.receiveToken.value?.tokenItem != initialTokenItem
            )
        )

        bind(sourceTokenInput: sourceTokenInput, receiveTokenInput: receiveTokenInput)
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

    func bind(sourceTokenInput: SendSourceTokenInput, receiveTokenInput: SendReceiveTokenInput) {
        // [REDACTED_TODO_COMMENT]
    }
}
