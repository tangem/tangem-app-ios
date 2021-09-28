//
//  WalletOnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletOnboardingView: View {
    
    @ObservedObject var viewModel: WalletOnboardingViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    private let screenSize: CGSize = UIScreen.main.bounds.size
    
    var currentStep: WalletOnboardingStep {
        viewModel.currentStep
    }
    
    var isNavbarVisible: Bool {
        viewModel.isNavBarVisible
    }
    
    var isProgressBarVisible: Bool {
        if case .welcome = currentStep {
            return false
        }
        
        if !viewModel.isInitialAnimPlayed {
            return false
        }
        
        return true
    }
    
    var navigationLinks: some View {
        VStack {
            NavigationLink(destination: WebViewContainer.shopView,
                           isActive: $navigation.onboardingWalletToShop)
        }
    }
    
    var body: some View {
        ZStack {
            navigationLinks
            
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)
                .frame(maxWidth: screenSize.width)
                .zIndex(110)
            
            VStack(spacing: 0) {
                GeometryReader { geom in
                    let size = geom.size
                    ZStack(alignment: .center) {
                        Circle()
                            .foregroundColor(.tangemTapBgGray)
                            .frame(size: currentStep.backgroundFrameSize(in: size))
                            .offset(currentStep.backgroundOffset(in: size))
                        
                        // Navbar is added to ZStack instead of VStack because of wrong animation when container changed
                        // and cards jumps instead of smooth transition
                        NavigationBar(title: viewModel.navbarTitle,
                                      settings: .init(titleFont: .system(size: 17, weight: .semibold), backgroundColor: .clear),
                                      leftButtons: {
                                        BackButton(height: viewModel.navbarSize.height,
                                                   isVisible: viewModel.isBackButtonVisible,
                                                   isEnabled: viewModel.isBackButtonEnabled) {
                                            viewModel.backButtonAction()
                                        }
                                      })
                            .offset(x: 0, y: -geom.size.height / 2 + (isNavbarVisible ? viewModel.navbarSize.height / 2 : 0))
                            .opacity(isNavbarVisible ? 1.0 : 0.0)
                        
                        ProgressBar(height: 5, currentProgress: viewModel.currentProgress)
                            .opacity(isProgressBarVisible ? 1.0 : 0.0)
                            .frame(width: screenSize.width - 32)
                            .offset(x: 0, y: -size.height / 2 + viewModel.navbarSize.height + 10)
                        
                        AnimatedView(settings: viewModel.$thirdCardSettings) {
                            OnboardingCardView(placeholderCardType: .dark,
                                               cardImage: viewModel.mainCardImage,
                                               cardScanned: viewModel.backupCardsAddedCount >= 2)
                        }
                        
                        AnimatedView(settings: viewModel.$supplementCardSettings) {
                            OnboardingCardView(placeholderCardType: (currentStep == .welcome || !viewModel.isInitialAnimPlayed) ? .light : .dark,
                                               cardImage: viewModel.mainCardImage,
                                               cardScanned: viewModel.backupCardsAddedCount >= 1)
                        }
                        
                        AnimatedView(settings: viewModel.$mainCardSettings) {
                            OnboardingCardView(placeholderCardType: .dark,
                                               cardImage: viewModel.mainCardImage,
                                               cardScanned: viewModel.isInitialAnimPlayed && currentStep != .welcome)
                        }
                        
                        OnboardingCircleButton(refreshAction: {},
                                               state: currentStep.successCircleState,
                                               size: .huge)
                            .offset(y: 8)
                            .opacity(currentStep.successCircleOpacity)
                    }
                    .position(x: size.width / 2, y: size.height / 2)
//                    .overlay(Color.red.opacity(0.3))
                }
                .readSize { size in
                    viewModel.setupContainer(with: size)
                }
                OnboardingTextButtonView(
                    title: viewModel.title,
                    subtitle: viewModel.subtitle,
                    textOffset: .zero,
                    buttonsSettings: .init(main: viewModel.mainButtonSettings,
                                           supplement: viewModel.supplementButtonSettings)

                ) {
                    viewModel.reset()
                }
                .padding(.horizontal, 40)
            }
            
        }
        .alert(item: $viewModel.alert, content: { alertBinder in
            alertBinder.alert
        })
        .sheet(isPresented: $navigation.onboardingWalletToAccessCode, content: {
            OnboardingAccessCodeView { accessCode in
                viewModel.saveAccessCode(accessCode)
            }
        })
        .preference(key: ModalSheetPreferenceKey.self, value: viewModel.isModal)
        .navigationBarHidden(true)
        .onAppear(perform: {
            if viewModel.isInitialAnimPlayed {
                return
            }
            
            viewModel.playInitialAnim()
        })
    }
}

struct WalletOnboardingView_Previews: PreviewProvider {
    
    static let assembly: Assembly = {
        let assembly = Assembly.previewAssembly
        
        return assembly
    }()
    
    static var previews: some View {
        NavigationView {
            WalletOnboardingView(viewModel: assembly.getWalletOnboardingViewModel())
                .environmentObject(assembly.services.navigationCoordinator)
                .navigationBarHidden(true)
        }
    }
}
