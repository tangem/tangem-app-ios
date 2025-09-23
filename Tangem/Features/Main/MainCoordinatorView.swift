//
//  MainCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemNFT
import TangemUI

struct MainCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MainCoordinator

    @State private var responderChainIntrospectionTrigger = UUID()

    @StateObject private var navigationAssertion = MainCoordinatorNavigationAssertion()

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

    var body: some View {
        NavigationView {
            content
        }
        .navigationViewStyle(.stack)
    }

    private var content: some View {
        ZStack {
            if let mainViewModel = coordinator.mainViewModel {
                MainView(viewModel: mainViewModel)
                    .navigationLinks(links)
            }

            marketsTooltipView

            sheets
        }
        .onOverlayContentStateChange(overlayContentStateObserver: overlayContentStateObserver) { [weak coordinator] state in
            if !state.isCollapsed {
                coordinator?.hideMarketsTooltip()
            } else {
                // Workaround: If you open the markets screen, add a token, and return to the main page, the frames break and no longer align with the tap zone.
                // [REDACTED_INFO]
                // https://forums.developer.apple.com/forums/thread/724598
                if let vc = UIApplication.topViewController as? OverlayContentContainerViewController {
                    vc.resetContentFrame()
                }
            }
        }
        .onAppear {
            responderChainIntrospectionTrigger = UUID()
        }
        .introspectResponderChain(
            introspectedType: UINavigationController.self,
            updateOnChangeOf: responderChainIntrospectionTrigger
        ) { [weak navigationAssertion] navigationController in
            navigationController.safeSet(delegate: navigationAssertion)
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
                MarketsTokenDetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.referralCoordinator) {
                ReferralCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.nftCollectionsCoordinator) {
                NFTCollectionsCoordinatorView(coordinator: $0)
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
            .iOS16UIKitSheet(item: $coordinator.expressCoordinator) { coordinator in
                ExpressCoordinatorView(coordinator: coordinator)
                    .expressNavigationView()
            }
            .sheet(item: $coordinator.modalOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
            }
            .sheet(item: $coordinator.organizeTokensViewModel) { viewModel in
                NavigationBarHidingView(shouldWrapInNavigationView: true) {
                    OrganizeTokensView(viewModel: viewModel)
                        .navigationTitle(Localization.organizeTokensTitle)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(item: $coordinator.mobileUpgradeCoordinator) {
                MobileUpgradeCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
            }
            .sheet(item: $coordinator.visaTransactionDetailsViewModel) {
                VisaTransactionDetailsView(viewModel: $0)
            }
            .sheet(item: $coordinator.actionButtonsBuyCoordinator) {
                ActionButtonsBuyCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.actionButtonsSellCoordinator) {
                ActionButtonsSellCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.actionButtonsSwapCoordinator) {
                ActionButtonsSwapCoordinatorView(coordinator: $0)
            }
            .floatingSheetContent(for: MobileFinishActivationNeededViewModel.self) {
                MobileFinishActivationNeededView(viewModel: $0)
            }
            .floatingSheetContent(for: ReceiveMainViewModel.self) {
                ReceiveMainView(viewModel: $0)
            }
            .floatingSheetContent(for: SendYieldNoticeStepViewModel.self) {
                SendYieldNoticeView(viewModel: $0)
            }

        NavHolder()
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
            .bottomSheet(
                item: $coordinator.pendingExpressTxStatusBottomSheetViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                PendingExpressTxStatusBottomSheetView(viewModel: $0)
            }

        NavHolder()
            .requestAppStoreReviewCompat($coordinator.isAppStoreReviewRequested)
    }

    /// Tooltip is placed on top of the other views
    private var marketsTooltipView: some View {
        BasicTooltipView(
            isShowBindingValue: $coordinator.isMarketsTooltipVisible,
            onHideAction: coordinator.hideMarketsTooltip,
            title: Localization.marketsTooltipTitle,
            message: Localization.marketsTooltipMessage
        )
    }
}
