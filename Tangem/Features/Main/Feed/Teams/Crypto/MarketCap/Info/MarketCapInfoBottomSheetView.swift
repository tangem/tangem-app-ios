//
//  MarketCapInfoBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketCapInfoBottomSheetView: View {
    let viewModel: MarketCapInfoBottomSheetViewModel

    var body: some View {
        VStack(spacing: Constants.contentSpacing) {
            if let reading = viewModel.reading {
                self.reading(reading)
            } else {
                Text(viewModel.title)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                    .infinityFrame(axis: .horizontal)
            }

            Text(description)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .tint(DesignSystem.Color.textAccentBlue)
                .infinityFrame(axis: .horizontal, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.topPadding)
        .padding(.bottom, Constants.bottomPadding)
    }

    private var description: AttributedString {
        var text = AttributedString(viewModel.descriptionText)

        if let range = text.range(of: Constants.sourceHost) {
            text[range].link = Constants.sourceURL
        }

        return text
    }
}

// MARK: - View Components

private extension MarketCapInfoBottomSheetView {
    func reading(_ metric: MarketCapViewModel.Metric) -> some View {
        VStack(spacing: Constants.contentSpacing) {
            VStack(spacing: Constants.readingSpacing) {
                Text(verbatim: "\(viewModel.title) – \(metric.value)")
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)

                Text(metric.status)
                    .style(DesignSystem.Font.headingSmallToken, color: metric.appearance.textColor)
            }

            MarketIndexScaleView(progress: metric.progress, size: .big)
                .padding(.horizontal, Constants.scaleHorizontalPadding)
        }
        .multilineTextAlignment(.center)
        .infinityFrame(axis: .horizontal)
    }
}

// MARK: - Constants

private extension MarketCapInfoBottomSheetView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 40
        static let contentSpacing: CGFloat = 40
        static let readingSpacing: CGFloat = 4
        static let scaleHorizontalPadding: CGFloat = 12
        static let sourceHost = "coinmarketcap.com"
        static let sourceURL = URL(string: "https://coinmarketcap.com")
    }
}
