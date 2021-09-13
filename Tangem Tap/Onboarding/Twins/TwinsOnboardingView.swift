//
//  TwinsOnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

protocol OnboardingCardFrameCalculator {
    associatedtype Step
    var cardHeightWidthRatio: CGFloat { get }
    func frame(for step: Step, containerSize: CGSize) -> CGSize
    func frameSizeRatio(for step: Step) -> CGFloat
    func cardFrameMinHorizontalPadding(at step: Step) -> CGFloat
}

extension OnboardingCardFrameCalculator {
    func frame(for step: Step, containerSize: CGSize) -> CGSize {
        let height = containerSize.height * frameSizeRatio(for: step)
        let width = height / cardHeightWidthRatio
        let maxWidth = containerSize.width - cardFrameMinHorizontalPadding(at: step)
        return width > maxWidth ?
            .init(width: maxWidth, height: maxWidth * cardHeightWidthRatio) :
            .init(width: width, height: height)
    }
}

enum TwinOnboardingCardLayout: OnboardingCardFrameCalculator {
    
    typealias Step = TwinsOnboardingStep
    
    case first, second
    
    var cardHeightWidthRatio: CGFloat { 0.519 }
    
    func animSettings(at step: TwinsOnboardingStep, containerSize: CGSize, stackCalculator: StackCalculator, animated: Bool) -> AnimatedViewSettings {
        switch (step, self) {
        case (.first, _), (.second, .second), (.third, .first):
            return .init(targetSettings: stackCalculator.cardsSettings[stackIndex(at: step)],
                         intermediateSettings: nil)
        case (.second, .first), (.third, .second):
            return .init(targetSettings: stackCalculator.cardsSettings[stackIndex(at: step)],
                         intermediateSettings: stackCalculator.prehideAnimSettings)
        default:
            return .init(targetSettings: CardAnimSettings(frame: frame(for: step, containerSize: containerSize),
                                                          offset: offset(at: step, in: containerSize),
                                                          scale: 1.0,
                                                          opacity: opacity(at: step),
                                                          zIndex: zIndex(at: step),
                                                          rotationAngle: rotationAngle(at: step),
                                                          animType: animated ? .default : .noAnim),
                         intermediateSettings: nil)
        }
    }
    
    func cardFrameMinHorizontalPadding(at step: TwinsOnboardingStep) -> CGFloat {
        switch (step, self) {
        case (.intro, _): return 75
        case (.first, .first), (.second, .second), (.third, .first): return 80
        case (.first, .second), (.second, .first), (.third, .second): return 120
        case (.topup, _), (.confetti, _), (.done, _): return 220
        }
    }
    
    func frameSizeRatio(for step: TwinsOnboardingStep) -> CGFloat {
        switch (step, self) {
        case (.intro, _): return 0.431
        case (.first, .first), (.second, .second), (.third, .first):
            return 0.454
        case (.first, .second), (.second, .first), (.third, .second):
            return 0.395
        case (.topup, _), (.confetti, _), (.done, _):
            return 0.246
        }
    }
    
    private func offset(at step: TwinsOnboardingStep, in container: CGSize) -> CGSize {
        let containerHeight = container.height
        switch (step, self) {
        case (.intro, .first):
            let heightOffset = containerHeight * 0.114
            let widthOffset = container.width * 0.131
            return .init(width: -widthOffset, height: -heightOffset)
        case (.intro, .second):
            let heightOffset = containerHeight * 0.183
            let widthOffset = container.width * 0.131
            return .init(width: widthOffset, height: heightOffset)
        case (.first, .first), (.second, .second), (.third, .first):
//            return .init(width: 0, height: -containerHeight * 0.128)
            fallthrough
        case (.first, .second), (.second, .first), (.third, .second):
//            return .init(width: 0, height: containerHeight * 0.095)
            return .zero
        case (.topup, _), (.confetti, _), (.done, _):
            let backgroundSize = step.backgroundFrame(in: container)
            let backgroundOffset = step.backgroundOffset(in: container)
            return .init(width: 0, height: backgroundOffset.height - backgroundSize.height / 2 + 8)
        }
    }
    
    private func rotationAngle(at step: TwinsOnboardingStep) -> Angle {
        switch (step, self) {
        case (.intro, _): return Angle(degrees: -2)
        default: return .zero
        }
    }
    
