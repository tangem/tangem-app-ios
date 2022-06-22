//
//  OnboardingStepIconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingStepIconView: View {
    
    enum State {
        case passed, current, future
        
        var checkmarkVisible: Bool {
            switch self {
            case .passed: return true
            default: return false
            }
        }
        
        var iconColor: Color {
            switch self {
            case .passed, .current: return .white
            case .future: return .tangemGrayDark
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .passed, .current: return .tangemGreen
            case .future: return .tangemGrayLight4
            }
        }
    }
    
    var image: Image
    var state: State
    
    var imageFont: Font = .system(size: 25, weight: .bold, design: .default)
    var circleSize: CGSize = .init(width: 50, height: 50)
    var checkmarkSize: CGSize = .init(width: 17, height: 17)
    
    private var smallCircleSize: CGSize {
        .init(width: circleSize.width - 4, height: circleSize.height - 4)
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .frame(size: circleSize)
                .foregroundColor(state.backgroundColor)
                .animation(.easeIn)
            Circle()
                .frame(size: state == .passed ? circleSize : .zero)
                .foregroundColor(.tangemGrayDark6)
                .animation(.easeIn)
            Circle()
                .strokeBorder(lineWidth: 4)
                .frame(size: smallCircleSize)
                .foregroundColor(.white)
            image
                .foregroundColor(state.iconColor)
                .animation(.easeIn)
                .font(imageFont)
            CircledCheckmarkView(filled: state == .passed)
                .frame(size: checkmarkSize)
                .offset(x: circleSize.width / 2 - checkmarkSize.width / 2, y: checkmarkSize.height / 2 - circleSize.height / 2)
        }
    }
}

struct OnboardingStepIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 10) {
            OnboardingStepIconView(image: Image("onboarding.nfc"), state: .passed)
            OnboardingStepIconView(image: Image("onboarding.create.wallet"), state: .current)
            OnboardingStepIconView(image: Image("onboarding.topup"), state: .current)
            OnboardingStepIconView(image: Image("onboarding.topup"), state: .passed)
            OnboardingStepIconView(image: Image("onboarding.topup"), state: .future)
        }
        
    }
}
