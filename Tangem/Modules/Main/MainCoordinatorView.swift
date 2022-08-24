//
//  MainCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MainCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MainCoordinator

    var body: some View {
        ZStack {
            if let model = coordinator.mainViewModel {
                MainView(viewModel: model)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.pushedWebViewModel) {
                WebViewContainer(viewModel: $0)
            }
            .navigation(item: $coordinator.tokenDetailsCoordinator) {
                TokenDetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.currencySelectViewModel) {
                CurrencySelectView(viewModel: $0)
            }
            .navigation(item: $coordinator.detailsCoordinator) {
                DetailsCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.pushTxCoordinator) {
                PushTxCoordinatorView(coordinator: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.modalWebViewModel) {
                WebViewContainer(viewModel: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.tokenListCoordinator) {
                TokenListCoordinatorView(coordinator: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.modalOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
            }

        NavHolder()
            .bottomSheet(item: $coordinator.addressQrBottomSheetContentViewVodel,
                         viewModelSettings: .qr) {
                AddressQrBottomSheetContent(viewModel: $0)
            }

        NavHolder()
            .bottomSheet(item: $coordinator.warningBankCardViewModel,
                         viewModelSettings: .warning) {
                WarningBankCardView(viewModel: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.userWalletStorageAgreementViewModel) {
                UserWalletStorageAgreementView(viewModel: $0)
            }

        NavHolder()
            .resizableBottomSheet(isPresented: $coordinator.userWalletListPresented, viewModelSettings: BottomSheetSettings(showClosedButton: false, contentBackgroundColor: UserWalletListView.sheetBackground)) {
                UserWalletListView(viewModel: UserWalletListViewModel(coordinator: coordinator.userWalletListCoordinator!))
            }
    }
}
