//
//  WelcomeCardLayout.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum WelcomeCardLayout: OnboardingCardFrameCalculator {
    case main, supplementary
    
    var cardHeightWidthRatio: CGFloat { 0.609 }
    
    var zIndex: Double {
        switch self {
        case .main: return 100
        case .supplementary: return 90
        }
    }
    
    static func defaultSettings(in container: CGSize, animated: Bool) -> (main: AnimatedViewSettings, supplement: AnimatedViewSettings) {
        (main: WelcomeCardLayout.main.cardSettings(at: .welcome, in: container, animated: animated),
         supplement: WelcomeCardLayout.supplementary.cardSettings(at: .welcome, in: container, animated: animated))
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
    
    func cardHeightToContainerHeightRatio(for step: WelcomeStep) -> CGFloat {
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
