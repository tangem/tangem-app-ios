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
    
    func offset(at step: TwinsOnboardingStep, in container: CGSize) -> CGSize {
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

//    func offset(at step: OnboardingStep, containerSize: CGSize) -> CGSize {
//        let containerHeight = max(containerSize.height, containerSize.width)
//        switch (self, step) {
//        case (.main, .read):
//            let heightOffset = containerHeight * 0.183
//            return .init(width: -1, height: -heightOffset)
//        case (.main, .createWallet):
//            let offset = containerHeight * 0.02
//            return .init(width: 0, height: -offset)
//        case (.main, _):
//            let backgroundSize = step.cardBackgroundFrame(containerSize: containerSize)
//            let backgroundOffset = step.cardBackgroundOffset(containerSize: containerSize)
//            return .init(width: 0, height: backgroundOffset.height - backgroundSize.height / 2 + 8)
//        case (.supplementary, .read):
//            let offset = containerHeight * 0.137
//            return .init(width: 8, height: offset)
//        case (.supplementary, _): return .zero
//        }
//    }
    
    func rotationAngle(at step: TwinsOnboardingStep) -> Angle {
        switch (step, self) {
        case (.intro, _): return Angle(degrees: -2)
        default: return .zero
        }
    }
    
    func zIndex(at step: TwinsOnboardingStep) -> Double {
        let topCardIndex: Double = 10
        let lowerCardIndex: Double = 9
        switch (step, self) {
        case (.second, .first): return lowerCardIndex
        case (.second, .second): return topCardIndex
        case (_, .first): return topCardIndex
        case (_, .second): return lowerCardIndex
        }
    }
    
    func opacity(at step: TwinsOnboardingStep) -> Double {
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
        [.intro(pairNumber: "0128"), .first, .second, .third, .topup, .confetti, .done]
    }
    
    static var twinningProcessSteps: [TwinsOnboardingStep] {
        [.first, .second, .third]
    }
    
    static var topupSteps: [TwinsOnboardingStep] {
        [.topup, .confetti, .done]
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
    
    @ViewBuilder
    var firstCard: some View {
        OnboardingCardView(baseCardName: "dark_card",
                           backCardImage: viewModel.firstTwinImage,
                           cardScanned: viewModel.firstTwinImage != nil)
    }
    
//    [REDACTED_USERNAME]
//    var secondCard: some View {
//        OnboardingCardView(baseCardName: "light_card",
//                           backCardImage: nil,
//                           cardScanned: false)
//    }
    
    @ViewBuilder
    var buttons: some View {
        TangemButton(isLoading: false,
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
    @State var size: CGSize = .zero
    
    var screenSize: CGSize {
        UIScreen.main.bounds.size
    }
    
    var body: some View {
        ZStack {
            navigationLinks
            
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
                        
                        secondCard(in: geom.size)
                        
                        
                        let firstCardFrameSize = TwinOnboardingCardLayout.first.frame(for: currentStep,
                                                                                      containerSize: containerSize)
                        let firstCardOffset = TwinOnboardingCardLayout.first.offset(at: currentStep, in: containerSize)
                        firstCard
                            .rotationEffect(TwinOnboardingCardLayout.first.rotationAngle(at: currentStep))
                            .offset(firstCardOffset)
                            .frame(size: firstCardFrameSize)
                            .opacity(TwinOnboardingCardLayout.first.opacity(at: currentStep))
                            .zIndex(TwinOnboardingCardLayout.first.zIndex(at: currentStep))
//                            .overlay(
//                                Text("Frame: \(firstCardFrameSize.description)\nOffset \(firstCardOffset.description)")
//                                    .font(.system(size: 14))
//                                    .foregroundColor(.red)
//                                    .offset(firstCardOffset)
//                            )
                    }
//                    .overlay(
//                        Text("Size: \(geom.size.description)")
//                            .offset(x: -90, y: geom.size.height / 2 - 30)
//                            .foregroundColor(.blue)
//                    )
                    .position(x: geom.size.width / 2, y: geom.size.height / 2)
                }
                .readSize { containerSize in
                    self.containerSize = containerSize
                }
                Group {
                    CardOnboardingMessagesView(title: currentStep.title,
                                               subtitle: currentStep.subtitle) {
                        viewModel.reset()
                    }
                    .frame(minHeight: 116, alignment: .top)
//                    .fixedSize(horizontal: false, vertical: true)
//                    .background(Color.orange)
//                    .overlay(
//                        Text("Messages size: \(size.description)")
//                            .offset(CGSize(width: 0, height: 100.0))
//                    )
                    .readSize { size in
                        self.size = size
                    }
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
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    func secondCard(in container: CGSize) -> some View {
        let secondCardFrameSize = TwinOnboardingCardLayout.second.frame(for: currentStep,
                                                                      containerSize: container)
        let secondCardOffset = TwinOnboardingCardLayout.second.offset(at: currentStep, in: container)
        OnboardingCardView(baseCardName: "light_card",
                           backCardImage: viewModel.secondTwinImage,
                           cardScanned: viewModel.secondTwinImage != nil)
            .frame(size: secondCardFrameSize)
            .offset(secondCardOffset)
            .rotationEffect(TwinOnboardingCardLayout.second.rotationAngle(at: currentStep))
            .opacity(TwinOnboardingCardLayout.second.opacity(at: currentStep))
            .zIndex(TwinOnboardingCardLayout.second.zIndex(at: currentStep))
//            .overlay(
//                Text("Frame: \(secondCardFrameSize.description)\nOffset \(secondCardOffset.description)")
//                    .font(.system(size: 14))
//                    .foregroundColor(.purple)
//                    .offset(secondCardOffset)
//            )
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
//            .previewGroup(devices: [.iPhoneX], withZoomed: false)
    }
}
