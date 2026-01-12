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
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                suggestedFeeCurrency
                suggestedFee
            }

            if shouldShowSummaryBottomButton {
                button
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
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

    private var button: some View {
        MainButton(settings: .init(title: Localization.commonConfirm, style: .primary, action: viewModel.userDidTapConfirm))
    }
}
