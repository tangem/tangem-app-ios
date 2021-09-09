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
        let containerLongestSize = container.height
        switch (step, self) {
        case (.intro, .first):
            let heightOffset = containerLongestSize * 0.234
            let widthOffset = container.width * 0.131
            return .init(width: -widthOffset, height: -heightOffset)
        case (.intro, .second):
            let heightOffset = containerLongestSize * 0.118
            let widthOffset = container.width * 0.131
            return .init(width: widthOffset, height: heightOffset)
        case (.first, .first), (.second, .second), (.third, .first):
            return .init(width: 0, height: -containerLongestSize * 0.128)
        case (.first, .second), (.second, .first), (.third, .second):
            return .init(width: 0, height: -containerLongestSize * 0.039)
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
    
    func defaultBackgroundFrameSize(in container: CGSize) -> CGSize {
        let height = 0.61 * container.height
        return .init(width: container.width * 0.787, height: height)
    }
    
    func defaultBackgroundOffset(in container: CGSize) -> CGSize {
        let height = 0.021 * container.height
        return .init(width: 0, height: -height)
    }
}

struct StackCalculator {
    
    private(set) var prehideAnimSettings: CardAnimSettings = .zero
    private(set) var cardsSettings: [CardAnimSettings] = []
    
    private let maxZIndex: Double = 100
    
    private var containerSize: CGSize = .zero
    private var settings: CardsStackAnimatorSettings = .zero
    
    mutating func setup(for container: CGSize, with settings: CardsStackAnimatorSettings) {
        containerSize = container
        self.settings = settings
        populateSettings()
    }
    
    mutating private func populateSettings() {
        prehideAnimSettings = .zero
        cardsSettings = []
        for i in 0..<settings.numberOfCards {
            cardsSettings.append(cardInStackSettings(at: i))
        }
        prehideAnimSettings = calculatePrehideSettings(for: 0)
    }
    
    private func calculatePrehideSettings(for index: Int) -> CardAnimSettings {
        guard cardsSettings.count > 0 else { return .zero }
        
        let settings = cardsSettings[0]
        let targetFrameHeight = settings.frame.height
        
        return .init(frame: settings.frame,
                     offset: .init(width: 0, height: -(settings.frame.height / 2 + targetFrameHeight / 2) - 10),
                     scale: 1.0,
                     opacity: 1.0,
                     zIndex: maxZIndex + 100,
                     rotationAngle: Angle(degrees: 0),
                     animType: .linear,
                     animDuration: 0.15)
    }
    
    private func cardInStackSettings(at index: Int) -> CardAnimSettings {
        let floatIndex = CGFloat(index)
        let doubleIndex = Double(index)
        let offset: CGFloat = settings.cardsVerticalOffset * 2 * floatIndex
        let scale: CGFloat = max(1 - settings.scaleStep * floatIndex, 0)
        let opacity: Double = max(1 - settings.opacityStep * doubleIndex, 0)
        let zIndex: Double = maxZIndex - Double(index)
        
        return .init(frame: settings.topCardSize,
                     offset: .init(width: 0, height: offset),
                     scale: scale,
                     opacity: opacity,
                     zIndex: zIndex,
                     rotationAngle: .zero,
                     animType: .linear,
                     animDuration: 0.3)
    }
    
}

struct TwinsOnboardingView: View {
    
    @ObservedObject var viewModel: TwinsOnboardingViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
//    [REDACTED_USERNAME] var calc: StackCalculator = .init()
    
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
    
    @ViewBuilder
    var buttons: some View {
        TangemButton(isLoading: viewModel.isModelBusy,
                     title: currentStep.mainButtonTitle,
                     size: .wide) {
            withAnimation {
                viewModel.executeStep()
            }
        }
        .buttonStyle(TangemButtonStyle(color: .green,
                                       font: .system(size: 17, weight: .semibold),
                                       isDisabled: false))
        TangemButton(isLoading: false,
                     title: currentStep.supplementButtonTitle,
                     size: .wide) {
            viewModel.supplementButtonAction()
        }
        .allowsHitTesting(currentStep.isSupplementButtonActive)
        .buttonStyle(TangemButtonStyle(color: .transparentWhite,
                                       font: .system(size: 17, weight: .semibold),
                                       isDisabled: false))
        .padding(.top, 10)
    }
    
    @State var containerSize: CGSize = .zero
    
    var screenSize: CGSize {
        UIScreen.main.bounds.size
    }
    
    var body: some View {
        ZStack {
            navigationLinks
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)
                .frame(maxWidth: screenSize.width)
                .zIndex(100)
            
            VStack(spacing: 0) {
                NavigationBar(title: "Tangem Twin", settings: .init(titleFont: .system(size: 17, weight: .semibold), backgroundColor: .clear))
                GeometryReader { geom in
                    ZStack(alignment: .center) {
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
                    .position(x: geom.size.width / 2, y: geom.size.height / 2)
                }
                .readSize { size in
                    containerSize = size
                    viewModel.setupContainerSize(size)
                }
                Group {
                    CardOnboardingMessagesView(title: currentStep.title,
                                               subtitle: currentStep.subtitle) {
                        viewModel.reset()
                    }
                    .frame(minHeight: 116, alignment: .top)
                    Spacer()
                        .frame(minHeight: 30, maxHeight: 66)
                    buttons
                        .padding(.bottom, 16)
                }
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
//            .previewGroup(devices: [.iPhoneX], withZoomed: false)
    }
}
