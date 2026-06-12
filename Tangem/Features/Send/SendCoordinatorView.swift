//
//  SendCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct SendCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SendCoordinator
    @State private var interactiveDismissDisabled: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                if let rootViewModel = coordinator.rootViewModel {
                    SendView(
                        viewModel: rootViewModel,
                        interactiveDismissDisabled: $interactiveDismissDisabled
                    )
                    .navigationLinks(links)
                }

                sheets
            }
        }
        .tint(Colors.Text.primary1)
        .interactiveDismissDisabled(interactiveDismissDisabled)
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.onrampSettingsViewModel) {
                OnrampSettingsView(viewModel: $0)
            }
            .navigation(item: $coordinator.onrampRedirectingViewModel) {
                OnrampRedirectingView(viewModel: $0)
            }
    }

    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.onrampCountryDetectionCoordinator) {
                OnrampCountryDetectionCoordinatorView(coordinator: $0)
                    .interactiveDismissDisabled(true)
                    .presentationBackground(Colors.Background.tertiary)
            }
            .sheet(item: $coordinator.qrScanViewCoordinator) {
                QRScanViewCoordinatorView(coordinator: $0).ignoresSafeArea()
            }
            .sheet(item: $coordinator.onrampCountrySelectorViewModel) {
                OnrampCountrySelectorView(viewModel: $0)
            }
            .sheet(item: $coordinator.onrampCurrencySelectorViewModel) {
                OnrampCurrencySelectorView(viewModel: $0)
            }
            .sheet(item: $coordinator.sendReceiveTokenCoordinator) {
                SendReceiveTokenCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.swapTokenSelectorViewModel) {
                SwapTokenSelectorView(viewModel: $0)
            }
    }
}
