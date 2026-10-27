//
//  PolymarketOrderPreviews.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Previews

#Preview("Yes") {
    PolymarketOrderView(viewModel: .preview(outcomeIndex: 0))
}

#Preview("Single sheet") {
    PolymarketOrderView(viewModel: .preview(outcomeIndex: 1, isSingleSheet: true))
}

#Preview("No — Dark") {
    PolymarketOrderView(viewModel: .preview(outcomeIndex: 1))
        .preferredColorScheme(.dark)
}

@MainActor
private extension PolymarketOrderViewModel {
    static func preview(outcomeIndex: Int, isSingleSheet: Bool = false) -> PolymarketOrderViewModel {
        PolymarketOrderViewModel(
            model: .preview(outcomeIndex: outcomeIndex),
            flowStyle: isSingleSheet
                ? .singleSheet(.init(placementService: PolymarketOrderPreviewPlacementService(), signingButtonType: .holdToConfirm))
                : .summaryStep,
            coordinator: nil
        )
    }
}
