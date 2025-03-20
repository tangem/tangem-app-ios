//
//  OnboardingCardFrameCalculator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import UIKit

protocol OnboardingCardFrameCalculator {
    associatedtype Step
    var cardHeightWidthRatio: CGFloat { get }
    func frame(for step: Step, containerSize: CGSize) -> CGSize
    func cardHeightToContainerHeightRatio(for step: Step) -> CGFloat
    func cardFrameMinHorizontalPadding(at step: Step) -> CGFloat
}

extension OnboardingCardFrameCalculator {
    func frame(for step: Step, containerSize: CGSize) -> CGSize {
        let height = containerSize.height * cardHeightToContainerHeightRatio(for: step)
        let width = height / cardHeightWidthRatio
        let maxWidth = containerSize.width - cardFrameMinHorizontalPadding(at: step)
        return width > maxWidth ?
            .init(width: maxWidth, height: maxWidth * cardHeightWidthRatio) :
            .init(width: width, height: height)
    }
}
