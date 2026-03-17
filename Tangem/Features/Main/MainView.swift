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

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.overlayCollapsedHeight) private var overlayCollapsedHeight

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
        if FeatureProvider.isAvailable(.redesign) {
            fullPagePagerContent
                .modifier(RedesignedBackgroundModifier(headerHeightRatioPublisher: viewModel.headerHeightRatioPublisher))
        } else {
            cardsInfoPagerContent
                .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        }
    }

    private var fullPagePagerContent: some View {
        FullPagePagerView(
            data: viewModel.pages,
            refreshScrollViewStateObject: viewModel.refreshScrollViewStateObject,
            selectedIndex: $viewModel.selectedCardIndex,
            navigationFactory: makeRedesignedNavigation,
            headerFactory: makeRedesignedHeader,
            bodyFactory: makeRedesignedBody
        )
        .horizontalScrollDisabled(viewModel.isHorizontalScrollDisabled)
        .onHeaderHeightRatioChange(viewModel.onHeaderHeightRatioChange)
        .onPageChange(viewModel.onPageChange(dueTo:))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: overlayCollapsedHeight)
        }
    }

    private func makeRedesignedNavigation(pageBuilder: MainUserWalletPageBuilder) -> some ViewModifier {
        RedesignedNavigationModifier(
            openDetailsAction: viewModel.openDetails,
            openQRScanAction: viewModel.openQRScan,
            headerHeightRatioPublisher: viewModel.headerHeightRatioPublisher,
            pageBuilder: pageBuilder
        )
    }

    private func makeRedesignedHeader(pageBuilder: MainUserWalletPageBuilder) -> some View {
        pageBuilder.redesignedHeader(
            totalPages: viewModel.pages.count,
            currentIndex: viewModel.selectedCardIndex
        )
    }

    private func makeRedesignedBody(pageBuilder: MainUserWalletPageBuilder) -> some View {
        pageBuilder.body
    }

    private var cardsInfoPagerContent: some View {
        CardsInfoPagerView(
            data: viewModel.pages,
            refreshScrollViewStateObject: viewModel.refreshScrollViewStateObject,
            selectedIndex: $viewModel.selectedCardIndex,
            discoveryAnimationTrigger: viewModel.swipeDiscoveryAnimationTrigger,
            headerFactory: { info in
                info.header
                    .contextMenu {
                        if !info.isLockedWallet {
                            if AppSettings.shared.saveUserWallets {
                                renameButton
                            }
                        }
                    }
            },
            contentFactory: { info in
                info.body
            },
            bottomOverlayFactory: { info, overlayParams in
                info.makeBottomOverlay(overlayParams)
            }
        )
        .pageSwitchThreshold(0.4)
        .contentViewVerticalOffset(64.0)
        .horizontalScrollDisabled(viewModel.isHorizontalScrollDisabled)
        .onPageChange(viewModel.onPageChange(dueTo:))
        .modifier(MainViewNavigationModifier(openDetailsAction: viewModel.openDetails, openQRScanAction: viewModel.openQRScan))
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

struct MainView_Preview: PreviewProvider {
    static let viewModel: MainViewModel = {
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

    static var previews: some View {
        NavigationStack {
            MainView(viewModel: viewModel)
        }
    }
}
