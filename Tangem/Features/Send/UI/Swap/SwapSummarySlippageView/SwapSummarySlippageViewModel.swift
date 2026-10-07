//
//  SwapSummarySlippageViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class SwapSummarySlippageViewModel: ObservableObject {
    @Published private(set) var isVisible = false

    let isCustomSlippageAvailable: Bool

    init(swapProvidersInput: SendSwapProvidersInput, isCustomSlippageAvailable: Bool) {
        self.isCustomSlippageAvailable = isCustomSlippageAvailable

        guard isCustomSlippageAvailable else {
            return
        }

        swapProvidersInput.selectedExpressProviderPublisher
            .map { provider in
                switch provider {
                case .success, .loading: true
                case .none, .failure: false
                }
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$isVisible)
    }
}
