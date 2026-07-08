//
//  MainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemAccessibilityIdentifiers
import TangemFoundation
import TangemUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        content
            .onAppear(perform: viewModel.onViewAppear)
            .onDisappear(perform: viewModel.onViewDisappear)
            .onDidAppear(perform: viewModel.onDidAppear)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .ignoresSafeArea(.keyboard)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isRedesignEnabled {
            MainHorizontalPagingScrollView(
                userWalletPageBuilders: viewModel.pages,
                selectedCardIndex: $viewModel.selectedCardIndex,
                onSelectedCardChanged: viewModel.onPageChange,
                pullToRefreshAction: viewModel.pullToRefresh,
                isPullToRefreshRunning: viewModel.isPullToRefreshRunning,
                scanQRCodeAction: viewModel.openQRScan,
                detailsAction: viewModel.openDetails
            )
        } else {
            cardsInfoPagerContent
                .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        }
    }

    @ViewBuilder
    private var cardsInfoPagerContent: some View {
        if let discoveryAnimationTrigger = viewModel.swipeDiscoveryAnimationTrigger {
            CardsInfoPagerView(
                data: viewModel.pages,
                refreshScrollViewStateObject: viewModel.refreshScrollViewStateObject,
                selectedIndex: $viewModel.selectedCardIndex,
                discoveryAnimationTrigger: discoveryAnimationTrigger,
                headerViewBuilder: { userWalletPageBuilder in
                    userWalletPageBuilder.header
                        .contextMenu {
                            if !userWalletPageBuilder.isLockedWallet {
                                if AppSettings.shared.saveUserWallets {
                                    renameButton
                                }
                            }
                        }
                },
                contentViewBuilder: { userWalletPageBuilder in
                    userWalletPageBuilder.content
                },
                bottomOverlayViewBuilder: { userWalletPageBuilder in
                    userWalletPageBuilder.bottomOverlay
                },
                footerOverlayViewBuilder: { userWalletPageBuilder in
                    userWalletPageBuilder.footerOverlay
                }
            )
            .pageSwitchThreshold(0.4)
            .contentViewVerticalOffset(64.0)
            .horizontalScrollDisabled(viewModel.isPullToRefreshRunning)
            .onPageChange(viewModel.onPageChange(dueTo:))
            .modifier(MainViewNavigationModifier(openDetailsAction: viewModel.openDetails, openQRScanAction: viewModel.openQRScan))
        }
    }

    private var renameButton: some View {
        Button(action: weakify(viewModel, forFunction: MainViewModel.didTapEditWallet)) {
            HStack {
                Text(Localization.commonRename)
                Image(systemName: "pencil")
            }
        }
    }
}

// MARK: - Navigation Modifier

private struct MainViewNavigationModifier: ViewModifier {
    let openDetailsAction: () -> Void
    let openQRScanAction: () -> Void

    func body(content: Content) -> some View {
        content
            .tangemLogoNavigationToolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: openQRScanAction) {
                        Assets.Glyphs.scanQrIcon.image
                            .renderingMode(.template)
                            .foregroundColor(Colors.Icon.primary1)
                    }
                    .buttonStyle(.plain)
                    .disableAnimations() // Try fix unexpected animations [REDACTED_INFO]
                    .accessibility(label: Text(Localization.voiceOverOpenNewWalletConnectSession))
                    .accessibilityIdentifier(MainAccessibilityIdentifiers.scanQrButton)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: openDetailsAction) {
                        NavbarDotsImage()
                            .disableAnimations() // Try fix unexpected animations [REDACTED_INFO]
                    }
                    .buttonStyle(.plain)
                    .disableAnimations() // Try fix unexpected animations [REDACTED_INFO]
                    .accessibility(label: Text(Localization.voiceOverOpenCardDetails))
                    .accessibilityIdentifier(MainAccessibilityIdentifiers.detailsButton)
                }
            }
    }
}

#Preview {
    let viewModel: MainViewModel = {
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository()
        let coordinator = MainCoordinator()
        let swipeDiscoveryHelper = WalletSwipeDiscoveryHelper()
        let viewModel = MainViewModel(
            coordinator: coordinator,
            swipeDiscoveryHelper: swipeDiscoveryHelper,
            mainUserWalletPageBuilderFactory: CommonMainUserWalletPageBuilderFactory(coordinator: coordinator),
            pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProviderStub()
        )

        swipeDiscoveryHelper.delegate = viewModel

        return viewModel
    }()

    NavigationStack {
        MainView(viewModel: viewModel)
    }
}
