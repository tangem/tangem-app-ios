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
            .bottomSheet(
                item: $coordinator.expressApproveViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                ExpressApproveView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.onrampCountryDetectionCoordinator,
                settings: .init(
                    backgroundColor: Colors.Background.tertiary,
                    hidingOption: .nonHideable
                )
            ) {
                OnrampCountryDetectionCoordinatorView(coordinator: $0)
            }
            .floatingSheetContent(for: FeeSelectorContentViewModel.self) {
                FeeSelectorContentView(viewModel: $0)
            }
            .floatingSheetContent(for: SendSwapProvidersSelectorViewModel.self) {
                SendSwapProvidersSelectorView(viewModel: $0)
            }
            .floatingSheetContent(for: HighPriceImpactWarningSheetViewModel.self) {
                HighPriceImpactWarningSheetView(viewModel: $0)
            }
            .floatingSheetContent(for: OnrampOffersSelectorViewModel.self) {
                OnrampOffersSelectorView(viewModel: $0)
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
            .floatingSheetContent(for: BlockchainAccountInitializationViewModel.self) {
                BlockchainAccountInitializationView(viewModel: $0)
            }
    }
}