    private func zIndex(at step: TwinsOnboardingStep) -> Double {
        let topCardIndex: Double = 10
        let lowerCardIndex: Double = 9
        switch (step, self) {
        case (.second, .first): return lowerCardIndex
        case (.second, .second): return topCardIndex
        case (_, .first): return topCardIndex
        case (_, .second): return lowerCardIndex
        }
    }
    
    private func stackIndex(at step: TwinsOnboardingStep) -> Int {
        let topCard = 0
        let lowerCard = 1
        switch (step, self) {
        case (.second, .first): return lowerCard
        case (.second, .second): return topCard
        case (_, .first): return topCard
        case (_, .second): return lowerCard
        }
    }
    
    private func opacity(at step: TwinsOnboardingStep) -> Double {
        switch (step, self) {
        case (.intro, _): return 1
        case (.first, .second), (.second, .first), (.third, .second):
            return 0.9
        case (.second, .second): return 1
        case (_, .second): return 0
        case (_, .first): return 1
        }
    }
    
}

enum TwinsOnboardingStep {
    case intro(pairNumber: String), first, second, third, topup, confetti, done
    
    static var previewCases: [TwinsOnboardingStep] {
        [.intro(pairNumber: "0128"), .topup, .confetti, .done]
    }
    
    static var twinningProcessSteps: [TwinsOnboardingStep] {
        [.first, .second, .third]
    }
    
    static var topupSteps: [TwinsOnboardingStep] {
        [.topup, .confetti, .done]
    }
    
    var topTwinCardIndex: Int {
        switch self {
        case .second: return 1
        default: return 0
        }
    }
    
    var isModal: Bool {
        switch self {
        case .second, .third: return true
        default: return false
        }
    }
    
    var title: LocalizedStringKey {
        switch self {
        case .intro: return "twins_onboarding_subtitle"
        case .first: return "onboarding_title_twin_first_card"
        case .second: return "onboarding_title_twin_second_card"
        case .third: return "onboarding_title_twin_first_card"
        case .topup: return "onboarding_topup_title"
        case .confetti: return "onboarding_confetti_title"
        case .done: return ""
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .intro(let pairNumber): return "onboarding_subtitle_intro \(pairNumber)"
        case .first, .second, .third: return "onboarding_subtitle_reset_twin_warning"
        case .topup: return "onboarding_topup_subtitle"
        case .confetti: return "Your crypto card is activated and ready to be used"
        case .done: return ""
        }
    }
    
    var mainButtonTitle: LocalizedStringKey {
        switch self {
        case .intro: return "common_continue"
        case .first, .third: return "onboarding_button_tap_first_card"
        case .second: return "onboarding_button_tap_second_card"
        case .topup: return "onboarding_button_buy_crypto"
        case .confetti: return "common_continue"
        case .done: return "common_continue"
        }
    }
    
    var supplementButtonTitle: LocalizedStringKey {
        switch self {
        case .topup: return "onboarding_button_show_address_qr"
        default: return ""
        }
    }
    
    var isSupplementButtonActive: Bool {
        switch self {
        case .topup: return true
        default: return false
        }
    }
    
    func backgroundFrame(in container: CGSize) -> CGSize {
        switch self {
        case .topup, .confetti, .done:
            return defaultBackgroundFrameSize(in: container)
        default: return .init(width: 10, height: 10)
        }
    }
    
    func backgroundCornerRadius(in container: CGSize) -> CGFloat {
        switch self {
        case .topup, .confetti, .done: return defaultBackgroundCornerRadius
        default: return backgroundFrame(in: container).height / 2
        }
    }
    
    func backgroundOffset(in container: CGSize) -> CGSize {
        defaultBackgroundOffset(in: container)
    }
    
    var backgroundOpacity: Double {
        switch self {
        case .topup, .confetti, .done: return 1
        default: return 0
        }
    }
}
extension TwinsOnboardingStep: OnboardingTopupBalanceLayoutCalculator {}

protocol OnboardingTopupBalanceLayoutCalculator {}

extension OnboardingTopupBalanceLayoutCalculator {
    var defaultBackgroundCornerRadius: CGFloat { 8 }
    
    func defaultBackgroundFrameSize(in container: CGSize, isWithNavbar: Bool = true) -> CGSize {
        guard isWithNavbar else {
            return .init(width: container.width * 0.787, height: 0.61 * container.height)
        }
        
        return .init(width: container.width * 0.787, height: 0.487 * container.height)
    }
    
