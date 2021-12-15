//
//  SingleCardOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct SingleCardOnboardingView: View {
    
    @EnvironmentObject var navigation: NavigationCoordinator
    @ObservedObject var viewModel: SingleCardOnboardingViewModel
    
    private let horizontalPadding: CGFloat = 16
    private let screenSize: CGSize = UIScreen.main.bounds.size
    
    var currentStep: SingleCardOnboardingStep { viewModel.currentStep }
    
    private var isTopItemsVisible: Bool {
        viewModel.isNavBarVisible
    }

    var body: some View {
        ZStack {
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)
                .frame(maxWidth: screenSize.width)
                .zIndex(100)
            VStack(spacing: 0) {
                GeometryReader { proxy in
                    let size = proxy.size
                    ZStack(alignment: .center) {
                        
                        NavigationBar(title: "onboarding_navbar_activating_card",
                                      settings: .init(titleFont: .system(size: 17, weight: .semibold), backgroundColor: .clear),
                                      leftButtons: {
                            BackButton(height: viewModel.navbarSize.height,
                                       isVisible: viewModel.isBackButtonVisible,
                                       isEnabled: viewModel.isBackButtonEnabled,
                                       hPadding: horizontalPadding) {
                                viewModel.reset()
                            }
                        })
                            .frame(size: viewModel.navbarSize)
                            .offset(x: 0, y: -size.height / 2 + (isTopItemsVisible ? viewModel.navbarSize.height / 2 : 0))
                            .opacity(isTopItemsVisible ? 1.0 : 0.0)
                        
                        ProgressBar(height: 5, currentProgress: viewModel.currentProgress)
                            .offset(x: 0, y: -size.height / 2 + (isTopItemsVisible ? viewModel.navbarSize.height + 10 : 0))
                            .opacity(isTopItemsVisible ? 1.0 : 0.0)
                            .padding(.horizontal, horizontalPadding)
                        
                        let backgroundFrame = viewModel.isInitialAnimPlayed ? currentStep.cardBackgroundFrame(containerSize: size) : .zero
                        let backgroundOffset = viewModel.isInitialAnimPlayed ? currentStep.cardBackgroundOffset(containerSize: size) : .zero
                        
                        AnimatedView(settings: viewModel.$supplementCardSettings) {
                            OnboardingCardView(placeholderCardType: .light,
                                               cardImage: nil,
                                               cardScanned: false)
                        }
                        AnimatedView(settings: viewModel.$mainCardSettings) {
                            OnboardingCardView(placeholderCardType: .dark,
                                               cardImage: viewModel.cardImage,
                                               cardScanned: viewModel.isInitialAnimPlayed && viewModel.isCardScanned)
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
                        
                        OnboardingCircleButton(refreshAction: {},
                                               state: currentStep.successCircleState,
                                               size: .huge)
                            .offset(y: 8)
                            .opacity(currentStep.successCircleOpacity)
                    }
                    .position(x: size.width / 2, y: size.height / 2)
                }
                .readSize { value in
                    viewModel.setupContainer(with: value)
                }
                
                OnboardingTextButtonView(
                    title: viewModel.title,
                    subtitle: viewModel.subtitle,
                    textOffset: currentStep.messagesOffset,
                    buttonsSettings: .init(main: viewModel.mainButtonSettings,
                                           supplement: viewModel.supplementButtonSettings)
                ) {
                    viewModel.reset()
                }
                .padding(.horizontal, 40)
            }
            BottomSheetView(isPresented: viewModel.$isAddressQrBottomSheetPresented,
                            hideBottomSheetCallback: {
                viewModel.isAddressQrBottomSheetPresented = false
            }, content: {
                AddressQrBottomSheetContent(shareAddress: viewModel.shareAddress,
                                            address: viewModel.walletAddress,
                                            qrNotice: viewModel.qrNoticeMessage)
            })
                .frame(maxWidth: screenSize.width)
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.onboardingToBuyCrypto) {
                    WebViewContainer(url: viewModel.buyCryptoURL,
                                     title: "wallet_button_topup",
                                     addLoadingIndicator: true,
                                     withCloseButton: true,
                                     urlActions: [ viewModel.buyCryptoCloseUrl : { _ in
                        DispatchQueue.main.async {
                            self.navigation.onboardingToBuyCrypto = false
                            self.viewModel.updateCardBalance()
                        }
                    }])
                }
        }
        .alert(item: $viewModel.alert, content: { $0.alert })
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
                    .foregroundColor(.tangemBgGray)
                    .padding(38)
            )
            .background(
                Circle()
                    .foregroundColor(.tangemBgGray)
            )
            .edgesIgnoringSafeArea(.all)
            .scaleEffect(scale)
            .offset(x: 299, y: -228)
    }
    
}
