//
//  WalletOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WalletOnboardingView: View {
    @State private var isModallyPresented: Bool = false

    @ObservedObject var viewModel: WalletOnboardingViewModel

    private let screenSize: CGSize = UIScreen.main.bounds.size
    private let infoPagerHeight: CGFloat = 156

    var currentStep: WalletOnboardingStep {
        viewModel.currentStep
    }

    var isNavbarVisible: Bool {
        viewModel.isNavBarVisible
    }

    var isProgressBarVisible: Bool {
        if !viewModel.isInitialAnimPlayed {
            return false
        }

        return true
    }

    var secondCardPlaceholder: OnboardingCardView.CardType {
        .dark
    }

    @ViewBuilder
    var customContent: some View {
        switch viewModel.currentStep {
        case .saveUserWallet:
            UserWalletStorageAgreementView(
                viewModel: viewModel.userWalletStorageAgreementViewModel,
                source: .backupCard,
                topInset: -viewModel.progressBarPadding
            )
        case .seedPhraseIntro:
            OnboardingSeedPhraseIntroView(
                readMoreAction: viewModel.openReadMoreAboutSeedPhraseScreen,
                generateSeedAction: viewModel.generateSeedPhrase,
                importWalletAction: viewModel.supplementButtonAction
            )
        case .seedPhraseGeneration:
            if let model = viewModel.generateSeedPhraseModel {
                OnboardingSeedPhraseGenerateView(viewModel: model)
            }
        case .seedPhraseImport:
            if let model = viewModel.importSeedPhraseModel {
                OnboardingSeedPhraseImportView(viewModel: model)
            }
        case .seedPhraseUserValidation:
            if let model = viewModel.validationUserSeedPhraseModel {
                OnboardingSeedPhraseUserValidationView(viewModel: model)
            }
        case .addTokens:
            if let model = viewModel.addTokensViewModel {
                OnboardingAddTokensView(viewModel: model)
            }
        case .pushNotifications:
            if let pushNotificationsViewModel = viewModel.pushNotificationsViewModel {
                PushNotificationsPermissionRequestView(
                    viewModel: pushNotificationsViewModel,
                    topInset: -viewModel.progressBarPadding,
                    buttonsAxis: .vertical
                )
            }
        case .mobileUpgradeBiometrics:
            UserWalletStorageAgreementView(
                viewModel: viewModel.userWalletStorageAgreementViewModel,
                source: .upgradeMobile,
                topInset: -viewModel.progressBarPadding
            )
        default:
            EmptyView()
        }
    }

    private var contentTopPadding: CGFloat {
        isModallyPresented ? .unit(.x4) : 0
    }

    var body: some View {
        ZStack {
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)
                .frame(maxWidth: screenSize.width)
                .zIndex(110)

            VStack(spacing: 0) {
                GeometryReader { geom in
                    let size = geom.size
                    ZStack(alignment: .center) {
                        Circle()
                            .foregroundColor(Colors.Button.secondary)
                            .frame(size: viewModel.isInitialAnimPlayed ? currentStep.cardBackgroundFrame(containerSize: size) : .zero)
                            .offset(viewModel.isInitialAnimPlayed ? currentStep.backgroundOffset(in: size) : .zero)
                            .opacity(viewModel.isCustomContentVisible ? 0 : 1)

                        // Navbar is added to ZStack instead of VStack because of wrong animation when container changed
                        // and cards jumps instead of smooth transition
                        NavigationBar(
                            title: viewModel.navbarTitle,
                            settings: .init(
                                title: .init(font: .system(size: 17, weight: .semibold)),
                                backgroundColor: .clear
                            ),
                            leftButtons: {
                                NavigationBarButton.back(action: viewModel.backButtonAction)
                                    .padding(.leading, .unit(.x4))
                                    .visible(viewModel.isBackButtonVisible)
                                    .disabled(!viewModel.isBackButtonEnabled)
                                    .redesigned()
                            },
                            rightButtons: {
                                SupportButton(
                                    height: viewModel.navbarSize.height,
                                    isVisible: viewModel.isSupportButtonVisible,
                                    isEnabled: true
                                ) {
                                    viewModel.openSupport()
                                }
                            }
                        )
                        .offset(x: 0, y: -geom.size.height / 2 + (isNavbarVisible ? viewModel.navbarSize.height / 2 + 4 : 0))
                        .opacity(isNavbarVisible ? 1.0 : 0.0)

                        ProgressBar(height: viewModel.progressBarHeight, currentProgress: viewModel.currentProgress)
                            .opacity(isProgressBarVisible ? 1.0 : 0.0)
                            .frame(width: screenSize.width - 32)
                            .offset(x: 0, y: -size.height / 2 + viewModel.navbarSize.height + viewModel.progressBarPadding)

                        if !viewModel.isCustomContentVisible {
                            AnimatedView(settings: viewModel.$thirdCardSettings) {
                                OnboardingCardView(
                                    placeholderCardType: secondCardPlaceholder,
                                    cardImage: viewModel.thirdImage,
                                    cardScanned: viewModel.canShowThirdCardImage && (viewModel.backupCardsAddedCount >= 2 || currentStep == .backupIntro) && viewModel.canDisplayCardImage
                                )
                            }

                            AnimatedView(settings: viewModel.$supplementCardSettings) {
                                OnboardingCardView(
                                    placeholderCardType: secondCardPlaceholder,
                                    cardImage: viewModel.secondImage,
                                    cardScanned: (viewModel.backupCardsAddedCount >= 1 || currentStep == .backupIntro) && viewModel.canDisplayCardImage
                                )
                            }

                            AnimatedView(settings: viewModel.$mainCardSettings) {
                                ZStack(alignment: .topTrailing) {
                                    OnboardingCardView(
                                        placeholderCardType: .dark,
                                        cardImage: viewModel.mainImage,
                                        cardScanned: viewModel.isInitialAnimPlayed
                                    )
                                    Text(viewModel.primaryLabel)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 5)
                                        .background(Color(hex: "575757"))
                                        .cornerRadius(50)
                                        .zIndex(251)
                                        .padding(12)
                                        .opacity(viewModel.canShowOriginCardLabel ? 1.0 : 0.0)
                                }
                            }

                            OnboardingCircleButton(
                                refreshAction: {},
                                state: currentStep.successCircleState,
                                size: .huge
                            )
                            .offset(y: 8)
                            .opacity(currentStep.successCircleOpacity)

                            if viewModel.isInfoPagerVisible {
                                OnboardingWalletInfoPager(animated: viewModel.isInfoPagerVisible)
                                    .offset(.init(width: 0, height: size.height / 2 + infoPagerHeight / 2))
                                    .frame(height: infoPagerHeight)
                                    .zIndex(150)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .position(x: size.width / 2, y: size.height / 2)
                }
                .readGeometry(\.size) { size in
                    if !viewModel.isCustomContentVisible {
                        viewModel.setupContainer(with: size)
                    }
                }
                .frame(minHeight: viewModel.navbarSize.height + 20)

                if viewModel.isCustomContentVisible {
                    customContent
                        .layoutPriority(1)
                        .readGeometry(\.size) { size in
                            viewModel.setupContainer(with: size)
                        }
                }

                if !viewModel.isCustomContentVisible {
                    OnboardingTextButtonView(
                        title: viewModel.title,
                        subtitle: viewModel.subtitle,
                        textOffset: currentStep.messagesOffset,
                        buttonsSettings: .init(
                            main: viewModel.mainButtonSettings,
                            supplement: viewModel.supplementButtonSettings
                        ),
                        infoText: viewModel.infoText
                    ) {
                        viewModel.closeOnboarding()
                    }
                    .padding(.top, 8)

                    if viewModel.isTosFooterVisible {
                        OnboardingTermsOfServiceFooter(onTap: viewModel.onTosTap)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                }
            }
            .padding(.top, contentTopPadding)
        }
        .alert(item: $viewModel.alert, content: { alertBinder in
            alertBinder.alert
        })
        .preference(key: ModalSheetPreferenceKey.self, value: viewModel.isModal)
        .onAppear(perform: viewModel.onAppear)
        .onModalDetection { isModallyPresented = $0 }
        .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    NavigationStack {
        WalletOnboardingView(
            viewModel: .init(
                input: OnboardingInput(
                    backupService: .init(sdk: .init(), networkService: .init(session: .shared, additionalHeaders: [:])),
                    primaryCardId: "",
                    cardInitializer: nil,
                    pushNotificationsPermissionManager: PushNotificationsPermissionManagerStub(),
                    steps: .wallet([.createWallet, .backupIntro, .selectBackupCards, .backupCards, .success]),
                    cardInput: .cardInfo(PreviewCard.tangemWalletEmpty.cardInfo),
                    twinData: nil
                ),
                coordinator: OnboardingCoordinator()
            )
        )
    }
}
