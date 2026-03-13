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
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.overlayCollapsedHeight) private var overlayCollapsedHeight

    @State private var redesignedHeaderHeightRatio: CGFloat?

    var body: some View {
        content
            .onAppear(perform: viewModel.onViewAppear)
            .onDisappear(perform: viewModel.onViewDisappear)
            .onDidAppear(perform: viewModel.onDidAppear)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .ignoresSafeArea(.keyboard)
            .modifier(MainViewNavigationModifier(openDetailsAction: viewModel.openDetails, openQRScanAction: viewModel.openQRScan))
    }

    @ViewBuilder
    private var content: some View {
        if FeatureProvider.isAvailable(.redesign) {
            fullPagePagerContent
                .northernLightsBackground(backgroundColor: .Tangem.Surface.level2)
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
            headerFactory: { pageBuilder in
                TangemElasticContainer(
                    onAddScrollViewObserver: viewModel.refreshScrollViewStateObject.addObserver,
                    onRemoveScrollViewObserver: viewModel.refreshScrollViewStateObject.removeObserver,
                    content: makeRedesignedHeader(pageBuilder: pageBuilder)
                )
                .onPreferenceChange(TangemElasticContainerHeightRatio.self) { redesignedHeaderHeightRatio = $0 }
            },
            bodyFactory: { page in
                page.body
            }
        )
        .horizontalScrollDisabled(viewModel.isHorizontalScrollDisabled)
        .onPageChange(viewModel.onPageChange(dueTo:))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: overlayCollapsedHeight)
        }
    }

    private func makeRedesignedHeader(pageBuilder: MainUserWalletPageBuilder) -> some View {
        let scale: CGFloat = max(0.5, redesignedHeaderHeightRatio ?? 1.0)
        let opacity: CGFloat = redesignedHeaderHeightRatio ?? 1.0

        return pageBuilder.redesignedHeader(
            totalPages: viewModel.pages.count,
            currentIndex: viewModel.selectedCardIndex
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .animation(.default, value: redesignedHeaderHeightRatio)
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
        if FeatureProvider.isAvailable(.redesign) {
            content
                .tangemLogoNavigationToolbar(
                    secondaryTrailingAction: TangemNavigationHeader.ActionInfo(
                        action: openQRScanAction,
                        accessibilityIdentifier: MainAccessibilityIdentifiers.scanQrButton,
                        accessibilityLabel: Localization.voiceOverOpenNewWalletConnectSession
                    ),
                    trailingAction: TangemNavigationHeader.ActionInfo(
                        action: openDetailsAction,
                        accessibilityIdentifier: MainAccessibilityIdentifiers.detailsButton,
                        accessibilityLabel: Localization.voiceOverOpenCardDetails
                    )
                )
        } else {
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
