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

    var body: some View {
        content
            .onAppear(perform: viewModel.onViewAppear)
            .onDisappear(perform: viewModel.onViewDisappear)
            .onDidAppear(perform: viewModel.onDidAppear)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .ignoresSafeArea(.keyboard)
            .modifier(MainViewNavigationModifier(openDetailsAction: viewModel.openDetails))
    }

    @ViewBuilder
    private var content: some View {
        if FeatureProvider.isAvailable(.redesign) {
            fullPagePagerContent
                .northernLightsBackground(backgroundColor: .Tangem.Surface.level1)
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
            headerFactory: { page in
                TangemElasticContainer(
                    onAddScrollViewDelegate: viewModel.refreshScrollViewStateObject.addDelegate,
                    onRemoveScrollViewDelegate: viewModel.refreshScrollViewStateObject.removeDelegate,
                    content: { ratio in
                        page.redesignedHeader(
                            totalPages: viewModel.pages.count,
                            currentIndex: viewModel.selectedCardIndex
                        )
                        .scaleEffect(ratio)
                        .opacity(ratio)
                    }
                )
            },
            bodyFactory: { page in
                page.body
            }
        )
        .horizontalScrollDisabled(viewModel.isHorizontalScrollDisabled)
        .onPageChange(viewModel.onPageChange(dueTo:))
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

    func body(content: Content) -> some View {
        if FeatureProvider.isAvailable(.redesign) {
            content
                .tangemNavigationHeader(
                    trailingAction: openDetailsAction,
                    accessibilityIdentifiers: TangemNavigationHeader.AccessibilityIdentifiers(
                        trailingButton: MainAccessibilityIdentifiers.detailsButton,
                        trailingButtonLabel: Localization.voiceOverOpenCardDetails
                    )
                )
        } else {
            content
                .tangemLogoNavigationToolbar(trailingItem: detailsNavigationButton)
        }
    }

    private var detailsNavigationButton: some View {
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
