//
//  ForYouSwapTokenSelectorViewModel.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class ForYouSwapTokenSelectorViewModel: ObservableObject, Identifiable {
    let tokenSelectorViewModel: TokenSelectorViewModel

    private let onClose: () -> Void

    init(
        direction: TokenSelectorItemSwapAvailabilityProvider.SwapDirection,
        preferredWalletId: UserWalletId?,
        onClose: @escaping () -> Void
    ) {
        self.onClose = onClose

        tokenSelectorViewModel = .swap(
            initialSelectedItem: direction.tokenItem,
            preferredWalletId: preferredWalletId
        )

        tokenSelectorViewModel.setup(directionPublisher: Just(direction).eraseToOptional())
        tokenSelectorViewModel.setup(with: self)
    }

    func close() {
        onClose()
    }
}

extension ForYouSwapTokenSelectorViewModel: TokenSelectorViewModelOutput {
    func userDidSelect(item: TokenSelectorItem) {
        // [REDACTED_TODO_COMMENT]
        onClose()
    }
}
