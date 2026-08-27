//
//  GachaAccountView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct GachaAccountView: View {
    @ObservedObject var viewModel: GachaAccountViewModel

    var body: some View {
        content.task(viewModel.load)
    }
}

private extension GachaAccountView {
    // MARK: - View properties

    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Skeleton()
        case .content(let summary):
            loaded(summary)
        case .failed:
            loaded(.unavailable)
        }
    }

    func loaded(_ summary: Summary) -> some View {
        VStack(spacing: 0) {
            balance(summary)
            collectionRow(summary)
                .padding(.top, Metrics.collectionRowTopPadding)
        }
    }

    func balance(_ summary: Summary) -> some View {
        VStack(spacing: 0) {
            Text(summary.fiatBalanceText)
                .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)

            Text(summary.cryptoBalanceText)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .padding(.top, Metrics.cryptoBalanceTopPadding)

            actionButtons
                .padding(.top, Metrics.actionButtonsTopPadding)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Metrics.topPadding)
    }

    var actionButtons: some View {
        HStack(spacing: 0) {
            // [REDACTED_TODO_COMMENT]
            TangemMainActionButton(title: "Add funds", icon: Assets.DesignSystem.arrowDown) {}
                .frame(width: Metrics.actionButtonWidth)

            // [REDACTED_TODO_COMMENT]
            TangemMainActionButton(title: "Withdrawal", icon: Assets.DesignSystem.arrowUp) {}
                .frame(width: Metrics.actionButtonWidth)
        }
    }

    func collectionRow(_ summary: Summary) -> some View {
        // [REDACTED_TODO_COMMENT]
        Row(title: summary.collectionCountText, subtitle: "My collection")
            .lineOrder(.secondaryFirst)
            .start { collectionIcon }
            .end { disclosureIcon }
            .background(
                DesignSystem.Color.bgSecondary,
                in: RoundedRectangle(cornerRadius: Metrics.collectionRowCornerRadius, style: .continuous)
            )
            .padding(.horizontal, Metrics.horizontalPadding)
    }

    var collectionIcon: some View {
        DesignSystem.Icons.Grid.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconBrand)
            .frame(size: .init(bothDimensions: Metrics.collectionIconSize))
            .background(DesignSystem.Color.bgStatusInfoSubtle, in: Circle())
            .accessibilityHidden(true)
    }

    var disclosureIcon: some View {
        DesignSystem.Icons.ChevronRight.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .accessibilityHidden(true)
    }
}

// MARK: - Metrics

/// Not private: `Skeleton` reads the shared values so it does not jump when the content arrives.
extension GachaAccountView {
    enum Metrics {
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 56
        static let cryptoBalanceTopPadding: CGFloat = 12
        static let actionButtonsTopPadding: CGFloat = 60
        static let actionButtonWidth: CGFloat = 102

        static let collectionRowTopPadding: CGFloat = 24
        static let collectionRowCornerRadius: CGFloat = 24
        static let collectionIconSize: CGFloat = 40
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        GachaAccountView(viewModel: GachaAccountViewModel(provider: GachaAccountSummaryMockProvider()))
    }
}
