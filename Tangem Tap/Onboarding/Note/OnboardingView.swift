//
//  OnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum NoteOnboardingStep: Int, CaseIterable {
    case read, createWallet, topup, backup, confetti, goToMain
    
    var hasProgressStep: Bool {
        switch self {
        case .read, .createWallet, .topup, .backup: return true
        case .confetti, .goToMain: return false
        }
    }
    
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
        case .topup: return "onboarding_button_buy_crypto"
        case .backup: return ""
        case .confetti: return "common_continue"
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
        case .topup: return "onboarding_button_show_address_qr"
        case .confetti, .backup, .goToMain: return ""
        }
    }
    
    var bigCircleBackgroundScale: CGFloat {
        switch self {
        case .read: return 1.0
        default: return 0.0
        }
    }
    
    func cardBackgroundOffset(containerSize: CGSize) -> CGSize {
        switch self {
        case .createWallet:
            return .init(width: 0, height: -7)
        case .topup, .confetti, .backup:
            let height = 0.021 * containerSize.height
            return .init(width: 0, height: -height)
        default:
            return .zero
        }
    }
    
    var balanceStackOpacity: Double {
        switch self {
        case .read, .createWallet, .goToMain, .backup: return 0
        case .topup, .confetti: return 1
        }
    }
    
    func cardBackgroundFrame(containerSize: CGSize) -> CGSize {
        switch self {
        case .read, .goToMain: return .zero
        case .createWallet:
            let diameter = CardLayout.main.frame(for: self, containerSize: containerSize).height * 1.316
            return .init(width: diameter, height: diameter)
        case .topup, .confetti, .backup:
            let height = 0.61 * containerSize.height
            return .init(width: containerSize.width * 0.787, height: height)
        }
    }
    
    func cardBackgroundCornerRadius(containerSize: CGSize) -> CGFloat {
        switch self {
        case .read, .goToMain: return 0
        case .createWallet: return cardBackgroundFrame(containerSize: containerSize).height / 2
        case .topup, .confetti, .backup: return 8
        }
    }
}

enum CardLayout {
    case main, supplementary
    
    private var cardHeightWidthRatio: CGFloat { 0.609 }
    
    func frame(for step: NoteOnboardingStep, containerSize: CGSize) -> CGSize {
        let height = containerSize.height * frameSizeRatio(for: step)
        let width = height / cardHeightWidthRatio
        let maxWidth = containerSize.width - cardFrameMinHorizontalPadding(for: step)
        return width > maxWidth ?
            .init(width: maxWidth, height: maxWidth * cardHeightWidthRatio) :
            .init(width: height / cardHeightWidthRatio, height: height)
    }
    
    func rotationAngle(at step: NoteOnboardingStep) -> Angle {
        switch (self, step) {
        case (.main, .read): return Angle(degrees: -2)
        case (.supplementary, .read): return Angle(degrees: -21)
        default: return .zero
        }
    }
    
    func offset(at step: NoteOnboardingStep, containerSize: CGSize) -> CGSize {
        let containerHeight = max(containerSize.height, containerSize.width)
        switch (self, step) {
        case (.main, .read):
            let heightOffset = containerHeight * 0.183
            return .init(width: -1, height: -heightOffset)
        case (.main, .createWallet):
            let offset = containerHeight * 0.02
            return .init(width: 0, height: -offset)
        case (.main, _):
            let backgroundSize = step.cardBackgroundFrame(containerSize: containerSize)
            let backgroundOffset = step.cardBackgroundOffset(containerSize: containerSize)
            return .init(width: 0, height: backgroundOffset.height - backgroundSize.height / 2 + 8)
        case (.supplementary, .read):
            let offset = containerHeight * 0.137
            return .init(width: 8, height: offset)
        case (.supplementary, _): return .zero
        }
    }
    
    func opacity(at step: NoteOnboardingStep) -> Double {
        guard self == .supplementary else {
            return 1
        }
        
        if step == .read {
            return 1
        }
        
        return 0
    }
    