    func defaultBackgroundOffset(in container: CGSize, isWithNavbar: Bool = true) -> CGSize {
        guard isWithNavbar else {
            let height = 0.021 * container.height
            return .init(width: 0, height: -height)
        }
        
        return .init(width: 0, height: 0.112 * container.height)
    }
}

struct TwinsOnboardingView: View {
    
    @ObservedObject var viewModel: TwinsOnboardingViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    var currentStep: TwinsOnboardingStep { viewModel.currentStep }
    
    @ViewBuilder
    var navigationLinks: some View {
        NavigationLink(destination: WebViewContainer(url: viewModel.buyCryptoURL,
                                                     title: "wallet_button_topup",
                                                     addLoadingIndicator: true,
                                                     urlActions: [ viewModel.buyCryptoCloseUrl : { _ in
                                                        navigation.onboardingToBuyCrypto = false
                                                     }
                                                     ]),
                       isActive: $navigation.onboardingToBuyCrypto)
    }
    
    @State var containerSize: CGSize = .zero
    @State var welcomeDisplayed: Bool = false
    
    var screenSize: CGSize {
        UIScreen.main.bounds.size
    }
    
    var isNavbarVisible: Bool {
        viewModel.isInitialAnimPlayed
    }
    
    private var navbarSize: CGSize {
        .init(width: screenSize.width, height: 44)
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
                    ZStack(alignment: .center) {
                        
                        // Navbar is added to ZStack instead of VStack because of wrong animation when container changed
                        // and cards jumps instead of smooth transition
                        NavigationBar(title: "Tangem Twin",
                                      settings: .init(titleFont: .system(size: 17, weight: .semibold), backgroundColor: .clear))
                            .offset(x: 0, y: -geom.size.height / 2 + (isNavbarVisible ? navbarSize.height / 2 : 0))
                            .opacity(isNavbarVisible ? 1.0 : 0.0)
                        
                        let backgroundFrame = currentStep.backgroundFrame(in: containerSize)
                        let backgroundOffset = currentStep.backgroundOffset(in: containerSize)
                        OnboardingTopupBalanceView(
                            backgroundFrameSize: backgroundFrame,
                            cornerSize: currentStep.backgroundCornerRadius(in: containerSize),
                            backgroundOffset: backgroundOffset,
                            balance: viewModel.cardBalance,
                            balanceUpdaterFrame: backgroundFrame,
                            balanceUpdaterOffset: backgroundOffset,
                            refreshAction: {
                                viewModel.updateCardBalance()
                            },
                            refreshButtonState: viewModel.refreshButtonState,
                            refreshButtonSize: .medium,
                            refreshButtonOpacity: currentStep.backgroundOpacity
                        )
                        
                        AnimatedView(settings: viewModel.$secondTwinSettings) {
                            OnboardingCardView(baseCardName: "light_card",
                                               backCardImage: viewModel.secondTwinImage,
                                               cardScanned: viewModel.secondTwinImage != nil)
                        }
                        AnimatedView(settings: viewModel.$firstTwinSettings) {
                            OnboardingCardView(baseCardName: "dark_card",
                                               backCardImage: viewModel.firstTwinImage,
                                               cardScanned: viewModel.firstTwinImage != nil)
                        }
                    }
                    .frame(size: geom.size)
                }
                .readSize { size in
                    withAnimation {
                        containerSize = size
                        viewModel.setupContainerSize(size)
                    }
                }
                
                OnboardingTextButtonView(
                    title: viewModel.title,
                    subtitle: viewModel.subtitle,
                    buttonsSettings: .init(
                        mainTitle: viewModel.mainButtonTitle,
                        mainSize: .wide,
                        mainAction: {
                            withAnimation {
                                
                            }
                            viewModel.executeStep()
                        },
                        mainIsBusy: viewModel.isModelBusy,
                        supplementTitle: viewModel.supplementButtonTitle,
                        supplementSize: .wide,
                        supplementAction: {
                            viewModel.supplementButtonAction()
                        },
                        isVisible: currentStep.isSupplementButtonActive,
                        containSupplementButton: true),
                    titleAction: {
                        viewModel.reset()
                        withAnimation {
                            
                        }
                    }
                )
                .padding(.horizontal, 40)
            }
            BottomSheetView(isPresented: viewModel.$isAddressQrBottomSheetPresented,
                                     hideBottomSheetCallback: {
                                        viewModel.isAddressQrBottomSheetPresented = false
                                     }, content: {
                                        AddressQrBottomSheetContent(shareAddress: viewModel.shareAddress,
                                                                    address: viewModel.walletAddress)
                                     })
                .frame(maxWidth: screenSize.width)
        }
        .preference(key: ModalSheetPreferenceKey.self, value: currentStep.isModal)
        .navigationBarHidden(true)
        .onAppear(perform: {
            if viewModel.isInitialAnimPlayed {
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.viewModel.playInitialAnim()
            }
            
        })
    }
}

