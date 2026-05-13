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
        .navigationTitle(NotificationSettingsViewModel.Constants.screenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var allowNotificationsBannerSection: some View {
        if viewModel.isBannerVisible {
            AllowNotificationsBannerView(
                openSettingsAction: viewModel.openAppSettingsFromBanner
            )
        }
    }

    @ViewBuilder
    private var transactionPushSection: some View {
        if let transactionPushViewModel = viewModel.transactionPushViewModel {
            TransactionNotificationsRowToggleView(viewModel: transactionPushViewModel)
        }
    }

    private var offersUpdatesSection: some View {
        GroupedSection(viewModel.offersUpdatesViewModel) {
            DefaultToggleRowView(viewModel: $0)
        } footer: {
            DefaultFooterView(NotificationSettingsViewModel.Constants.offersUpdatesFooter)
        }
    }

    private var priceAlertsSection: some View {
        GroupedSection(viewModel.priceAlertsViewModel) {
            DefaultToggleRowView(viewModel: $0)
        } footer: {
            DefaultFooterView(NotificationSettingsViewModel.Constants.priceAlertsFooter)
        }
    }
}
