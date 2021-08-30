//
//  LetsStartOnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct LetsStartOnboardingView: View {
    
    enum LetsStartStep {
        case welcome, letsStart
    }
    
    enum CardLayout: OnboardingCardFrameCalculator {
        case main, supplementary
        
        var cardHeightWidthRatio: CGFloat { 0.609 }
        
        func rotationAngle(at step: LetsStartStep) -> Angle {
            switch (self, step) {
            case (.main, .welcome): return Angle(degrees: -2)
            case (.supplementary, .welcome): return Angle(degrees: -21)
            default: return .zero
            }
        }
        
        func offset(at step: LetsStartStep, containerSize: CGSize) -> CGSize {
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
        
        func opacity(at step: LetsStartStep) -> Double {
            guard self == .supplementary else {
                return 1
            }
            
            if step == .welcome {
                return 1
            }
            
            return 0
        }
        
        func frameSizeRatio(for step: LetsStartStep) -> CGFloat {
            switch (self, step) {
            case (.main, _): return 0.375
            case (.supplementary, _): return 0.32
            }
        }
        
        func cardFrameMinHorizontalPadding(at step: LetsStartStep) -> CGFloat {
            switch (self, step) {
            case (.main, _): return 98
            case (.supplementary, _): return 106
            }
        }
    }
    
    @ObservedObject var viewModel: LetsStartOnboardingViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    @State var containerSize: CGSize = .zero
    
    var currentStep: LetsStartStep { .welcome }
    
    @ViewBuilder
    var navigationLinks: some View {
        NavigationLink(destination: WebViewContainer(url: viewModel.shopURL, title: "home_button_shop"),
                       isActive: $navigation.readToShop)
    }
    
    @ViewBuilder
    var buttons: some View {
        TangemButton(isLoading: viewModel.isScanningCard,
                     title: "home_button_scan",
                     size: .wide) {
            viewModel.scanCard()
        }
        .buttonStyle(TangemButtonStyle(color: .green, font: .system(size: 18, weight: .semibold)))
        .padding(.bottom, 10)
        
        TangemButton(isLoading: false,
                     title: "onboarding_button_shop",
                     size: .wide) {
            navigation.readToShop = true
        }
        .buttonStyle(TangemButtonStyle(color: .transparentWhite, font: .system(size: 18, weight: .semibold)))
        .padding(.bottom, 16)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                navigationLinks
                
                ZStack {
                    Image("light_card")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(size: CardLayout.supplementary.frame(for: currentStep, containerSize: containerSize))
                        .rotationEffect(CardLayout.supplementary.rotationAngle(at: currentStep))
                        .offset(CardLayout.supplementary.offset(at: currentStep, containerSize: containerSize))
                        .opacity(CardLayout.supplementary.opacity(at: currentStep))
                    OnboardingCardView(baseCardName: "dark_card",
                                       backCardImage: nil,
                                       cardScanned: false)
                        .rotationEffect(CardLayout.main.rotationAngle(at: currentStep))
                        .offset(CardLayout.main.offset(at: currentStep, containerSize: containerSize))
                        .frame(size: CardLayout.main.frame(for: currentStep, containerSize: containerSize))
                }
                .position(x: containerSize.width / 2, y: containerSize.height / 2)
//                .background(Color.red)
                .readSize { size in
                    containerSize = size
                }
                Group {
                    CardOnboardingMessagesView(title: "onboarding_read_title",
                                               subtitle: "onboarding_read_subtitle") {
                        
                    }
                    
                    Spacer()
                        .frame(minHeight: 30, maxHeight: 66)
                    
                    buttons
                        .sheet(isPresented: $navigation.readToDisclaimer, content: {
                            DisclaimerView(style: .sheet)
                        })
                }
            }
        }
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
