//
//  EthYieldSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

// [REDACTED_TODO_COMMENT]
struct EthYieldSheetView: View {
    let viewModel: EthYieldSheetViewModel

    @ObservedObject private var visibilityState = SensitiveTextVisibilityState.shared

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            ForEach(viewModel.activeRows) { row($0) }

            if !viewModel.inactiveRows.isEmpty {
                Text("Not active yet")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .padding(.horizontal, Constants.sectionTitleHorizontalPadding)
                    .padding(.top, viewModel.activeRows.isEmpty ? .zero : Constants.sectionTitleTopPadding)
                    .accessibilityAddTraits(.isHeader)

                ForEach(viewModel.inactiveRows) { row($0) }
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.bottom, Constants.bottomPadding)
    }

    @ViewBuilder
    private func row(_ item: EthYieldSheetViewModel.RowItem) -> some View {
        switch item.content {
        case .active(let rate, let cryptoBalance, let fiatBalance):
            Row(title: item.name, subtitle: rate)
                .contentLead(.end)
                .titleLineLimit(Constants.labelLineLimit)
                .subtitleLineLimit(Constants.labelLineLimit)
                .overrideTextColors(RowOverrideTextColors(subtitle: DesignSystem.Color.textAccentBlue))
                .valueAccessory {
                    UtilBalance(cryptoBalance)
                        .masked(visibilityState.isHidden)
                        .lineLimit(Constants.labelLineLimit)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
                .subvalueAccessory {
                    UtilBalance(fiatBalance)
                        .masked(visibilityState.isHidden)
                        .lineLimit(Constants.labelLineLimit)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
                .start { icon(item.icon) }
                .end { chevron }
                .onTap(action: item.action)
        case .inactive(let rate, let risk):
            Row(title: item.name, value: rate, subvalue: "Start earning")
                .contentLead(.end)
                .titleLineLimit(Constants.labelLineLimit)
                .valueLineLimit(Constants.labelLineLimit)
                .subvalueLineLimit(Constants.labelLineLimit)
                .overrideTextColors(RowOverrideTextColors(value: DesignSystem.Color.textAccentBlue))
                .subtitleAccessory {
                    Badge(label: risk, accessibilityLabel: nil)
                        .appearance(.success)
                        .size(.x4)
                }
                .start { icon(item.icon) }
                .end { chevron }
                .onTap(action: item.action)
        }
    }

    @ViewBuilder
    private func icon(_ icon: EthYieldSheetViewModel.Icon) -> some View {
        switch icon {
        case .logo(let logo):
            Avatar(.asset(logo.image), size: .size40)
                .accessibilityHidden(true)
        case .illustration(let illustration):
            EarnIllustrationView(illustration: illustration)
        }
    }

    private var chevron: some View {
        DesignSystem.Icons.ChevronRight.regular20.image
            .renderingMode(.template)
            .flipsForRightToLeftLayoutDirection(true)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension EthYieldSheetView {
    enum Constants {
        static let horizontalPadding: CGFloat = 8
        static let bottomPadding: CGFloat = 16
        static let sectionTitleHorizontalPadding: CGFloat = 8
        static let sectionTitleTopPadding: CGFloat = 8
        static let labelLineLimit = 2
    }
}
