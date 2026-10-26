//
//  SwapSummarySlippageViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class SwapSummarySlippageViewModel: ObservableObject {
    @Published private(set) var isVisible = false
    @Published private(set) var isEditable = false
    @Published private(set) var value: Value = .auto(isHighlighted: false)

    init(
        swapProvidersInput: SendSwapProvidersInput,
        slippageInput: SwapSlippageInput,
        percentFormatter: PercentFormatter = PercentFormatter()
    ) {
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

        slippageInput.providerSlippagePublisher
            .map { $0 != nil }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$isEditable)

        Publishers.CombineLatest(slippageInput.slippagePublisher, slippageInput.isCustomSlippageResetPublisher)
            .map { [percentFormatter] slippage, isReset in
                switch slippage {
                case .auto: .auto(isHighlighted: isReset)
                case .custom(let value): .custom(percentFormatter.format(value, option: .customSlippage))
                }
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$value)
    }
}

// MARK: - Value

extension SwapSummarySlippageViewModel {
    enum Value: Hashable {
        case auto(isHighlighted: Bool)
        case custom(String)
    }
}
