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

    @ScaledMetric private var balanceLoaderWidth: CGFloat = 190
    @ScaledMetric private var balanceLoaderHeight: CGFloat = 52

    @ScaledMetric(relativeTo: DesignSystem.Font.bodyMediumToken.relativeTo)
    private var collectionTitleBarHeight: CGFloat = 20

    @ScaledMetric(relativeTo: DesignSystem.Font.captionMediumToken.relativeTo)
    private var collectionSubtitleBarHeight: CGFloat = 16

    var body: some View {
        content
            .task(viewModel.load)
            .alert(item: $viewModel.alert) { $0.alert }
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
                loader: .init(size: CGSize(width: balanceLoaderWidth, height: balanceLoaderHeight))
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
            TangemMainActionButton(
                title: Localization.commonAddFunds,
                icon: Assets.DesignSystem.arrowDown,
                action: viewModel.addFunds,
                reasonTapWhenDisabled: viewModel.addFunds
            )
            .padding(.horizontal, Metrics.actionButtonHorizontalPadding)
            .disabled(!viewModel.vaultUsdcState.isReady)

            // [REDACTED_TODO_COMMENT]
            TangemMainActionButton(title: Localization.commonWithdrawal, icon: Assets.DesignSystem.arrowUp) {}
                .padding(.horizontal, Metrics.actionButtonHorizontalPadding)
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
                skeletonBar(width: Metrics.collectionSubtitleSkeletonWidth, height: collectionSubtitleBarHeight)

                skeletonBar(width: Metrics.collectionTitleSkeletonWidth, height: collectionTitleBarHeight)
            }

            Spacer(minLength: 0)

            Self.disclosureIcon
        }
        .padding(Metrics.collectionRowInnerPadding)
        .background(
            DesignSystem.Color.bgSecondary,
            in: RoundedRectangle(cornerRadius: Metrics.collectionRowCornerRadius, style: .continuous)
        )
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    func skeletonBar(width: CGFloat, height: CGFloat) -> some View {
        Shimmer()
            .frame(width: width, height: height)
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
        static let actionButtonHorizontalPadding: CGFloat = 16

        static let collectionRowTopPadding: CGFloat = 24
        static let collectionRowCornerRadius: CGFloat = 24
        static let collectionIconSize: CGFloat = 40

        static let collectionRowInnerPadding: CGFloat = 16
        static let collectionRowSpacing: CGFloat = 12
        static let collectionSkeletonSpacing: CGFloat = 2
        static let collectionSubtitleSkeletonWidth: CGFloat = 122
        static let collectionTitleSkeletonWidth: CGFloat = 76
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        CollectiblesAccountView(
            viewModel: CollectiblesAccountViewModel(accountModel: nil, routable: nil),
            balanceCoordinateSpace: .local,
            onBalanceMaxYChange: { _ in }
        )
    }
}
