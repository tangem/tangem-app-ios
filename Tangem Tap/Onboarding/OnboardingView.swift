//
//  OnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case read, disclaimer, createWallet, topup, backup, confetti
    
    var iconName: String {
        String(describing: self)
    }
    
    var cardImageWidthRate: CGFloat {
        switch self {
        case .read: return 0.925
        default: return 1
        }
    }
    
    var cardWidthHeightRate: CGFloat {
        1.826
    }
    
    var cardImageMaxSize: CGSize {
        .init(width: 347 * 0.6, height: 190 * 0.6)
    }
}

struct ProgressOnboardingView: View {
    
    var steps: [OnboardingStep]
    var currentStep: Int
    
    var body: some View {
        HStack {
            OnboardingStepIconView(imageName: "wave.3.right", filled: currentStep != 0)
        }
    }
}

struct OnboardingView: View {
    
    @EnvironmentObject var navigation: NavigationCoordinator
    @ObservedObject var viewModel: OnboardingViewModel
    
    @State private var cardScanned: Bool = false

    var navigationLinks: some View {
        VStack {
            NavigationLink(destination: WebViewContainer(url: viewModel.shopURL, title: "home_button_shop"),
                           isActive: $navigation.readToShop)
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                navigationLinks
                
                ProgressOnboardingView(steps: viewModel.steps, currentStep: viewModel.currentStep.rawValue)
                
                
                RotatingCardView(baseCardName: "card_twin",
                                 backCardImage: UIImage(named: "card_btc")!,
                                 cardScanned: viewModel.currentStep != .read)
                    .frame(size: calculateCardSize(for: viewModel.currentStep, readerProxy: proxy))
                    .position(x: proxy.size.width / 2,
                              y: proxy.safeAreaInsets.top + calculateCardSize(for: viewModel.currentStep, readerProxy: proxy).height / 2)
                Spacer()
                Button(action: {
                    self.viewModel.transitionToNextStep()
                }, label: {
                    Text("Animate cards")
                        .padding()
                })
                Button(action: {
                    viewModel.executeStep()
                }, label: {
                    Text("Yes! Scan card")
                        .padding()
                })
                Button(action: {
                    
                }, label: {
                    Text("Buy new card")
                        .padding()
                })
                Spacer()
            }
        }
    }
    
    private func calculateCardSize(for step: OnboardingStep, readerProxy: GeometryProxy) -> CGSize {
        return step.cardImageMaxSize
    }
}

struct OnboardingView_Previews: PreviewProvider {
    
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        OnboardingView(viewModel: assembly.makeOnboardingViewModel())
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
