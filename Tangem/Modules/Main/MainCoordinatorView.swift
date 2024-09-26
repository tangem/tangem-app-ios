//
//  MainCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MainCoordinator

    @State private var responderChainIntrospectionTrigger = UUID()

    @StateObject private var navigationAssertion = MainCoordinatorNavigationAssertion()

    var body: some View {
        ZStack {
            if let mainViewModel = coordinator.mainViewModel {
                MainView(viewModel: mainViewModel)
                    .navigationLinks(links)
            }

            marketsTooltipView

            sheets
        }
        .onOverlayContentStateChange { [weak coordinator] state in
            if !state.isCollapsed {
                coordinator?.hideMarketsTooltip()
            }
        }
        .onAppear {
            responderChainIntrospectionTrigger = UUID()
        }
        .introspectResponderChain(
            introspectedType: UINavigationController.self,
            updateOnChangeOf: responderChainIntrospectionTrigger
        ) { [weak navigationAssertion] navigationController in
            navigationController.setDelegateSafe(navigationAssertion)
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.detailsCoordinator) {
                DetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.tokenDetailsCoordinator) {
                TokenDetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.stakingDetailsCoordinator) {
                StakingDetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.marketsTokenDetailsCoordinator) {
                TokenMarketsDetailsCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.modalWebViewModel) {
                WebViewContainer(viewModel: $0)
            }
            .iOS16UIKitSheet(item: $coordinator.expressCoordinator) {
                ExpressCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.modalOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
            }
            .sheet(item: $coordinator.organizeTokensViewModel) { viewModel in
                OrganizeTokensContainerView(viewModel: viewModel)
            }
            .sheet(item: $coordinator.legacyTokenListCoordinator) {
                LegacyTokenListCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.visaTransactionDetailsViewModel) {
                VisaTransactionDetailsView(viewModel: $0)
            }

        NavHolder()
            .bottomSheet(
                item: $coordinator.warningBankCardViewModel,
                backgroundColor: Colors.Background.primary
            ) {
                WarningBankCardView(viewModel: $0)
                    .padding(.bottom, 10)
            }
            .bottomSheet(
                item: $coordinator.receiveBottomSheetViewModel,
                settings: .init(backgroundColor: Colors.Background.primary, contentScrollsHorizontally: true)
            ) {
                ReceiveBottomSheetView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.pushNotificationsViewModel,
                backgroundColor: Colors.Background.primary
            ) {
                PushNotificationsBottomSheetView(viewModel: $0)
            }

        NavHolder()
            .requestAppStoreReviewCompat($coordinator.isAppStoreReviewRequested)
    }

    // Tooltip is placed on top of the other views
    private var marketsTooltipView: some View {
        BasicTooltipView(
            isShowBindingValue: $coordinator.isMarketsTooltipVisible,
            onHideAction: coordinator.hideMarketsTooltip,
            title: Localization.marketsTooltipTitle,
            message: Localization.marketsTooltipMessage
        )
    }
}
