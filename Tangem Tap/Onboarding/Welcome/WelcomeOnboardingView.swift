//
//  WelcomeOnboardingView.swift
//  Tangem Tap
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
    
    @ViewBuilder
    var navigationLinks: some View {
        NavigationLink(destination: WebViewContainer(url: viewModel.shopURL, title: "home_button_shop"),
                       isActive: $navigation.readToShop)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            navigationLinks
            
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
                        },
                        isBusy: false,
                        isEnabled: true,
                        isVisible: true,
                        color: .transparentWhite))
            ) {
                
            }
            .padding(.horizontal, 40)
            .sheet(isPresented: $navigation.onboardingToDisclaimer, content: {
                DisclaimerView(style: .sheet(acceptCallback: viewModel.acceptDisclaimer), showAccept: true)
                    .presentation(modal: true, onDismissalAttempt: nil, onDismissed: viewModel.disclaimerDismissed)
            })
            ScanTroubleshootingView(isPresented: $navigation.readToTroubleshootingScan) {
                self.viewModel.scanCard()
            } requestSupportAction: {
                self.viewModel.failedCardScanTracker.resetCounter()
                self.navigation.readToSendEmail = true
            }
            .sheet(isPresented: $navigation.readToSendEmail, content: {
                MailView(dataCollector: viewModel.failedCardScanTracker, support: .tangem, emailType: .failedToScanCard)
            })
        }
        .alert(item: $viewModel.error, content: { error in
            error.alert
        })
        .navigationBarHidden(true)
    }
}

struct WelcomeOnboardingView_Previews: PreviewProvider {
    
    static let assembly: Assembly = .previewAssembly
    
    static var previews: some View {
        WelcomeOnboardingView(viewModel: assembly.getLetsStartOnboardingViewModel(with: { _ in }))
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
