//
//  OnboardingStepIconView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingStepIconView: View {
    
    var imageName: String
    var filled: Bool
    
    private let circleSize: CGSize = .init(width: 50, height: 50)
    private var smallCircleSize: CGSize {
        .init(width: circleSize.width - 4, height: circleSize.height - 4)
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .frame(size: circleSize)
                .foregroundColor(.tangemTapGreen)
                .animation(.easeIn)
            Circle()
                .frame(size: filled ? circleSize : .zero)
                .foregroundColor(.tangemTapGrayDark6)
                .animation(.easeIn)
            Circle()
                .strokeBorder(lineWidth: 4)
                .frame(size: smallCircleSize)
                .foregroundColor(.white)
            Image(systemName: imageName)
                .foregroundColor(.white)
                .font(.system(size: 25, weight: .bold))
            CircledCheckmarkView(filled: filled)
                .frame(size: CGSize(width: 20, height: 20))
                .offset(x: circleSize.width / 3.5, y: -smallCircleSize.height / 3)
        }
    }
}

struct OnboardingStepIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OnboardingStepIconView(imageName: "wave.3.right", filled: true)
            Spacer()
                .frame(width: 1, height: 100, alignment: .center)
            OnboardingStepIconView(imageName: "key", filled: false)
        }
        
    }
}
