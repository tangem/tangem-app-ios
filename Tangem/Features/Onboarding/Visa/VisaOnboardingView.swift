//
//  VisaOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
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
        .background(Colors.Background.primary)
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
                leftButtons: {
                    switch viewModel.leftButtonType {
                    case .back:
                        BackButton(
                            height: viewModel.navigationBarHeight,
                            isVisible: true,
                            isEnabled: true,
                            action: viewModel.backButtonAction
                        )
                    case .close:
                        OnboardingCloseButton(
                            height: viewModel.navigationBarHeight,
                            action: viewModel.closeButtonAction
                        )
                    case .none:
                        EmptyView()
                    }

                },
                rightButtons: {
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
        case .welcome, .welcomeBack:
            VisaOnboardingWelcomeView(viewModel: viewModel.welcomeViewModel)
        case .accessCode:
            VisaOnboardingAccessCodeSetupView(viewModel: viewModel.accessCodeSetupViewModel)
        case .selectWalletForApprove:
            VisaOnboardingApproveWalletSelectorView(viewModel: viewModel.walletSelectorViewModel)
        case .approveUsingTangemWallet:
            if let viewModel = viewModel.tangemWalletApproveViewModel {
                VisaOnboardingTangemWalletDeployApproveView(viewModel: viewModel)
            }
        case .approveUsingWalletConnect:
            if let viewModel = viewModel.walletConnectViewModel {
                VisaOnboardingWalletConnectView(viewModel: viewModel)
            }
        case .paymentAccountDeployInProgress, .issuerProcessingInProgress:
            if let viewModel = viewModel.inProgressViewModel {
                VisaOnboardingInProgressView(viewModel: viewModel)
            }
        case .pinSelection:
            OnboardingPinView(viewModel: viewModel.pinSelectionViewModel)
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
            VisaOnboardingSuccessView(
                fireConfetti: $viewModel.shouldFireConfetti,
                finishAction: viewModel.finishOnboarding
            )
        }
    }
}

extension VisaOnboardingView {
    enum LeftButtonType {
        case back
        case close
    }
}

#if DEBUG
#Preview {
    VisaOnboardingView(viewModel: .mock)
}
#endif // DEBUG
