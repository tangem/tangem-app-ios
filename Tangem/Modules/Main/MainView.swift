//
//  MainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import AlertToast

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        CardsInfoPagerView(
            data: viewModel.pages,
            selectedIndex: $viewModel.selectedCardIndex,
            discoveryAnimationTrigger: viewModel.swipeDiscoveryAnimationTrigger,
            headerFactory: { info in
                info.header
                    .contextMenu {
                        if !info.isLockedWallet {
                            Button(action: weakify(viewModel, forFunction: MainViewModel.didTapEditWallet), label: editButtonLabel)

                            Button(role: .destructive, action: weakify(viewModel, forFunction: MainViewModel.didTapDeleteWallet), label: deleteButtonLabel)
                        }
                    }
            },
            contentFactory: { info in
                info.body
            },
            bottomOverlayFactory: { info, didScrollToBottom in
                info.makeBottomOverlay(
                    isMainBottomSheetEnabled: viewModel.isMainBottomSheetEnabled,
                    didScrollToBottom: didScrollToBottom
                )
            },
            onPullToRefresh: viewModel.onPullToRefresh(completionHandler:)
        )
        .pageSwitchThreshold(0.4)
        .contentViewVerticalOffset(64.0)
        .horizontalScrollDisabled(viewModel.isHorizontalScrollDisabled)
        .onPageChange(viewModel.onPageChange(dueTo:))
        .onAppear(perform: viewModel.onViewAppear)
        .onDisappear(perform: viewModel.onViewDisappear)
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
        .actionSheet(item: $viewModel.actionSheet) { $0.sheet }
        .bottomSheet(
            item: $viewModel.unlockWalletBottomSheetViewModel,
            backgroundColor: Colors.Background.primary
        ) { model in
            UnlockUserWalletBottomSheetView(viewModel: model)
        }
        .toast(isPresenting: $viewModel.showAddressCopiedToast) {
            AlertToast(type: .complete(Colors.Icon.accent), title: Localization.walletNotificationAddressCopied)
        }
    }

    var detailsNavigationButton: some View {
        Button(action: weakify(viewModel, forFunction: MainViewModel.openDetails)) {
            NavbarDotsImage()
        }
        .buttonStyle(PlainButtonStyle())
        .animation(nil)
        .accessibility(label: Text(Localization.voiceOverOpenCardDetails))
    }

    @ViewBuilder
    private func editButtonLabel() -> some View {
        HStack {
            Text(Localization.commonRename)
            Image(systemName: "pencil")
        }
    }

    @ViewBuilder
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
            mainUserWalletPageBuilderFactory: CommonMainUserWalletPageBuilderFactory(coordinator: coordinator)
        )
        swipeDiscoveryHelper.delegate = viewModel

        return viewModel
    }()

    static var previews: some View {
        NavigationView {
            MainView(viewModel: viewModel)
        }
    }
}
