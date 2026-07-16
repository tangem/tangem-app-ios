//
//  NotificationSettingsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct NotificationSettingsView: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel

    var body: some View {
        content
            .background(Colors.Background.secondary.ignoresSafeArea())
            .navigationTitle(Localization.pushNotificationSettingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .alert(item: $viewModel.alert) { $0.alert }
            .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            loadingView
        case .error:
            errorView
        case .content:
            settingsView
        }
    }

    private var settingsView: some View {
        GroupedScrollView(contentType: .lazy(alignment: .leading, spacing: 24)) {
            allowNotificationsBannerSection

            transactionPushSection

            offersUpdatesSection

            priceAlertsSection
        }
        .interContentPadding(8)
    }

    private var loadingView: some View {
        GroupedScrollView(contentType: .lazy(alignment: .leading, spacing: 24)) {
            ForEach(0 ..< Constants.skeletonSectionsCount, id: \.self) { _ in
                skeletonSection
            }
        }
        .interContentPadding(8)
    }

    private var errorView: some View {
        UnableToLoadDataView(
            isButtonBusy: viewModel.isRetryButtonBusy,
            retryButtonAction: viewModel.onRetryLoadPreferencesTap
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Reuses `GroupedSection` so the card background, corner radius, horizontal padding and
    /// footer spacing stay in lockstep with the real sections instead of being duplicated here.
    private var skeletonSection: some View {
        GroupedSection(SkeletonSectionItem()) { _ in
            HStack {
                skeletonCapsule(width: 222)

                Spacer()

                skeletonCapsule(width: 56)
            }
            // Matches `DefaultToggleRowView`'s vertical padding so the placeholder row height
            // lines up with a real toggle row.
            .padding(.vertical, 8)
        } footer: {
            skeletonCapsule()
        }
    }

    /// Fixed-width capsule placeholder; without `width` it stretches to the available width.
    private func skeletonCapsule(width: CGFloat? = nil) -> some View {
        SkeletonView()
            .frame(width: width)
            .frame(height: 20)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var allowNotificationsBannerSection: some View {
        if let input = viewModel.allowNotificationsBannerInput {
            NotificationView(input: input)
        }
    }

    @ViewBuilder
    private var transactionPushSection: some View {
        VStack(spacing: 14) {
            GroupedSection(viewModel.transactionAlertsViewModel) {
                DefaultToggleRowView(viewModel: $0)
            } footer: {
                Button(action: viewModel.onTapMoreInfoTransactionPushNotifications) {
                    Group {
                        Text("\(Localization.walletSettingsPushNotificationsDescription) ")
                            + readMoreText
                    }
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                }
            }
        }
    }

    private var offersUpdatesSection: some View {
        GroupedSection(viewModel.offersUpdatesViewModel) {
            DefaultToggleRowView(viewModel: $0)
        } footer: {
            DefaultFooterView(Localization.pushNotificationSettingsOffersUpdatesSubtitle)
        }
    }

    private var priceAlertsSection: some View {
        GroupedSection(viewModel.priceAlertsViewModel) {
            DefaultToggleRowView(viewModel: $0)
        } footer: {
            DefaultFooterView(Localization.pushNotificationSettingsPriceAlertsSubtitle)
        }
    }

    private var readMoreText: Text {
        let text = Localization.pushNotificationsMoreInfo.replacingOccurrences(of: " ", with: String.unbreakableSpace)
        return Text(text).foregroundColor(Colors.Text.accent)
    }
}

// MARK: - Constants

private extension NotificationSettingsView {
    enum Constants {
        static let skeletonSectionsCount = 3
    }

    struct SkeletonSectionItem: Identifiable {
        let id = 0
    }
}
