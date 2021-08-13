//
//  ProgressOnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ProgressOnboardingView: View {
    
    var steps: [OnboardingStep]
    var currentStep: Int
    
    private let animDuration: TimeInterval = 0.3
    
    var body: some View {
        HStack {
            ForEach(0..<steps.count) { stepIndex in
                let step = steps[stepIndex]
                let state = stepState(for: stepIndex)
                HStack {
                    if let icon = step.icon {
                        if stepIndex > 0 {
                            ProgressIndicatorGroupView(filled: state == .current || state == .passed, animDuration: animDuration)
                        }
                        OnboardingStepIconView(image: icon,
                                               state: state,
                                               imageFont: step.iconFont,
                                               circleSize: .init(width: 50, height: 50))
                    }
                }
            }
            
        }
    }
    
    func stepState(for index: Int) -> OnboardingStepIconView.State {
        if currentStep == index {
            return .current
        } else if currentStep < index {
            return .future
        } else {
            return .passed
        }
    }
}
