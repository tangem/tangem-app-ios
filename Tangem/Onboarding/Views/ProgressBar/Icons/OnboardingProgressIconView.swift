//
//  OnboardingProgressIconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingProgressIconView: View {
    
    var steps: [SingleCardOnboardingStep]
    var currentStep: Int
    
    private let animDuration: TimeInterval = 0.3
    
    var body: some View {
        HStack {
            ForEach(0..<steps.count) { stepIndex in
                let step = steps[stepIndex]
                let state = stepState(for: stepIndex)
                HStack {
                    if let icon = step.icon {
                        let isFilled: Bool = state == .current || state == .passed
                        if stepIndex > 0 {
                            ProgressIndicatorGroupView(filled: isFilled, animDuration: animDuration)
                        }
                        OnboardingStepIconView(image: icon,
                                               state: state,
                                               imageFont: step.iconFont,
                                               circleSize: .init(width: 50, height: 50))
                    } else {
                        EmptyView()
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

struct OnboardingProgressIconView_Previews: PreviewProvider {
    
    static var previews: some View {
        VStack {
            OnboardingProgressIconView(steps: [.createWallet, .topup], currentStep: 1)
            OnboardingProgressIconView(steps: [.createWallet], currentStep: 0)
            OnboardingProgressIconView(steps: [.topup], currentStep: 0)
        }
        
    }
    
}
