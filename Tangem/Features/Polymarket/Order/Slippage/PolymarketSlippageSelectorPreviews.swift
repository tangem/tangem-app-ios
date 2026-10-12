//
//  PolymarketSlippageSelectorPreviews.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Previews

#Preview("Default") {
    PolymarketSlippageSelectorView(
        viewModel: PolymarketSlippageSelectorViewModel(onConfirm: { _ in })
    )
}

#Preview("Above the ceiling") {
    PolymarketSlippageSelectorView(
        viewModel: PolymarketSlippageSelectorViewModel(percent: 42, onConfirm: { _ in })
    )
}

#Preview("Below the floor — Dark") {
    PolymarketSlippageSelectorView(
        viewModel: PolymarketSlippageSelectorViewModel(percent: 0.05, onConfirm: { _ in })
    )
    .preferredColorScheme(.dark)
}
