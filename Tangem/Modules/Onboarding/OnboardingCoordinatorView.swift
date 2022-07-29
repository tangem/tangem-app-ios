//
//  OnboardingCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct OnboardingCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: OnboardingCoordinator

    var body: some View {
        ZStack {
            content
                .transition(.withoutOpacity)
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarHidden(true)

            NavHolder()
                .sheet(item: $coordinator.buyCryptoModel) {
                    WebViewContainer(viewModel: $0)
                }

            NavHolder()
                .sheet(item: $coordinator.accessCodeModel) {
                    OnboardingAccessCodeView(viewModel: $0)
                }

            NavHolder()
                .bottomSheet(item: $coordinator.addressQrBottomSheetContentViewVodel, viewModelSettings: .qr) {
                    AddressQrBottomSheetContent(viewModel: $0)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let singleCardViewModel = coordinator.singleCardViewModel {
            SingleCardOnboardingView(viewModel: singleCardViewModel)
        } else if let twinsViewModel = coordinator.twinsViewModel {
            TwinsOnboardingView(viewModel: twinsViewModel)
        } else if let walletViewModel = coordinator.walletViewModel {
            WalletOnboardingView(viewModel: walletViewModel)
        }
    }
}
