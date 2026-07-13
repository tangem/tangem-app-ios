//
//  NotificationSettingsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct NotificationSettingsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: NotificationSettingsCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                NotificationSettingsView(viewModel: rootViewModel)
                    .navigation(item: $coordinator.priceAlertsScreenCoordinator) {
                        PriceAlertsScreenCoordinatorView(coordinator: $0)
                    }
            }

            sheets
        }
    }

    private var sheets: some View {
        NavHolder()
            .floatingSheetContent(for: TransactionNotificationsModalViewModel.self) {
                TransactionNotificationsModalView(viewModel: $0)
            }
    }
}