struct ButtonsSettings {
    let mainTitle: LocalizedStringKey
    let mainSize: ButtonSize
    let mainAction: (() -> Void)?
    let mainIsBusy: Bool
    
    let supplementTitle: LocalizedStringKey
    let supplementSize: ButtonSize
    let supplementAction: (() -> Void)?
    let isVisible: Bool
    let containSupplementButton: Bool
}

struct OnboardingTextButtonView: View {
    
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let buttonsSettings: ButtonsSettings
    
    let titleAction: (() -> Void)?
    
    @ViewBuilder
    var buttons: some View {
        VStack(spacing: 10) {
            TangemButton(isLoading: buttonsSettings.mainIsBusy,
                         title: buttonsSettings.mainTitle,
                         size: buttonsSettings.mainSize) {
                withAnimation {
                    buttonsSettings.mainAction?()
                }
            }
            .buttonStyle(TangemButtonStyle(color: .green,
                                           font: .system(size: 17, weight: .semibold),
                                           isDisabled: false))
            
            if buttonsSettings.containSupplementButton {
                TangemButton(isLoading: false,
                             title: buttonsSettings.supplementTitle,
                             size: buttonsSettings.supplementSize) {
                    buttonsSettings.supplementAction?()
                }
                .opacity(buttonsSettings.isVisible ? 1.0 : 0.0)
                .allowsHitTesting(buttonsSettings.isVisible)
                .buttonStyle(TangemButtonStyle(color: .transparentWhite,
                                               font: .system(size: 17, weight: .semibold),
                                               isDisabled: false))
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CardOnboardingMessagesView(title: title,
                                       subtitle: subtitle) {
                titleAction?()
            }
            .frame(alignment: .top)
            Spacer()
            buttons
                .padding(.bottom, 16)
                
        }
        .frame(maxHeight: 304)
    }
    
}

struct OnboardingTopupBalanceView: View {
    
    let backgroundFrameSize: CGSize
    let cornerSize: CGFloat
    let backgroundOffset: CGSize
    
    let balance: String
    let balanceUpdaterFrame: CGSize
    let balanceUpdaterOffset: CGSize
    
    let refreshAction: () -> Void
    let refreshButtonState: OnboardingCircleButton.State
    let refreshButtonSize: OnboardingCircleButton.Size
    let refreshButtonOpacity: Double
    
    var body: some View {
        ZStack {
            Rectangle()
                .frame(size: backgroundFrameSize)
                .cornerRadius(cornerSize)
                .foregroundColor(Color.tangemTapBgGray)
                .opacity(0.8)
                .offset(backgroundOffset)
            OnboardingTopupBalanceUpdater(
                balance: balance,
                frame: balanceUpdaterFrame,
                offset: balanceUpdaterOffset,
                refreshAction: {
                    refreshAction()
                },
                refreshButtonState: refreshButtonState,
                refreshButtonSize: refreshButtonSize,
                opacity: refreshButtonOpacity
            )
        }
    }
    
}

struct TwinsOnboardingView_Previews: PreviewProvider {
    
    static var assembly: Assembly = {
        let assembly = Assembly.previewAssembly
//        assembly.makeCardTwinOnboardingViewModel(with: nil)
        return assembly
    }()
    
    static var previews: some View {
        TwinsOnboardingView(viewModel: assembly.getTwinsOnboardingViewModel())
            .environmentObject(assembly.services.navigationCoordinator)
        // don't know why, preview group doesn't display layout properly. If you want to try live preview,
        // you should select launch device to the right of target selection
//            .previewGroup(devices: [.iPhone7], withZoomed: true)
    }
}
