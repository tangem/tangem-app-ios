//
//  SingleCardOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct SingleCardOnboardingView: View {
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
                                              viewModel.popToStories()
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
                    viewModel.popToStories()
                }
                .padding(.horizontal, 40)
            }
        }
        .alert(item: $viewModel.alert, content: { $0.alert })
        .onAppear(perform: {
            viewModel.playInitialAnim()
        })
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        SingleCardOnboardingView(viewModel: .init(input: PreviewData.previewNoteCardOnboardingInput,
                                                  coordinator: OnboardingCoordinator()))
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
