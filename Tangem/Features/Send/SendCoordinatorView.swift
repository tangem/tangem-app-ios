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

    private let presentation: SendView.Presentation

    @State private var interactiveDismissDisabled: Bool = false

    init(coordinator: SendCoordinator, presentation: SendView.Presentation = .modal) {
        self.coordinator = coordinator
        self.presentation = presentation
    }

    @ViewBuilder
    var body: some View {
        switch presentation {
        case .modal:
            NavigationStack {
                content
            }
            .tint(Colors.Text.primary1)
            .interactiveDismissDisabled(interactiveDismissDisabled)

        case .pushed:
            content
                .tint(Colors.Text.primary1)
        }
    }

    private var content: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                SendView(
                    viewModel: rootViewModel,
                    interactiveDismissDisabled: $interactiveDismissDisabled,
                    presentation: presentation
                )
                .navigationLinks(links)
                .supportChatPresentation(coordinator.supportChatPresenter)
            }

            sheets
        }
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
            .sheet(item: $coordinator.sendReceiveTokenCoordinator, onDismiss: coordinator.onReceiveTokensListDismissed) {
                SendReceiveTokenCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.addressBooksCoordinator) { coordinator in
                NavigationStack {
                    AddressBooksCoordinatorView(coordinator: coordinator)
                }
            }
            .addressBookContactManagementSheet($coordinator.contactManagementCoordinator)
            .sheet(item: $coordinator.swapTokenSelectorViewModel) {
                SwapTokenSelectorView(viewModel: $0)
            }
    }
}
