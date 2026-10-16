//
//  YieldModuleAboutApyV2View.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAssets

struct YieldModuleAboutApyV2View: View {
    private let viewModel: YieldModuleAboutApyViewModel

    init(viewModel: YieldModuleAboutApyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            header

            description

            apyBreakdownSection
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            configuration.backgroundInteractionBehavior = .tapToDismiss
            configuration.verticalSwipeBehavior = .init(target: .sheet, threshold: Constants.swipeDismissThreshold)
        }
    }

    private var header: some View {
        ZStack {
            Text(Localization.yieldModuleAboutApySheetTitle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)

            HStack {
                Spacer()

                TangemUI.Button(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonClose,
                    action: viewModel.onCloseTap
                )
                .size(.x11)
                .styleType(.material(.glass))
            }
        }
        .padding(Constants.headerPadding)
    }

    private var description: some View {
        Text(Localization.yieldModuleAboutApySheetSubtitle)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.descriptionHorizontalPadding)
            .padding(.vertical, Constants.descriptionVerticalPadding)
    }

    private var apyBreakdownSection: some View {
        VStack(spacing: .zero) {
            breakdownRow(title: Localization.yieldModuleAboutApyBaseYieldTitle, value: viewModel.baseApyText, showsDivider: true)

            breakdownRow(title: Localization.yieldModuleAboutApyExtraRewardsTitle, value: viewModel.rewardsApyText)
        }
    }

    private func breakdownRow(title: String, value: String, showsDivider: Bool = false) -> some View {
        Row(title: title, value: value)
            .overrideTextColors(.init(title: DesignSystem.Color.textSecondary))
            .showDivider(showsDivider)
    }
}

// MARK: - Constants

private extension YieldModuleAboutApyV2View {
    enum Constants {
        static let headerPadding: CGFloat = 16
        static let descriptionHorizontalPadding: CGFloat = 16
        static let descriptionVerticalPadding: CGFloat = 12
        static let swipeDismissThreshold: CGFloat = 100
    }
}
