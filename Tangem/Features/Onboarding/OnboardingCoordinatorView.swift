//
//  OnboardingCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct OnboardingCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: OnboardingCoordinator

    private let bottomSheetBackground = Colors.Background.primary

    var body: some View {
        ZStack {
            content
            sheets
        }
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.viewState {
        case .singleCard(let singleCardOnboardingViewModel):
            SingleCardOnboardingView(viewModel: singleCardOnboardingViewModel)
        case .twins(let twinsOnboardingViewModel):
            TwinsOnboardingView(viewModel: twinsOnboardingViewModel)
        case .wallet(let walletOnboardingViewModel):
            WalletOnboardingView(viewModel: walletOnboardingViewModel)
        case .visa(let visaViewModel):
            VisaOnboardingView(viewModel: visaViewModel)
        case .hot(let hotViewModel):
            HotOnboardingView(viewModel: hotViewModel)
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.accessCodeModel) {
                OnboardingAccessCodeView(viewModel: $0)
            }
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
            .fullScreenCover(item: $coordinator.supportChatViewModel) {
                SupportChatView(viewModel: $0)
                    .edgesIgnoringSafeArea(.vertical)
            }
            .sheet(item: $coordinator.modalWebViewModel) {
                WebViewContainer(viewModel: $0)
            }

        NavHolder()
            .bottomSheet(item: $coordinator.addressQrBottomSheetContentViewModel, backgroundColor: bottomSheetBackground) {
                AddressQrBottomSheetContent(viewModel: $0)
            }
    }
}
