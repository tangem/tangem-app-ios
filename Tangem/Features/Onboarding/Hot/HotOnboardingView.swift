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
        ZStack {
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                navigationBar

                if viewModel.isProgressBarEnabled {
                    progressBar
                        .padding(.top, 4)
                        .padding(.horizontal, 8)
                }

                pageContent
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.opacity)
            }
        }
        .animation(.default, value: viewModel.currentStep)
        .background(Colors.Background.primary)
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarHidden(true)
    }
}

// MARK: - NavigationBar

private extension HotOnboardingView {
    var navigationBar: some View {
        NavigationBar(
            title: viewModel.navigationBarTitle,
            settings: NavigationBar.Settings(
                backgroundColor: .clear,
                height: viewModel.navigationBarHeight
            ),
            leftButtons: navBarLeadingButtons,
            rightButtons: navBarTrailingButtons
        )
    }

    @ViewBuilder
    func navBarLeadingButtons() -> some View {
        switch viewModel.leadingButtonStyle {
        case .back:
            BackButton(
                height: viewModel.navigationBarHeight,
                isVisible: true,
                isEnabled: true,
                action: viewModel.backButtonAction
            )
        case .close:
            CloseButton(dismiss: viewModel.onCloseTap)
                .padding(.leading, 16)
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    func navBarTrailingButtons() -> some View {
        switch viewModel.trailingButtonStyle {
        case .skip:
            skipButton
                .padding(.trailing, 16)
        case .none:
            EmptyView()
        }
    }

    var skipButton: some View {
        Button(action: viewModel.onSkipTap) {
            Text(viewModel.skipTitle)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(height: viewModel.navigationBarHeight)
        }
    }
}

// MARK: - ProgressBar

private extension HotOnboardingView {
    var progressBar: some View {
        ProgressBar(
            height: viewModel.progressBarHeight,
            currentProgress: viewModel.currentProgress
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
            case .importWallet:
                OnboardingSeedPhraseImportView(viewModel: viewModel.importWalletViewModel)
                    .padding(.top, 32)
            case .importCompleted:
                HotOnboardingSuccessView(viewModel: viewModel.importCompletedViewModel)
            case .seedPhraseIntro:
                HotOnboardingSeedPhraseIntroView(viewModel: viewModel.seedPhraseIntroViewModel)
            case .seedPhraseRecovery:
                viewModel.seedPhraseRecoveryViewModel.map {
                    HotOnboardingSeedPhraseRecoveryView(viewModel: $0)
                }
            case .seedPhraseUserValidation:
                viewModel.seedPhraseUserValidationViewModel.map {
                    OnboardingSeedPhraseUserValidationView(viewModel: $0)
                        .padding(.top, 32)
                }
            case .seedPhraseCompleted:
                HotOnboardingSuccessView(viewModel: viewModel.seedPhraseCompletedViewModel)
            case .checkAccessCode:
                HotOnboardingCheckAccessCodeView(viewModel: viewModel.checkAccessCodeViewModel)
            case .accessCode:
                HotOnboardingAccessCodeView(viewModel: viewModel.accessCodeViewModel)
            case .pushNotifications:
                PushNotificationsPermissionRequestView(
                    viewModel: viewModel.pushNotificationsViewModel,
                    topInset: 0,
                    buttonsAxis: .vertical
                )
            case .done:
                HotOnboardingSuccessView(viewModel: viewModel.doneViewModel)
            }
        }
    }
}
