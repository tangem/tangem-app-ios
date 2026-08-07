//
//  PriceAlertsScreenView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct PriceAlertsScreenView: View {
    @ObservedObject var viewModel: PriceAlertsScreenViewModel

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .leading, spacing: 24)) {
            showNotificationsSection

            watchlistSection
        }
        .interContentPadding(8)
        .background(Colors.Background.secondary.ignoresSafeArea())
        .navigationTitle(Localization.pushNotificationSettingsPriceAlertsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
    }

    private var showNotificationsSection: some View {
        GroupedSection(viewModel.showNotificationsRowViewModel) {
            DefaultToggleRowView(viewModel: $0)
        } footer: {
            DefaultFooterView(Localization.pushNotificationSettingsPriceAlertsSubtitle)
        }
    }

    @ViewBuilder
    private var watchlistSection: some View {
        switch viewModel.watchlistState {
        case .loading:
            loadingView
        case .empty:
            emptyStateView
        case .error:
            errorStateView
        case .items(let items):
            watchlistBlock(items: items)
        }
    }

    private func watchlistBlock(items: [PriceAlertsWatchlistItemViewModel]) -> some View {
        watchlistCard {
            ForEach(items) { item in
                PriceAlertsWatchlistItemView(viewModel: item) {
                    viewModel.deleteTapped(tokenId: item.id)
                }
            }
        }
    }

    private var loadingView: some View {
        watchlistCard {
            ForEach(0 ..< Constants.skeletonRowsCount, id: \.self) { _ in
                skeletonRow
            }
        }
    }

    /// Titled card container shared by the loaded list and the loading skeletons; rows are the
    /// design-system `TangemRow` with its own 16pt inner padding.
    private func watchlistCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            // [REDACTED_TODO_COMMENT]
            Text("My watchlist")
                .style(DesignSystem.Font.captionMediumToken, color: Colors.Text.tertiary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            content()
        }
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }

    /// Shimmer variant of the watchlist row (start slot only, no divider), mirroring the real row's layout.
    private var skeletonRow: some View {
        TangemRow()
            .titleAccessory { skeletonCapsule(size: Constants.skeletonTitleSize) }
            .subtitleAccessory { skeletonCapsule(size: Constants.skeletonSubtitleSize) }
            .start {
                SkeletonView()
                    .frame(width: Constants.skeletonIconSize, height: Constants.skeletonIconSize)
                    .clipShape(Circle())
            }
            .contentLead(.equal)
            .showDivider(false)
    }

    private func skeletonCapsule(size: CGSize) -> some View {
        SkeletonView()
            .frame(width: size.width, height: size.height)
            .clipShape(Capsule())
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            // [REDACTED_TODO_COMMENT]
            Text("Your watchlist is empty")
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)

            Text("Add coins to track price moves and get notified when something changes.")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.top, Constants.stateTopPadding)
    }

    private var errorStateView: some View {
        Text(Localization.commonSomethingWentWrong)
            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, Constants.stateTopPadding)
    }
}

// MARK: - Constants

private extension PriceAlertsScreenView {
    enum Constants {
        static let stateTopPadding: CGFloat = 40
        static let skeletonRowsCount = 3
        static let skeletonIconSize: CGFloat = 36
        static let skeletonTitleSize = CGSize(width: 132, height: 16)
        static let skeletonSubtitleSize = CGSize(width: 80, height: 16)
    }
}
