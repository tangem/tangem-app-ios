//
//  SingleCardOnboardingView.swift
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
            return .init(width: 0, height: containerSize.height * 0.103)
        case .topup, .confetti, .backup:
            return defaultBackgroundOffset(in: containerSize)
//            let height = 0.112 * containerSize.height
//            return .init(width: 0, height: height)
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
            let diameter = CardLayout.main.frame(for: self, containerSize: containerSize).height * 1.317
            return .init(width: diameter, height: diameter)
        case .topup, .confetti, .backup:
            return defaultBackgroundFrameSize(in: containerSize)
//            let height = 0.61 * containerSize.height
//            return .init(width: containerSize.width * 0.787, height: height)
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

extension NoteOnboardingStep: OnboardingTopupBalanceLayoutCalculator { }

enum CardLayout: OnboardingCardFrameCalculator {
    case main, supplementary
    
    var cardHeightWidthRatio: CGFloat { 0.609 }
    
    func cardAnimSettings(for step: NoteOnboardingStep, containerSize: CGSize, animated: Bool) -> CardAnimSettings {
        .init(frame: frame(for: step, containerSize: containerSize),
              offset: offset(at: step, containerSize: containerSize),
              scale: 1.0,
              opacity: opacity(at: step),
              zIndex: self == .main ? 100 : 10,
              rotationAngle: rotationAngle(at: step),
              animType: animated ? .default : .noAnim)
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
            return step.cardBackgroundOffset(containerSize: containerSize)
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
    
    func frameSizeRatio(for step: NoteOnboardingStep) -> CGFloat {
        switch (self, step) {
        case (.main, .read): return 0.375
        case (.main, .createWallet): return 0.536
        case (.main, _): return 0.246
        case (.supplementary, .read): return 0.32
        case (.supplementary, _): return 0.18
        }
    }
    
    func cardFrameMinHorizontalPadding(at step: NoteOnboardingStep) -> CGFloat {
        switch (self, step) {
        case (.main, .read): return 98
        case (.main, .createWallet): return 80
        case (.main, _): return 234
        case (.supplementary, _): return 106
        }
    }
}

struct SingleCardOnboardingView: View {
    
    @EnvironmentObject var navigation: NavigationCoordinator
    @ObservedObject var viewModel: SingleCardOnboardingViewModel
    
    private let horizontalPadding: CGFloat = 40
    private let screenSize: CGSize = UIScreen.main.bounds.size
    
    @State private var animationContainerSize: CGSize = .zero
    
    var currentStep: NoteOnboardingStep { viewModel.currentStep }
    
    var isSmallScreenSize: Bool { animationContainerSize.height < 300 }
    
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
    
    private var isTopItemsVisible: Bool {
        currentStep != .read && viewModel.isInitialAnimPlayed
    }
    
    var body: some View {
        ZStack {
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)
                .frame(maxWidth: screenSize.width)
                .zIndex(100)
            VStack(spacing: 0) {
                navigationLinks
                
                if viewModel.steps.count > 2 && currentStep != .read {
                    
                }
                
                GeometryReader { proxy in
                    ZStack(alignment: .center) {
                        let size = proxy.size
                        
                        NavigationBar(title: "onboarding_navbar_activating_card",
                                      settings: .init(titleFont: .system(size: 17, weight: .semibold), backgroundColor: .clear))
                            .frame(size: viewModel.navbarSize)
                            .offset(x: 0, y: -size.height / 2 + (isTopItemsVisible ? viewModel.navbarSize.height / 2 : 0))
                            .opacity(isTopItemsVisible ? 1.0 : 0.0)
                        
                        OnboardingProgressCheckmarksView(numberOfSteps: viewModel.numberOfProgressBarSteps, currentStep: viewModel.$currentStepIndex)
                            .frame(maxWidth: .infinity, maxHeight: 5)
                            .offset(x: 0, y: -size.height / 2 + (isTopItemsVisible ? viewModel.navbarSize.height + 5 : 0))
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

//                        OnboardingTopupBalanceUpdater(
//                            balance: viewModel.cardBalance,
//                            frame: backgroundFrame,
//                            offset: backgroundOffset,
//                            refreshAction: {
//                                viewModel.updateCardBalance()
//                            },
//                            refreshButtonState: viewModel.refreshButtonState,
//                            refreshButtonSize: isSmallScreenSize ? .small : .default,
//                            opacity: currentStep.balanceStackOpacity
//                        )
                    }
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
//                    .background(Color.yellow)
                }
//                .frame(minHeight: 210)
                .readSize { value in
                    animationContainerSize = value
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
                            case .read:
                                navigation.readToShop = true
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
//                messages
//                buttons
//                Spacer()
//                    .frame(width: 1, height: 20)
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
        .onAppear(perform: {
            viewModel.playInitialAnim()
        })
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
