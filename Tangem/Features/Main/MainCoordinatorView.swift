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
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager

    var body: some View {
        NavigationStack {
            ZStack {
                if let mainViewModel = coordinator.mainViewModel {
                    MainView(viewModel: mainViewModel)
                        .navigationLinks(links)
                        .onDidAppear { [weak coordinator] in
                            coordinator?.showMarketsTooltip()
                        }
                        .onWillDisappear { [weak coordinator] in
                            coordinator?.hideMarketsTooltipTemporarily()
                        }
                }

                sheets
            }
            .onOverlayContentStateChange(overlayContentStateObserver: overlayContentStateObserver) { [weak coordinator] state in
                mainBottomSheetUIManager.setExpanded(!state.isCollapsed)

                if !state.isCollapsed {
                    coordinator?.dismissMarketsTooltip()
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
        .overlay {
            marketsTooltipView
        }
        .mainShtorka(coordinator.shtorka)
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
            .navigation(item: $coordinator.tangemPaySelectPlanCoordinator) {
                TangemPaySelectPlanCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.yieldModulePromoCoordinator) {
                YieldModulePromoCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.mobileBackupTypesCoordinator) {
                MobileBackupTypesCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.hardwareBackupTypesCoordinator) {
                HardwareBackupTypesCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.manageTokensCoordinator) {
                ManageTokensCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.polymarketCoordinator) {
                PolymarketCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.collectiblesCoordinator) {
                CollectiblesCoordinatorView(coordinator: $0)
            }
    }

    private func tangemPayWaitlist(_ waitlist: MainCoordinator.TangemPayWaitlistPresentation) -> some View {
        NavigationStack {
            TangemPayWaitlistFactory.makeView(
                product: .paymentAccount,
                country: waitlist.region.country,
                region: waitlist.region.region,
                service: waitlist.service,
                output: { [weak coordinator] in coordinator?.handleTangemPayWaitlist($0) }
            )
            .topNavigation(
                leading: .none,
                onClose: { [weak coordinator] in coordinator?.closeTangemPayWaitlist() }
            )
        }
        .sheet(item: $coordinator.tangemPayWaitlistPrivacyPolicyViewModel) {
            WebViewContainer(viewModel: $0)
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .shtorkaCompatibleFullScreenCover(
                item: $coordinator.tangemPayOnboardingCoordinator
            ) {
                TangemPayOnboardingCoordinatorView(coordinator: $0)
            }
            .shtorkaCompatibleFullScreenCover(item: $coordinator.tangemPayCampaignCoordinator) {
                TangemPayCampaignCoordinatorView(coordinator: $0)
            }
            .shtorkaCompatibleFullScreenCover(item: $coordinator.mainQRScanFlowCoordinator) {
                MainQRScanFlowCoordinatorView(coordinator: $0)
            }
            .shtorkaCompatibleFullScreenCover(item: $coordinator.jointAccountManagementCoordinator) {
                JointAccountManagementCoordinatorView(coordinator: $0)
            }
            .shtorkaCompatibleSheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
            .shtorkaCompatibleSheet(item: $coordinator.modalOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
            }
            .shtorkaCompatibleSheet(item: $coordinator.visaTransactionDetailsViewModel) {
                VisaTransactionDetailsView(viewModel: $0)
            }
            .shtorkaCompatibleSheet(item: $coordinator.actionButtonsBuyCoordinator) {
                ActionButtonsBuyCoordinatorView(coordinator: $0)
            }
            .shtorkaCompatibleSheet(item: $coordinator.actionButtonsSellCoordinator) {
                ActionButtonsSellCoordinatorView(coordinator: $0)
            }
            .shtorkaCompatibleSheet(item: $coordinator.yieldModuleActiveCoordinator) {
                YieldModuleActiveCoordinatorView(coordinator: $0)
            }
            .shtorkaCompatibleSheet(item: $coordinator.tangemPayWaitlist) {
                tangemPayWaitlist($0)
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
            .floatingSheetContent(for: TangemPayFailedToIssueCardSheetViewModel.self) {
                TangemPayPopupView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayKYCStatusPopupViewModel.self) {
                TangemPayPopupView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayKYCDeclinedPopupViewModel.self) {
                TangemPayPopupView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayRegionUnavailablePopupViewModel.self) {
                TangemPayPopupView(viewModel: $0)
            }
            .floatingSheetContent(for: PushNotificationsMainViewModel.self) {
                PushNotificationsMainView(viewModel: $0)
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
            onHideAction: coordinator.dismissMarketsTooltip,
            title: Localization.marketsTooltipTitle,
            message: Localization.marketsTooltipMessage,
            leadingIcon: Assets.plusMini
        )
    }
}

// MARK: - Overlay content controller bottom sheet + push navigation assertion

private extension View {
    @ViewBuilder
    func injectNavigationAssertionDelegate() -> some View {
        if AppEnvironment.current.isInternalOrDebug {
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
