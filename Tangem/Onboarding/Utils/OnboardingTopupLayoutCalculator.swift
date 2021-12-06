//
//  OnboardingTopupLayoutCalculator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import CoreGraphics

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
