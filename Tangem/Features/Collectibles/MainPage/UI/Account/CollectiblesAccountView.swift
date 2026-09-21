//
//  CollectiblesAccountView.swift
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

struct CollectiblesAccountView: View {
    @ObservedObject var viewModel: CollectiblesAccountViewModel

    let balanceCoordinateSpace: CoordinateSpace
    let onBalanceMaxYChange: (CGFloat) -> Void

    var body: some View {
        content.task(viewModel.load)
    }
}

private extension CollectiblesAccountView {
    // MARK: - View properties

    var content: some View {
        VStack(spacing: 0) {
            balance(viewModel.summary)

            collectionRow(viewModel.summary)
                .padding(.top, Metrics.collectionRowTopPadding)
        }
    }

    func balance(_ summary: Summary) -> some View {
        VStack(spacing: 0) {
            LoadableBalanceView(
                state: summary.fiatBalance,
                style: .init(font: DesignSystem.Font.displayMediumToken, textColor: DesignSystem.Color.textPrimary),
                loader: .init(size: CGSize(width: Metrics.balanceLoaderWidth, height: Metrics.balanceLoaderHeight))
            )

            Text(summary.cryptoBalanceText)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .shimmer()
                .padding(.top, Metrics.cryptoBalanceTopPadding)
                .readGeometry(\.frame.maxY, inCoordinateSpace: balanceCoordinateSpace, onChange: onBalanceMaxYChange)

            actionButtons(summary)
                .padding(.top, Metrics.actionButtonsTopPadding)
        }
        .environment(\.isShimmerActive, summary.isBalanceUpdating)
        .infinityFrame(axis: .horizontal)
        .padding(.top, Metrics.topPadding)
    }

    func actionButtons(_ summary: Summary) -> some View {
        HStack(spacing: 0) {
            // [REDACTED_TODO_COMMENT]
            TangemMainActionButton(title: Localization.commonAddFunds, icon: Assets.DesignSystem.arrowDown) {}
                .frame(width: Metrics.actionButtonWidth)

            // [REDACTED_TODO_COMMENT]
            TangemMainActionButton(title: Localization.commonWithdrawal, icon: Assets.DesignSystem.arrowUp) {}
                .frame(width: Metrics.actionButtonWidth)
                .disabled(!summary.isWithdrawalAvailable)
        }
    }

    @ViewBuilder
    func collectionRow(_ summary: Summary) -> some View {
        if summary.isBalanceUpdating {
            collectionRowSkeleton
        } else {
            // [REDACTED_TODO_COMMENT]
            Row(title: summary.collectionCountText, subtitle: Localization.collectiblesAccountCollectionRowSubtitle)
                .lineOrder(.secondaryFirst)
                .start { Self.collectionIcon }
                .end { Self.disclosureIcon }
                .background(
                    DesignSystem.Color.bgSecondary,
                    in: RoundedRectangle(cornerRadius: Metrics.collectionRowCornerRadius, style: .continuous)
                )
                .padding(.horizontal, Metrics.horizontalPadding)
        }
    }

    var collectionRowSkeleton: some View {
        HStack(spacing: Metrics.collectionRowSpacing) {
            Self.collectionIcon

            VStack(alignment: .leading, spacing: Metrics.collectionSkeletonSpacing) {
                skeletonBar(width: Metrics.collectionSubtitleSkeletonWidth)

                skeletonBar(width: Metrics.collectionTitleSkeletonWidth)
            }

            Spacer(minLength: 0)

            Self.disclosureIcon
        }
        .padding(.horizontal, Metrics.collectionRowInnerPadding)
        .frame(height: Metrics.collectionRowHeight)
        .background(
            DesignSystem.Color.bgSecondary,
            in: RoundedRectangle(cornerRadius: Metrics.collectionRowCornerRadius, style: .continuous)
        )
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    func skeletonBar(width: CGFloat) -> some View {
        Shimmer()
            .frame(width: width, height: Metrics.collectionSkeletonBarHeight)
            .clipShape(Capsule())
    }
}

// MARK: - Shared icons

private extension CollectiblesAccountView {
    static var collectionIcon: some View {
        DesignSystem.Icons.Grid.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconBrand)
            .frame(size: .init(bothDimensions: Metrics.collectionIconSize))
            .background(DesignSystem.Color.bgStatusInfoSubtle, in: Circle())
            .accessibilityHidden(true)
    }

    static var disclosureIcon: some View {
        DesignSystem.Icons.ChevronRight.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .accessibilityHidden(true)
    }
}

// MARK: - Metrics

private extension CollectiblesAccountView {
    enum Metrics {
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 56
        static let cryptoBalanceTopPadding: CGFloat = 12
        static let actionButtonsTopPadding: CGFloat = 60
        static let actionButtonWidth: CGFloat = 102

        static let balanceLoaderWidth: CGFloat = 190
        static let balanceLoaderHeight: CGFloat = 40

        static let collectionRowTopPadding: CGFloat = 24
        static let collectionRowCornerRadius: CGFloat = 24
        static let collectionIconSize: CGFloat = 40

        static let collectionRowHeight: CGFloat = 72
        static let collectionRowInnerPadding: CGFloat = 16
        static let collectionRowSpacing: CGFloat = 12
        static let collectionSkeletonSpacing: CGFloat = 6
        static let collectionSkeletonBarHeight: CGFloat = 16
        static let collectionSubtitleSkeletonWidth: CGFloat = 122
        static let collectionTitleSkeletonWidth: CGFloat = 76
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        CollectiblesAccountView(
            viewModel: CollectiblesAccountViewModel(accountModel: nil),
            balanceCoordinateSpace: .local,
            onBalanceMaxYChange: { _ in }
        )
    }
}
