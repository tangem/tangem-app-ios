//
//  OnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case read, createWallet, topup, backup, confetti, goToMain
    
    var icon: Image? {
        switch self {
        case .read: return Image("onboarding.nfc")
        case .createWallet: return Image("onboarding.create.wallet")
        case .topup: return Image("onboarding.topup")
        case .backup, .confetti, .goToMain: return nil
        }
    }
    
    var iconFont: Font {
        switch self {
        case .read: return .system(size: 20, weight: .bold)
        default: return .system(size: 20, weight: .regular)
        }
    }
    
    var title: LocalizedStringKey {
        switch self {
        case .read: return "onboarding_read_title"
        case .goToMain: return ""
        case .createWallet: return "onboarding_create_title"
        case .topup: return "onboarding_topup_title"
        case .backup: return "Backup wallet"
        case .confetti: return "onboarding_confetti_title"
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .read: return "onboarding_read_subtitle"
        case .goToMain: return ""
        case .createWallet: return "onboarding_create_subtitle"
        case .topup: return "onboarding_topup_subtitle"
        case .backup: return ""
        case .confetti: return "onboarding_confetti_subtitle"
        }
    }
    
    var primaryButtonTitle: LocalizedStringKey {
        switch self {
        case .read: return "home_button_scan"
        case .createWallet: return "onboarding_button_create_wallet"
        case .topup: return "onboarding_button_topup"
        case .backup: return ""
        case .confetti: return "onboarding_button_confetti"
        case .goToMain: return ""
        }
    }
    
    var withSecondaryButton: Bool {
        switch self {
        case .read, .createWallet, .topup: return true
        case .confetti, .backup, .goToMain: return false
        }
    }
    
    var secondaryButtonTitle: LocalizedStringKey {
        switch self {
        case .read: return "onboarding_button_shop"
        case .createWallet: return "onboarding_button_how_it_works"
        case .topup: return "onboarding_button_topup_qr"
        case .confetti, .backup, .goToMain: return ""
        }
    }
    
    var cardBackgroundFrame: CGSize {
        switch self {
        case .read, .goToMain: return .zero
        case .createWallet: return .init(width: 246, height: 246)
        case .topup, .confetti, .backup: return .init(width: 295, height: 213)
        }
    }
    
    var cardBackgroundOffset: CGSize {
        switch self {
        case .createWallet:
            return .init(width: 0, height: -7)
        case .topup, .confetti, .backup:
            return .init(width: 0, height: 15)
        default:
            return .zero
        }
    }
    
    var cardBackgroundCornerRadius: CGFloat {
        switch self {
        case .read, .goToMain: return 0
        case .createWallet: return cardBackgroundFrame.height / 2
        case .topup, .confetti, .backup: return 8
        }
    }
    
    var balanceStackOpacity: Double {
        switch self {
        case .read, .createWallet, .goToMain, .backup: return 0
        case .topup, .confetti: return 1
        }
    }
}


struct OnboardingView: View {
    
    @EnvironmentObject var navigation: NavigationCoordinator
    @ObservedObject var viewModel: OnboardingViewModel
    
