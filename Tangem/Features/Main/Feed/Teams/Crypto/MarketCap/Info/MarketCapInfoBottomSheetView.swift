//
//  MarketCapInfoBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct MarketCapInfoBottomSheetView: View {
    let viewModel: MarketCapInfoBottomSheetViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: Constants.contentSpacing) {
                    if let reading = viewModel.reading {
                        self.reading(reading)
                    }

                    Text(viewModel.descriptionText)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                        .infinityFrame(axis: .horizontal, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.bottom, Constants.bottomPadding)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .floatingSheetConfiguration { config in
            config.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            config.backgroundInteractionBehavior = .tapToDismiss
            config.verticalSwipeBehavior = .init(target: .sheet, threshold: 100)
        }
    }
}

// MARK: - View Components

private extension MarketCapInfoBottomSheetView {
    var header: some View {
        BottomSheetHeaderView(
            title: viewModel.title,
            trailing: {
                TangemUI.Button(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonClose,
                    action: viewModel.closeAction
                )
                .size(.x9)
                .styleType(.secondary(.default))
            }
        )
        .titleFont(DesignSystem.Font.bodyMediumToken.font)
        .titleColor(DesignSystem.Color.textPrimary)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.headerTopPadding)
        .environment(\.isRedesign, true)
    }

    func reading(_ metric: MarketCapViewModel.Metric) -> some View {
        VStack(spacing: Constants.readingSpacing) {
            Text(metric.value)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            Text(metric.status)
                .style(DesignSystem.Font.bodyMediumToken, color: metric.appearance.textColor)

            MarketIndexScaleView(progress: metric.progress, size: .big)
                .padding(.top, Constants.scaleTopPadding)
                .padding(.horizontal, Constants.scaleHorizontalPadding)
        }
        .infinityFrame(axis: .horizontal)
    }
}

// MARK: - Constants

private extension MarketCapInfoBottomSheetView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 16
        static let headerTopPadding: CGFloat = 12
        static let contentSpacing: CGFloat = 24
        static let readingSpacing: CGFloat = 4
        static let scaleTopPadding: CGFloat = 20
        static let scaleHorizontalPadding: CGFloat = 12
    }
}