    private func frameSizeRatio(for step: NoteOnboardingStep) -> CGFloat {
        switch (self, step) {
        case (.main, .read): return 0.375
        case (.main, .createWallet): return 0.536
        case (.main, _): return 0.246
        case (.supplementary, .read): return 0.32
        case (.supplementary, _): return 0.18
        }
    }
    
    private func cardFrameMinHorizontalPadding(for step: NoteOnboardingStep) -> CGFloat {
        switch (self, step) {
        case (.main, .read): return 98
        case (.main, .createWallet): return 68
        case (.main, _): return 234
        case (.supplementary, _): return 106
        }
    }
}

struct OnboardingView: View {
    
    @EnvironmentObject var navigation: NavigationCoordinator
    @ObservedObject var viewModel: NoteOnboardingViewModel
    
    private let horizontalPadding: CGFloat = 40
    private let screenSize: CGSize = UIScreen.main.bounds.size
    
    @State private var animationContainerSize: CGSize = .zero
    
    var currentStep: NoteOnboardingStep { viewModel.currentStep }
    
    var isSmallScreenSize: Bool { animationContainerSize.height < 250 }
    
    var navigationLinks: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: WebViewContainer(url: viewModel.shopURL, title: "home_button_shop"),
                           isActive: $navigation.readToShop)
            
