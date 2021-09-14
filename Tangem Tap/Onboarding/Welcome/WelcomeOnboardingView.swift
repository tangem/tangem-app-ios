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
        ZStack {
            VStack(spacing: 0) {
                navigationLinks
                
                ZStack {
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
                    buttonsSettings: ButtonsSettings.init(
                        mainTitle: currentStep.mainButtonTitle,
                        mainSize: .wide,
                        mainAction: {
                            viewModel.scanCard()
                        },
                        mainIsBusy: viewModel.isScanningCard,
                        supplementTitle: currentStep.supplementButtonTitle,
                        supplementSize: .wide,
                        supplementAction: {
                            navigation.readToShop = true
                        },
                        isVisible: true,
                        containSupplementButton: true
                    )) {
                    
                }
                .padding(.horizontal, 40)
                .sheet(isPresented: $navigation.onboardingToDisclaimer, content: {
                    DisclaimerView(style: .sheet(acceptCallback: viewModel.acceptDisclaimer))
                        .presentation(modal: true, onDismissalAttempt: nil, onDismissed: viewModel.disclaimerDismissed)
                })
            }
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
