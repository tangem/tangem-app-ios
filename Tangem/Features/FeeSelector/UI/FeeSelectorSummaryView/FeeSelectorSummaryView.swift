//
//  FeeSelectorSummaryView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAssets

struct FeeSelectorSummaryView: View {
    @ObservedObject var viewModel: FeeSelectorSummaryViewModel
    let shouldShowSummaryBottomButton: Bool

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 8) {
            suggestedFeeCurrency
            suggestedFee
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Sub Views

    @ViewBuilder
    private var suggestedFeeCurrency: some View {
        if let model = viewModel.suggestedFeeCurrency {
            FeeSelectorRowView(viewModel: model)
        }
    }

    @ViewBuilder
    private var suggestedFee: some View {
        if let model = viewModel.suggestedFee {
            FeeSelectorRowView(viewModel: model)
        }
    }
}
