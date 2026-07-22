//
//  TokenSummaryMetricInfoView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TokenSummaryMetricInfoView: View {
    let viewModel: TokenSummaryMetricInfoViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            Text(viewModel.info)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
        .floatingSheetConfiguration { config in
            config.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            config.backgroundInteractionBehavior = .tapToDismiss
            config.verticalSwipeBehavior = .init(target: .sheet, threshold: 100)
        }
    }

    private var header: some View {
        ZStack {
            Text(viewModel.title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)

            HStack {
                Spacer()

                TangemUI.Button(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonClose,
                    action: viewModel.onClose
                )
                .size(.x11)
                .styleType(.material(.glass))
            }
        }
        .padding(16)
    }
}

// MARK: - Previews

#Preview {
    TokenSummaryMetricInfoView(
        viewModel: TokenSummaryMetricInfoViewModel(
            title: "Galaxy Score",
            info: "An indicator that evaluates the current state of a cryptocurrency based on its market indicators and the dynamics of social sentiment, developed by LunarCrush.",
            onClose: {}
        )
    )
}
