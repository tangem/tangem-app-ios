//
//  VisaOnboardingView.swift
//  Tangem
//
//  Created by Andrew Son on 28.10.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaOnboardingView: View {
    @ObservedObject var viewModel: VisaOnboardingViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    var body: some View {
        ZStack {
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)
                .frame(maxWidth: mainWindowSize.width)
                .frame(maxHeight: mainWindowSize.height)
                .zIndex(110)

            VStack(spacing: 0) {
                navigationView

                pageContent
                    .transition(.opacity)
            }
        }
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var navigationView: some View {
        VStack(spacing: 8) {
            NavigationBar(
                title: viewModel.navigationBarTitle,
                settings: .init(
                    title: .init(font: Fonts.RegularStatic.body),
                    backgroundColor: .clear
                ),
                leftItems: {
                    BackButton(
                        height: viewModel.navigationBarHeight,
                        isVisible: viewModel.isBackButtonVisible,
                        isEnabled: viewModel.isBackButtonEnabled,
                        action: viewModel.backButtonAction
                    )
                },
                rightItems: {
                    SupportButton(
                        height: viewModel.navigationBarHeight,
                        isVisible: viewModel.isSupportButtonVisible,
                        isEnabled: true,
                        action: viewModel.openSupport
                    )
                }
            )

            ProgressBar(
                height: viewModel.progressBarHeight,
                currentProgress: viewModel.currentProgress
            )
            .padding(.horizontal, viewModel.progressBarPadding)
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            VisaOnboardingWelcomeView(viewModel: viewModel.welcomeViewModel)
        case .saveUserWallet:
            UserWalletStorageAgreementView(
                viewModel: viewModel.userWalletStorageAgreementViewModel,
                topInset: -viewModel.progressBarPadding
            )
        case .pushNotifications:
            if let pushNotificationsViewModel = viewModel.pushNotificationsViewModel {
                PushNotificationsPermissionRequestView(
                    viewModel: pushNotificationsViewModel,
                    topInset: -viewModel.progressBarPadding,
                    buttonsAxis: .vertical
                )
            }
        case .success:
            EmptyView()
        }
    }
}

#Preview {
    VisaOnboardingView(viewModel: .mock)
}