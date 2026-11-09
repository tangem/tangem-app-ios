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
            .tint(DesignSystem.Color.textPrimary)
            .interactiveDismissDisabled(interactiveDismissDisabled)

        case .pushed:
            content
                .tint(DesignSystem.Color.textPrimary)
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
                    .presentationBackground(DesignSystem.Color.bgPrimary)
                    .softTopScrollEdgeEffect()
            }
            .sheet(item: $coordinator.qrScanViewCoordinator) {
                QRScanViewCoordinatorView(coordinator: $0).ignoresSafeArea()
                    .softTopScrollEdgeEffect()
            }
            .sheet(item: $coordinator.onrampCountrySelectorViewModel) {
                OnrampCountrySelectorView(viewModel: $0)
                    .softTopScrollEdgeEffect()
            }
            .sheet(item: $coordinator.onrampCurrencySelectorViewModel) {
                OnrampCurrencySelectorView(viewModel: $0)
                    .softTopScrollEdgeEffect()
            }
            .sheet(item: $coordinator.sendReceiveTokenCoordinator, onDismiss: coordinator.onReceiveTokensListDismissed) {
                SendReceiveTokenCoordinatorView(coordinator: $0)
                    .softTopScrollEdgeEffect()
            }
            .sheet(item: $coordinator.addressBooksCoordinator) { coordinator in
                NavigationStack {
                    AddressBooksCoordinatorView(coordinator: coordinator)
                }
                .softTopScrollEdgeEffect()
            }
            .addressBookContactManagementSheet($coordinator.contactManagementCoordinator)
            .sheet(item: $coordinator.swapTokenSelectorViewModel) {
                SwapTokenSelectorView(viewModel: $0)
                    .softTopScrollEdgeEffect()
            }
            .sheet(item: $coordinator.demandSurveySheet) { sheet in
                NavigationStack {
                    demandSurvey(sheet)
                        .withCloseButton(action: coordinator.closeDemandSurvey)
                }
            }
    }

    @ViewBuilder
    private func demandSurvey(_ sheet: SendCoordinator.DemandSurveySheet) -> some View {
        switch sheet {
        case .form(let viewModel):
            DemandSurveyView(viewModel: viewModel)
        case .success:
            DemandSurveySuccessView(onDone: coordinator.closeDemandSurvey)
        }
    }
}
