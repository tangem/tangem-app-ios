//
//  PolymarketSlippageSelectorPreviews.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

// MARK: - Previews

#Preview("Default") {
    PolymarketSlippageSelectorPreviewHost(viewModel: PolymarketSlippageSelectorViewModel(onConfirm: { _ in }))
}

#Preview("Above the ceiling") {
    PolymarketSlippageSelectorPreviewHost(viewModel: PolymarketSlippageSelectorViewModel(percent: 42, onConfirm: { _ in }))
}

#Preview("Below the floor — Dark") {
    PolymarketSlippageSelectorPreviewHost(viewModel: PolymarketSlippageSelectorViewModel(percent: 0.05, onConfirm: { _ in }))
        .preferredColorScheme(.dark)
}

private struct PolymarketSlippageSelectorPreviewHost: View {
    let viewModel: PolymarketSlippageSelectorViewModel

    var body: some View {
        Color.clear.modal(
            isPresented: .constant(true),
            title: Localization.predictionPlaceSlippage,
            content: { PolymarketSlippageSelectorView(viewModel: viewModel) },
            footer: { PolymarketSlippageSelectorFooterView(viewModel: viewModel) }
        )
    }
}
