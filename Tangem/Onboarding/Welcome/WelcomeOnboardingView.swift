//
//  WelcomeOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeOnboardingView: View {
    
    @ObservedObject var viewModel: WelcomeOnboardingViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    @State var containerSize: CGSize = .zero
    
    var currentStep: WelcomeStep { .welcome }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    let bgSize = containerSize * 1.5
                    
                    WelcomeBackgroundView()
                        .frame(size: bgSize)
                        .offset(x: bgSize.width/3,
                                y: (containerSize.height - bgSize.height) * 0.2)
                    
                    AnimatedView(settings: viewModel.$lightCardSettings) {
                        OnboardingCardView(placeholderCardType: .light,
                                           cardImage: nil,
                                           cardScanned: false)
                    }
                    
                    AnimatedView(settings: viewModel.$darkCardSettings) {
                        OnboardingCardView(placeholderCardType: .dark,
                                           cardImage: nil,
                                           cardScanned: false)
                    }
                }
                .position(x: containerSize.width / 2, y: containerSize.height / 2)
                .readSize { size in
                    containerSize = size
                    viewModel.setupContainer(size)
                }
                
                OnboardingTextButtonView(
                    title: currentStep.title,
                    subtitle: currentStep.subtitle,
                    buttonsSettings:
                        .init(main: TangemButtonSettings(
                            title: currentStep.mainButtonTitle,
                            size: .wide,
                            action: {
                                viewModel.scanCard()
                            },
                            isBusy: viewModel.isScanningCard,
                            isEnabled: true,
                            isVisible: true
                        ),
                        supplement: TangemButtonSettings(
                            title: currentStep.supplementButtonTitle,
                            size: .wide,
                            action: {
                                navigation.readToShop = true
                                Analytics.log(.getACard, params: [.source: .welcome])
                            },
                            isBusy: false,
                            isEnabled: true,
                            isVisible: true,
                            color: .transparentWhite))
                ) {
                    
                }
                .padding(.horizontal, 40)
            }
            .actionSheet(item: $viewModel.discardAlert, content: { $0.sheet })
            
            ScanTroubleshootingView(isPresented: $navigation.readToTroubleshootingScan) {
                self.viewModel.scanCard()
            } requestSupportAction: {
                self.viewModel.failedCardScanTracker.resetCounter()
                self.navigation.readToSendEmail = true
            }
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.welcomeToBackup, content: {
                    OnboardingBaseView(viewModel: viewModel.assembly.getCardOnboardingViewModel())
                        .presentation(modal: viewModel.isBackupModal, onDismissalAttempt: {
                            viewModel.assembly.getWalletOnboardingViewModel()?.backButtonAction()
                        }, onDismissed: nil)
                        .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                            viewModel.isBackupModal = value
                        })
                        .environmentObject(navigation)
                })
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.readToSendEmail, content: {
                    MailView(dataCollector: viewModel.failedCardScanTracker, support: .tangem, emailType: .failedToScanCard)
                })
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.onboardingToDisclaimer, content: {
                    DisclaimerView(style: .sheet(acceptCallback: viewModel.acceptDisclaimer), showAccept: true)
                        .presentation(modal: true, onDismissalAttempt: nil, onDismissed: viewModel.disclaimerDismissed)
                })
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.readToShop, content: {
                    ShopView(viewModel: viewModel.assembly.makeShopViewModel())
                        .environmentObject(navigation)
                })
        }
        .alert(item: $viewModel.error, content: { $0.alert })
        .onAppear(perform: viewModel.onAppear)
    }
}

struct WelcomeOnboardingView_Previews: PreviewProvider {
    
    static let assembly: Assembly = .previewAssembly
    
    static var previews: some View {
        WelcomeOnboardingView(viewModel: assembly.getLetsStartOnboardingViewModel(with: { _ in }))
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