//            if !navigation.mainToCardOnboarding {
//                NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
//                               isActive: $navigation.readToMain)
//                    .environmentObject(navigation)
//            }
            
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
    
    @ViewBuilder
    private var messages: some View {
        CardOnboardingMessagesView(
            title: currentStep.title,
            subtitle: currentStep.subtitle) {
            viewModel.reset()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, isSmallScreenSize ? 15 : 60)
    }
    
    @ViewBuilder
    private var buttons: some View {
        TangemButton(isLoading: viewModel.executingRequestOnCard,
                     title: currentStep.primaryButtonTitle,
                     image: "",
                     size: .customWidth(animationContainerSize.width - 80)) {
            viewModel.executeStep()
        }
        .buttonStyle(TangemButtonStyle(color: .green,
                                       font: .system(size: 18, weight: .semibold),
                                       isDisabled: false))
        .padding(.bottom, 10)
        TangemButton(isLoading: false,
                     title: currentStep.secondaryButtonTitle,
                     image: "",
                     size: .customWidth(animationContainerSize.width - horizontalPadding * 2)) {
//            viewModel.reset()
            switch currentStep {
            case .read:
                navigation.readToShop = true
            case .topup:
                viewModel.isAddressQrBottomSheetPresented = true
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
    
    var body: some View {
        ZStack {
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)
                .frame(maxWidth: screenSize.width)
                .zIndex(100)
            VStack(spacing: 0) {
                navigationLinks
                
                if viewModel.steps.count > 1 && currentStep != .read {
                    OnboardingProgressCheckmarksView(numberOfSteps: viewModel.numberOfProgressBarSteps, currentStep: viewModel.$currentStepIndex)
                        .frame(maxWidth: .infinity, idealHeight: 42)
                        .padding(.top, isSmallScreenSize ? 0 : 26)
                        .padding(.horizontal, horizontalPadding)
                }
                
                GeometryReader { proxy in
                    ZStack(alignment: .center) {
                        let backgroundFrame = currentStep.cardBackgroundFrame(containerSize: proxy.size)
                        let backgroundOffset = currentStep.cardBackgroundOffset(containerSize: proxy.size)
                        Rectangle()
                            .frame(size: backgroundFrame)
                            .cornerRadius(currentStep.cardBackgroundCornerRadius(containerSize: proxy.size))
                            .foregroundColor(Color.tangemTapBgGray)
                            .opacity(0.8)
                            .offset(backgroundOffset)
                        
                        Image("light_card")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(size: CardLayout.supplementary.frame(for: currentStep, containerSize: proxy.size))
                            .rotationEffect(CardLayout.supplementary.rotationAngle(at: currentStep))
                            .offset(CardLayout.supplementary.offset(at: currentStep, containerSize: proxy.size))
                            .opacity(CardLayout.supplementary.opacity(at: currentStep))
                        OnboardingCardView(baseCardName: "dark_card",
                                           backCardImage: viewModel.cardImage,
                                           cardScanned: currentStep != .read)
                            .rotationEffect(CardLayout.main.rotationAngle(at: currentStep))
                            .offset(CardLayout.main.offset(at: currentStep, containerSize: proxy.size))
                            .frame(size: CardLayout.main.frame(for: currentStep, containerSize: proxy.size))
                        OnboardingTopupBalanceUpdater(
                            balance: viewModel.cardBalance,
                            frame: backgroundFrame,
                            offset: backgroundOffset,
                            refreshAction: {
                                viewModel.updateCardBalance()
                            },
                            refreshButtonState: viewModel.refreshButtonState,
                            refreshButtonSize: isSmallScreenSize ? .small : .default,
                            opacity: currentStep.balanceStackOpacity
                        )
//                        Group {
//                            VStack {
//                                Text("onboarding_balance")
//                                    .font(.system(size: 14, weight: .semibold))
//                                    .padding(.bottom, 8)
//                                Text(viewModel.cardBalance)
////                                    .background(Color.orange)
//                                    .multilineTextAlignment(.center)
//                                    .truncationMode(.middle)
//                                    .lineLimit(2)
//                                    .minimumScaleFactor(0.3)
//                                    .font(.system(size: 28, weight: .bold))
//                                    .frame(maxWidth: backgroundFrame.width - 26, maxHeight: backgroundFrame.height * 0.155)
//                            }
////                            .background(Color.green)
//                            .offset(backgroundOffset)
//
//                            OnboardingCircleButton(refreshAction: { viewModel.updateCardBalance() },
//                                                   state: viewModel.refreshButtonState,
//                                                   size: isSmallScreenSize ? .small : .default)
//                                .offset(x: 0, y: backgroundOffset.height + backgroundFrame.height / 2)
//                        }
                        
                        //                        }
//                        .background(Color.red)
//                        .offset(currentStep.cardBackgroundOffset(containerSize: proxy.size))
//                        .opacity(currentStep.balanceStackOpacity)
                        
                    }
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
//                    .background(Color.yellow)
                }
//                .frame(minHeight: 210)
                .readSize { value in
                    animationContainerSize = value
                }
                messages
                buttons
                    .sheet(isPresented: $navigation.onboardingToDisclaimer, content: {
                        DisclaimerView(style: .sheet)
                    })
                Spacer()
                    .frame(width: 1, height: 20)
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
//        .background(Color.pink)
//        .background(Color.gray.edgesIgnoringSafeArea(.all))
        
        
        .navigationBarHidden(true)
    }
}

struct OnboardingTopupBalanceUpdater: View {
    
    let balance: String
    let frame: CGSize
    let offset:  CGSize
    let refreshAction: () -> Void
    let refreshButtonState: OnboardingCircleButton.State
    let refreshButtonSize: OnboardingCircleButton.Size
    let opacity: Double
    
    var body: some View {
        Group {
            VStack {
                Text("onboarding_balance")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.bottom, 8)
                Text(balance)
//                                    .background(Color.orange)
                    .multilineTextAlignment(.center)
                    .truncationMode(.middle)
                    .lineLimit(2)
                    .minimumScaleFactor(0.3)
                    .font(.system(size: 28, weight: .bold))
                    .frame(maxWidth: frame.width - 26, maxHeight: frame.height * 0.155)
            }
//                            .background(Color.green)
            .offset(offset)
            
            OnboardingCircleButton(refreshAction: refreshAction,
                                   state: refreshButtonState,
                                   size: refreshButtonSize)
//                                   size: isSmallScreenSize ? .small : .default)
                .offset(x: 0, y: offset.height + frame.height / 2)
        }
        
        //                        }
//                        .background(Color.red)
//                        .offset(currentStep.cardBackgroundOffset(containerSize: proxy.size))
        .opacity(opacity)
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
            OnboardingView(viewModel: assembly.getOnboardingViewModel())
                .environmentObject(assembly)
                .environmentObject(assembly.services.navigationCoordinator)
        }
        .previewGroup(devices: [.iPhoneX], withZoomed: false)
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
