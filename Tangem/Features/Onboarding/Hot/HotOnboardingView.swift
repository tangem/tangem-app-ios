//
//  HotOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct HotOnboardingView: View {
    @ObservedObject var viewModel: HotOnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            navBar
            pageContent
        }
        .background(Colors.Background.primary)
        .navigationBarHidden(true)
    }
}

// MARK: - navBar

private extension HotOnboardingView {
    var navBar: some View {
        NavigationBar(
            title: viewModel.navigationBarTitle,
            settings: NavigationBar.Settings(backgroundColor: .clear),
            leftButtons: navBarLeadingButtons
        )
    }

    func navBarLeadingButtons() -> some View {
        BackButton(
            height: viewModel.navigationBarHeight,
            isVisible: true,
            isEnabled: true,
            action: viewModel.backButtonAction
        )
    }
}

// MARK: - pageContent

private extension HotOnboardingView {
    var pageContent: some View {
        ZStack {
            switch viewModel.currentStep {
            case .createWallet:
                HotOnboardingCreateWalletView(viewModel: viewModel.createWalletViewModel)
                    .padding(.bottom, 14)
                    .transition(.opacity)
            case .importWallet:
                EmptyView()
            }
        }
        .padding(.horizontal, 16)
        .animation(.default, value: viewModel.currentStep)
    }
}
