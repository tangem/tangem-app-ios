//
//  LetsStartOnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum WelcomeStep {
    case welcome, letsStart
    
    var title: LocalizedStringKey {
        switch self {
        case .welcome: return "onboarding_read_title"
        case .letsStart: return "onboarding_read_title"
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .welcome: return "onboarding_read_subtitle"
        case .letsStart: return "onboarding_read_subtitle"
        }
    }
    
    var mainButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return "home_button_scan"
        case .letsStart: return "home_button_scan"
        }
    }
    
    var supplementButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return "onboarding_button_shop"
        case .letsStart: return "onboarding_button_shop"
        }
    }
}

enum WelcomeCardLayout: OnboardingCardFrameCalculator {
    case main, supplementary
    
    var cardHeightWidthRatio: CGFloat { 0.609 }
    
    var zIndex: Double {
        switch self {
        case .main: return 100
        case .supplementary: return 90
        }
    }
    
    func cardSettings(at step: WelcomeStep, in container: CGSize, animated: Bool) -> AnimatedViewSettings {
        .init(
            targetSettings: .init(
                frame: frame(for: step, containerSize: container),
                offset: offset(at: step, containerSize: container),
                scale: 1.0,
                opacity: opacity(at: step),
                zIndex: zIndex,
                rotationAngle: rotationAngle(at: step),
                animType: animated ? .default : .noAnim
            ),
            intermediateSettings: nil
        )
    }
    
    func rotationAngle(at step: WelcomeStep) -> Angle {
        switch (self, step) {
        case (.main, .welcome): return Angle(degrees: -2)
        case (.supplementary, .welcome): return Angle(degrees: -21)
        default: return .zero
        }
    }
    
    func offset(at step: WelcomeStep, containerSize: CGSize) -> CGSize {
        let containerHeight = max(containerSize.height, containerSize.width)
        switch (self, step) {
        case (.main, _):
            let heightOffset = containerHeight * 0.183
            return .init(width: -1, height: -heightOffset)
        case (.supplementary, _):
            let offset = containerHeight * 0.137
            return .init(width: 8, height: offset)
        }
    }
    
    func opacity(at step: WelcomeStep) -> Double {
        guard self == .supplementary else {
            return 1
        }
        
        if step == .welcome {
            return 1
        }
        
        return 0
    }
    
    func frameSizeRatio(for step: WelcomeStep) -> CGFloat {
        switch (self, step) {
        case (.main, _): return 0.375
        case (.supplementary, _): return 0.32
        }
    }
    
    func cardFrameMinHorizontalPadding(at step: WelcomeStep) -> CGFloat {
        switch (self, step) {
        case (.main, _): return 98
        case (.supplementary, _): return 106
        }
    }
}

struct LetsStartOnboardingView: View {
    
    enum CardLayout: OnboardingCardFrameCalculator {
        case main, supplementary
        
        var cardHeightWidthRatio: CGFloat { 0.609 }
        
        func rotationAngle(at step: WelcomeStep) -> Angle {
            switch (self, step) {
            case (.main, .welcome): return Angle(degrees: -2)
            case (.supplementary, .welcome): return Angle(degrees: -21)
            default: return .zero
            }
        }
        
        func offset(at step: WelcomeStep, containerSize: CGSize) -> CGSize {
            let containerHeight = max(containerSize.height, containerSize.width)
            switch (self, step) {
            case (.main, _):
                let heightOffset = containerHeight * 0.183
                return .init(width: -1, height: -heightOffset)
            case (.supplementary, _):
                let offset = containerHeight * 0.137
                return .init(width: 8, height: offset)
            }
        }
        
        func opacity(at step: WelcomeStep) -> Double {
            guard self == .supplementary else {
                return 1
            }
            
            if step == .welcome {
                return 1
            }
            
            return 0
        }
        
        func frameSizeRatio(for step: WelcomeStep) -> CGFloat {
            switch (self, step) {
            case (.main, _): return 0.375
            case (.supplementary, _): return 0.32
            }
        }
        
        func cardFrameMinHorizontalPadding(at step: WelcomeStep) -> CGFloat {
            switch (self, step) {
            case (.main, _): return 98
            case (.supplementary, _): return 106
            }
        }
    }
    
    @ObservedObject var viewModel: LetsStartOnboardingViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    @State var containerSize: CGSize = .zero
    
    var currentStep: WelcomeStep { .welcome }
    
    @ViewBuilder
    var navigationLinks: some View {
        NavigationLink(destination: WebViewContainer(url: viewModel.shopURL, title: "home_button_shop"),
                       isActive: $navigation.readToShop)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                navigationLinks
                
                ZStack {
                    AnimatedView(settings: viewModel.$lightCardSettings) {
                        Image("light_card")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
//                        .frame(size: CardLayout.supplementary.frame(for: currentStep, containerSize: containerSize))
//                        .rotationEffect(CardLayout.supplementary.rotationAngle(at: currentStep))
//                        .offset(CardLayout.supplementary.offset(at: currentStep, containerSize: containerSize))
//                        .opacity(CardLayout.supplementary.opacity(at: currentStep))
                    AnimatedView(settings: viewModel.$darkCardSettings) {
                        OnboardingCardView(baseCardName: "dark_card",
                                           backCardImage: nil,
                                           cardScanned: false)
                    }
//
//                        .rotationEffect(CardLayout.main.rotationAngle(at: currentStep))
//                        .offset(CardLayout.main.offset(at: currentStep, containerSize: containerSize))
//                        .frame(size: CardLayout.main.frame(for: currentStep, containerSize: containerSize))
                }
                .position(x: containerSize.width / 2, y: containerSize.height / 2)
//                .background(Color.red)
                .readSize { size in
                    containerSize = size
                    viewModel.setupContainer(size)
                }
                
                OnboardingTextButtonView(
                    title: currentStep.title,
                    subtitle: currentStep.subtitle,
                    buttonsSettings: ButtonsSettings.init(
                        mainTitle: currentStep.mainButtonTitle,
                        mainSize: .wide,
                        mainAction: {
                            viewModel.scanCard()
                        },
                        mainIsBusy: viewModel.isScanningCard,
                        supplementTitle: currentStep.supplementButtonTitle,
                        supplementSize: .wide,
                        supplementAction: {
                            navigation.readToShop = true
                        },
                        isVisible: true,
                        containSupplementButton: true
                    )) {
                    
                }
                .padding(.horizontal, 40)
                .sheet(isPresented: $navigation.onboardingToDisclaimer, content: {
                    DisclaimerView(style: .sheet(acceptCallback: viewModel.acceptDisclaimer))
                        .presentation(modal: true, onDismissalAttempt: nil, onDismissed: viewModel.onboardingDismissed)
                })
            }
        }
        .alert(item: $viewModel.error, content: { error in
            error.alert
        })
        .navigationBarHidden(true)
    }
}

struct LetsStartOnboardingView_Previews: PreviewProvider {
    
    static let assembly: Assembly = .previewAssembly
    
    static var previews: some View {
        LetsStartOnboardingView(viewModel: assembly.getLetsStartOnboardingViewModel(with: { _ in }))
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
