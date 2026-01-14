//
//  MainCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import StoreKit
import SwiftUI
import TangemAssets
import TangemLocalization
import enum TangemFoundation.AppEnvironment
import TangemUI
import TangemUIUtils

struct MainCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MainCoordinator

    @Environment(\.requestReview) private var requestReview

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

    var body: some View {
        NavigationStack {
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
            .injectNavigationAssertionDelegate()
        }
    }

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
            .navigation(item: $coordinator.nftCollectionsCoordinator) {
                NFTCollectionsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.tangemPayMainCoordinator) {
                TangemPayMainCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.yieldModulePromoCoordinator) {
                YieldModulePromoCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .fullScreenCover(
                item: $coordinator.tangemPayOnboardingCoordinator
            ) {
                TangemPayOnboardingCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.expressCoordinator) { coordinator in
                ExpressCoordinatorView(coordinator: coordinator)
            }
            .sheet(item: $coordinator.modalOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
            }
            .sheet(item: $coordinator.organizeTokensViewModel) { viewModel in
                NavigationBarHidingView(shouldWrapInNavigationStack: true) {
                    AccountsAwareOrganizeTokensView(viewModel: viewModel)
                        .navigationTitle(Localization.organizeTokensTitle)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(item: $coordinator.legacyOrganizeTokensViewModel) { viewModel in
                NavigationBarHidingView(shouldWrapInNavigationStack: true) {
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
            .sheet(item: $coordinator.yieldModuleActiveCoordinator) {
                YieldModuleActiveCoordinatorView(coordinator: $0)
            }
            .floatingSheetContent(for: MobileFinishActivationNeededViewModel.self) {
                MobileFinishActivationNeededView(viewModel: $0)
            }
            .floatingSheetContent(for: ReceiveMainViewModel.self) {
                ReceiveMainView(viewModel: $0)
            }
            .floatingSheetContent(for: AccountSelectorViewModel.self) {
                AccountSelectorView(viewModel: $0)
            }
            .floatingSheetContent(for: YieldNoticeViewModel.self) {
                YieldNoticeView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayYourCardIsIssuingSheetViewModel.self) {
                TangemPayYourCardIsIssuingSheetView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayFailedToIssueCardSheetViewModel.self) {
                TangemPayFailedToIssueCardSheetView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayKYCStatusPopupViewModel.self) {
                TangemPayKYCStatusPopupView(viewModel: $0)
            }

        NavHolder()
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
            .onChange(of: coordinator.isAppStoreReviewRequested) { newValue in
                guard newValue else { return }

                coordinator.isAppStoreReviewRequested.toggle()
                requestReview()
            }
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

// MARK: - Overlay content controller bottom sheet + push navigation assertion

private extension View {
    @ViewBuilder
    func injectNavigationAssertionDelegate() -> some View {
        if AppEnvironment.current.isAlphaOrBetaOrDebug {
            modifier(NavigationControllerDelegateViewModifier())
        } else {
            self
        }
    }
}

private struct NavigationControllerDelegateViewModifier: ViewModifier {
    @State private var responderChainIntrospectionTrigger = UUID()

    @StateObject private var multicastDelegate = UINavigationControllerMulticastDelegate(
        customDelegate: MainCoordinatorNavigationAssertion()
    )

    func body(content: Content) -> some View {
        content
            .onAppear {
                responderChainIntrospectionTrigger = UUID()
            }
            .introspectResponderChain(
                introspectedType: UINavigationController.self,
                updateOnChangeOf: responderChainIntrospectionTrigger
            ) { [weak multicastDelegate] navigationController in
                navigationController.set(multicastDelegate: multicastDelegate)
            }
    }
}