    var navigationLinks: some View {
        VStack {
            NavigationLink(destination: WebViewContainer(url: viewModel.shopURL, title: "home_button_shop"),
                           isActive: $navigation.readToShop)
            
            NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
                           isActive: $navigation.readToMain)
                .environmentObject(navigation)
            
            NavigationLink(destination: WebViewContainer(url: viewModel.buyCryptoURL,
                                                         title: "wallet_button_topup",
                                                         addLoadingIndicator: true,
                                                         urlActions: [ viewModel.buyCryptoCloseUrl : { _ in
                                                            navigation.onboardingToBuyCrypto = false
                                                         }
                                                         ]),
                           isActive: $navigation.onboardingToBuyCrypto)
            
        }
    }
    
    @ViewBuilder
    private var messages: some View {
        Text(currentStep.title)
            .font(.system(size: 28, weight: .bold))
            .multilineTextAlignment(.center)
            .foregroundColor(.tangemTapGrayDark6)
            .padding(.bottom, 14)
            .onTapGesture {
                // [REDACTED_TODO_COMMENT]
                viewModel.reset()
            }
        Text(currentStep.subtitle)
            .multilineTextAlignment(.center)
            .font(.system(size: 18, weight: .regular))
            .foregroundColor(.tangemTapGrayDark6)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40)
        Spacer()
            .frame(size: .init(width: 0.01, height: 60))
    }
    
    @ViewBuilder
    private var buttons: some View {
        TangemButton(isLoading: viewModel.executingRequestOnCard,
                     title: currentStep.primaryButtonTitle,
                     image: "",
                     size: .wide) {
            viewModel.executeStep()
        }
        .buttonStyle(TangemButtonStyle(color: .green,
                                       font: .system(size: 18, weight: .semibold),
                                       isDisabled: false))
        .padding(.bottom, 10)
        TangemButton(isLoading: false,
                     title: currentStep.secondaryButtonTitle,
                     image: "",
                     size: .wide) {
//            viewModel.reset()
            switch currentStep {
            case .topup:
                bottomSheetPresented = true
            default:
                viewModel.reset()
            }
//            viewModel.shouldFireConfetti = true
        }
        .opacity(currentStep.withSecondaryButton ? 1.0 : 0.1)
        .buttonStyle(TangemButtonStyle(color: .transparentWhite,
                                       font: .system(size: 18, weight: .semibold),
                                       isDisabled: false))
    }
    
    enum CardLayout {
        case main, supplementary
        
        func frame(for step: OnboardingStep) -> CGSize {
            switch self {
            case .main:
                switch step {
                case .read:
                    return .init(width: 272, height: 164.5)
                case .createWallet:
                    return .init(width: 307, height: 187)
                case .topup, .confetti, .backup, .goToMain:
                    return .init(width: 141, height: 86)
                }
            case .supplementary:
                switch step {
                case .read: return .init(width: 232, height: 140)
                case .createWallet: return .init(width: 170, height: 103)
                default: return .zero
                }
            }
        }
        
        func rotationAngle(at step: OnboardingStep) -> Angle {
            switch (self, step) {
            case (.main, .read): return Angle(degrees: -2)
            case (.supplementary, .read): return Angle(degrees: -21)
            default: return .zero
            }
        }
        
        func offset(at step: OnboardingStep) -> CGSize {
            switch (self, step) {
            case (.main, .read): return .init(width: -1, height: -80)
            case (.main, .createWallet): return .init(width: 0, height: -7)
            case (.main, _): return .init(width: 0, height: -77)
            case (.supplementary, .read): return .init(width: 8, height: 60)
            case (.supplementary, _): return .zero
            }
        }
        
        func opacity(at step: OnboardingStep) -> Double {
            guard self == .supplementary else {
                return 1
            }
            
            if step == .read {
                return 1
            }
            
            return 0
        }
    }
    
    var currentStep: OnboardingStep { viewModel.currentStep }
    
    @State var bottomSheetPresented: Bool = false
    
    var body: some View {
        ZStack {
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)
                .zIndex(100)
            VStack {
                navigationLinks
                
                if viewModel.steps.count > 1 && currentStep != .read {
                    ProgressOnboardingView(steps: viewModel.steps, currentStep: viewModel.currentStepIndex)
                        .frame(minHeight: 62)
                        .padding(.top, 26)
                }
                
                GeometryReader { proxy in
                    ZStack(alignment: .center) {
//                        Rectangle()
//                            .frame(size: CGSize(width: proxy.size.width, height: 1))
//                            .foregroundColor(Color.green)
                        Image("light_card")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(size: CardLayout.supplementary.frame(for: currentStep))
                            .rotationEffect(CardLayout.supplementary.rotationAngle(at: currentStep))
                            .offset(CardLayout.supplementary.offset(at: currentStep))
                            .opacity(CardLayout.supplementary.opacity(at: currentStep))
                        Rectangle()
                            .frame(size: currentStep.cardBackgroundFrame)
                            .cornerRadius(currentStep.cardBackgroundCornerRadius)
                            .foregroundColor(Color.tangemTapBgGray)
                            .opacity(0.8)
                            .offset(currentStep.cardBackgroundOffset)
                        OnboardingCardView(baseCardName: "dark_card",
                                           backCardImage: viewModel.cardImage,
                                           cardScanned: currentStep != .read)
                            .frame(size: CardLayout.main.frame(for: currentStep))
                            .rotationEffect(CardLayout.main.rotationAngle(at: currentStep))
                            .offset(CardLayout.main.offset(at: currentStep))
                            
                        VStack {
                            Spacer()
                            Text("onboarding_balance")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.bottom, 8)
                            Text(viewModel.cardBalance)
                                .font(.system(size: 28, weight: .bold))
                                .padding(.bottom, 28)
                            
                            
                            OnboardingCircleButton(refreshAction: { viewModel.updateCardBalance() },
                                                   state: viewModel.refreshButtonState)
                                .padding(.bottom, 19)
                        }
                        .offset(currentStep.cardBackgroundOffset)
                        .opacity(currentStep.balanceStackOpacity)
                        
                    }
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
                messages
                buttons
                    .sheet(isPresented: $navigation.onboardingToDisclaimer, content: {
                        VStack {
                            ScrollView {
                                Text("disclaimer_title")
                                    .font(.system(size: 20, weight: .semibold, design: .default))
                                    .foregroundColor(.tangemTapGrayDark6)
                                    .padding()
                                Text("disclaimer_text")
                                    .font(Font.system(size: 16, weight: .regular, design: .default))
                                    .foregroundColor(.tangemTapGrayDark2)
                                    .padding()
                            }
                            TangemButton(isLoading: false,
                                         title: "common_accept",
                                         size: .wide) {
                                viewModel.acceptDisclaimer()
                            }
                            .buttonStyle(TangemButtonStyle(color: .green,
                                                           font: .system(size: 18)))
                            .padding(.bottom, 8)
                        }
                    })
                Spacer()
                    .frame(width: 1, height: 20)
            }
            AddressQrBottomSheetView(isPresented: $bottomSheetPresented,
                                     shareAddress: viewModel.shareAddress,
                                     address: viewModel.walletAddress)
        }
        .navigationBarHidden(true)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        ContentView() {
            OnboardingView(viewModel: assembly.makeOnboardingViewModel())
                .environmentObject(assembly)
                .environmentObject(assembly.services.navigationCoordinator)
        }
    }
}
