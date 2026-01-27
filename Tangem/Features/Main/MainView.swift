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
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
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
                                Button(
                                    action: weakify(viewModel, forFunction: MainViewModel.didTapEditWallet),
                                    label: editButtonLabel
                                )
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
        .onAppear(perform: viewModel.onViewAppear)
        .onDisappear(perform: viewModel.onViewDisappear)
        .onDidAppear(perform: viewModel.onDidAppear)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(.keyboard)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Assets.newTangemLogo.image
                    .foregroundColor(Colors.Icon.primary1)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                detailsNavigationButton
            }
        })
        .confirmationDialog(viewModel: $viewModel.confirmationDialog)
    }

    var detailsNavigationButton: some View {
        Button(action: weakify(viewModel, forFunction: MainViewModel.openDetails)) {
            NavbarDotsImage()
                .disableAnimations() // Try fix unexpected animations [REDACTED_INFO]
        }
        .buttonStyle(PlainButtonStyle())
        .disableAnimations() // Try fix unexpected animations [REDACTED_INFO]
        .accessibility(label: Text(Localization.voiceOverOpenCardDetails))
        .accessibilityIdentifier(MainAccessibilityIdentifiers.detailsButton)
    }

    private func editButtonLabel() -> some View {
        HStack {
            Text(Localization.commonRename)
            Image(systemName: "pencil")
        }
    }

    private func deleteButtonLabel() -> some View {
        HStack {
            Text(Localization.commonDelete)
            Image(systemName: "trash")
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
