//
//  SingleCardOnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct SingleCardOnboardingView: View {
    
    @EnvironmentObject var navigation: NavigationCoordinator
    @ObservedObject var viewModel: SingleCardOnboardingViewModel

    private let horizontalPadding: CGFloat = 40
    private let screenSize: CGSize = UIScreen.main.bounds.size
    
    var currentStep: SingleCardOnboardingStep { viewModel.currentStep }
    
    private var isTopItemsVisible: Bool {
        viewModel.isInitialAnimPlayed
    }
    
    var navigationLinks: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: WebViewContainer(url: viewModel.shopURL, title: "home_button_shop"),
                           isActive: $navigation.readToShop)
            
            NavigationLink(destination: WebViewContainer(url: viewModel.buyCryptoURL,
                                                         title: "wallet_button_topup",
                                                         addLoadingIndicator: true,
                                                         urlActions: [ viewModel.buyCryptoCloseUrl : { _ in
                                                            navigation.onboardingToBuyCrypto = false
                                                         }
                                                         ]),
                           isActive: $navigation.onboardingToBuyCrypto)
            
            NavigationLink(destination: EmptyView(), isActive: .constant(false))
        }
    }
    
    var body: some View {
        ZStack {
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)
                .frame(maxWidth: screenSize.width)
                .zIndex(100)
            VStack(spacing: 0) {
                navigationLinks
                
                GeometryReader { proxy in
                    ZStack(alignment: .center) {
                        let size = proxy.size
                        
                        NavigationBar(title: "onboarding_navbar_activating_card",
                                      settings: .init(titleFont: .system(size: 17, weight: .semibold), backgroundColor: .clear))
                            .frame(size: viewModel.navbarSize)
                            .offset(x: 0, y: -size.height / 2 + (isTopItemsVisible ? viewModel.navbarSize.height / 2 : 0))
                            .opacity(isTopItemsVisible ? 1.0 : 0.0)
                        
                        ProgressBar(height: 5, currentProgress: viewModel.currentProgress)
                            .offset(x: 0, y: -size.height / 2 + (isTopItemsVisible ? viewModel.navbarSize.height + 10 : 0))
                            .opacity(isTopItemsVisible ? 1.0 : 0.0)
                            .padding(.horizontal, horizontalPadding)
                        
                        let backgroundFrame = viewModel.isInitialAnimPlayed ? currentStep.cardBackgroundFrame(containerSize: size) : .zero
                        let backgroundOffset = viewModel.isInitialAnimPlayed ? currentStep.cardBackgroundOffset(containerSize: size) : .zero
                        
                        AnimatedView(settings: viewModel.$lightCardAnimSettings) {
                            Image("light_card")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        AnimatedView(settings: viewModel.$cardAnimSettings) {
                            OnboardingCardView(baseCardName: "dark_card",
                                               backCardImage: viewModel.cardImage,
                                               cardScanned: viewModel.isInitialAnimPlayed && viewModel.cardImage != nil)
                        }
                        
                        OnboardingTopupBalanceView(
                            backgroundFrameSize: backgroundFrame,
                            cornerSize: currentStep.cardBackgroundCornerRadius(containerSize: size),
                            backgroundOffset: backgroundOffset,
                            balance: viewModel.cardBalance,
                            balanceUpdaterFrame: backgroundFrame,
                            balanceUpdaterOffset: backgroundOffset,
                            refreshAction: {
                                viewModel.updateCardBalance()
                            },
                            refreshButtonState: viewModel.refreshButtonState,
                            refreshButtonSize: .medium,
                            refreshButtonOpacity: currentStep.balanceStackOpacity
                        )
                    }
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
                .readSize { value in
                    viewModel.setupContainer(with: value)
                }
                OnboardingTextButtonView(
                    title: viewModel.title,
                    subtitle: viewModel.subtitle,
                    buttonsSettings: .init(
                        mainTitle: viewModel.mainButtonTitle,
                        mainSize: .wide,
                        mainAction: {
                            viewModel.executeStep()
                        },
                        mainIsBusy: viewModel.executingRequestOnCard,
                        supplementTitle: viewModel.supplementButtonTitle,
                        supplementSize: .wide,
                        supplementAction: {
                            switch currentStep {
                            case .topup:
                                viewModel.isAddressQrBottomSheetPresented = true
                            default:
                                viewModel.reset()
                            }
                        },
                        isVisible: currentStep.withSecondaryButton,
                        containSupplementButton: true)
                ) {
                    viewModel.reset()
                }
                .padding(.horizontal, 40)
            }
            .frame(maxWidth: screenSize.width, maxHeight: screenSize.height)
            BottomSheetView(isPresented: viewModel.$isAddressQrBottomSheetPresented,
                                     hideBottomSheetCallback: {
                                        viewModel.isAddressQrBottomSheetPresented = false
                                     }, content: {
                                        AddressQrBottomSheetContent(shareAddress: viewModel.shareAddress,
                                                                    address: viewModel.walletAddress)
                                     })
                .frame(maxWidth: screenSize.width)
        }
        .frame(maxWidth: screenSize.width, maxHeight: screenSize.height)
        .navigationBarHidden(true)
        .onAppear(perform: {
            viewModel.playInitialAnim()
        })
    }
}

struct OnboardingView_Previews: PreviewProvider {
    
    static var assembly: Assembly = {
        let assembly = Assembly.previewAssembly
        let previewModel = assembly.previewCardViewModel
//        assembly.makeOnboardingViewModel(with: assembly.previewNoteCardOnboardingInput)
        return assembly
    }()
    
    static var previews: some View {
        ContentView() {
            SingleCardOnboardingView(viewModel: assembly.getOnboardingViewModel())
                .environmentObject(assembly)
                .environmentObject(assembly.services.navigationCoordinator)
        }
//        .previewGroup(devices: [.iPhoneX], withZoomed: false)
//        .previewGroup()
    }
}

struct CardOnboardingBackgroundCircle: View {
    
    let scale: CGFloat
    
    var body: some View {
        Circle()
            .foregroundColor(.white)
            .frame(size: .init(width: 664, height: 664))
            .padding(10)
            .overlay(
                Circle()
                    .foregroundColor(.tangemTapBgGray)
                    .padding(38)
            )
            .background(
                Circle()
                    .foregroundColor(.tangemTapBgGray)
            )
            .edgesIgnoringSafeArea(.all)
            .scaleEffect(scale)
            .offset(x: 299, y: -228)
    }
    
}
