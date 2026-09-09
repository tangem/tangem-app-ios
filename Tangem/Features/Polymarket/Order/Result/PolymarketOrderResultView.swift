//
//  PolymarketOrderResultView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct PolymarketOrderResultView: View {
    let viewModel: PolymarketOrderResultViewModel

    var body: some View {
        StatusScreen(
            title: Localization.predictionPlaceResultSuccessTitle,
            actionTitle: Localization.predictionPlaceResultToMain,
            action: { viewModel.handleViewAction(.toMainTapped) }
        )
        .appearance(.success)
    }
}

// MARK: - Previews

#Preview("Result") {
    PolymarketOrderResultView(viewModel: PolymarketOrderResultViewModel(coordinator: nil))
}

#Preview("Result — Dark") {
    PolymarketOrderResultView(viewModel: PolymarketOrderResultViewModel(coordinator: nil))
        .preferredColorScheme(.dark)
}
