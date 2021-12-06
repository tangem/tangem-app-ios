//
//  SingleCardOnboardingCardsLayout.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum SingleCardOnboardingCardsLayout: OnboardingCardFrameCalculator {
    case main, supplementary
    
    var cardHeightWidthRatio: CGFloat { 0.609 }
    
    func cardAnimSettings(for step: SingleCardOnboardingStep, containerSize: CGSize, animated: Bool) -> CardAnimSettings {
        .init(frame: frame(for: step, containerSize: containerSize),
              offset: offset(at: step, containerSize: containerSize),
              scale: 1.0,
              opacity: opacity(at: step),
              zIndex: self == .main ? 100 : 10,
              rotationAngle: rotationAngle(at: step),
              animType: animated ? .default : .noAnim)
    }
    
    func rotationAngle(at step: SingleCardOnboardingStep) -> Angle {
        .zero
    }
    
    func offset(at step: SingleCardOnboardingStep, containerSize: CGSize) -> CGSize {
        switch (self, step) {
        case (.main, .createWallet):
            return step.cardBackgroundOffset(containerSize: containerSize)
        case (.main, _):
            let backgroundSize = step.cardBackgroundFrame(containerSize: containerSize)
            let backgroundOffset = step.cardBackgroundOffset(containerSize: containerSize)
            return .init(width: 0, height: backgroundOffset.height - backgroundSize.height / 2 + 8)
        case (.supplementary, _): return .zero
        }
    }
    
    func opacity(at step: SingleCardOnboardingStep) -> Double {
        if step == .success {
            return 0
        }
        
        guard self == .supplementary else {
            return 1
        }
        
        return 0
    }
    
    func cardHeightToContainerHeightRatio(for step: SingleCardOnboardingStep) -> CGFloat {
        switch (self, step) {
        case (.main, .createWallet): return 0.536
        case (.main, _): return 0.246
        case (.supplementary, _): return 0.18
        }
    }
    
    func cardFrameMinHorizontalPadding(at step: SingleCardOnboardingStep) -> CGFloat {
        switch (self, step) {
        case (.main, .createWallet): return 80
        case (.main, _): return 234
        case (.supplementary, _): return 106
        }
    }
}
