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
        GroupedScrollView(contentType: .lazy(alignment: .leading, spacing: 24)) {
            allowNotificationsBannerSection

            transactionPushSection

            offersUpdatesSection

            priceAlertsSection
        }
        .interContentPadding(8)
        .background(Colors.Background.secondary.ignoresSafeArea())
        .navigationTitle(Localization.pushNotificationSettingsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
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
