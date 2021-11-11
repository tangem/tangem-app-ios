//
//  OnboardingProgressIndicator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ProgressIndicatorView: View {
    var index: Int
    var maxIndex: Int
    var filled: Bool
    var animDuration: TimeInterval = 0.3
    
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(.tangemGrayLight4)
            Circle()
                .foregroundColor(.tangemGrayDark6)
                .scaleEffect(filled ? 1.0 : 0.0)
                .animation(
                    .easeIn(duration: animDuration)
                        .delay(filled ?
                                Double(index) / 2 * animDuration :
                                0
//                                Double(maxIndex - index) / 2 * animDuration
                        )
                )
        }
    }
}

struct ProgressIndicatorGroupView: View {
    
    var filled: Bool
    var numberOfIndicators: Int = 3
    var animDuration: TimeInterval
    
    var body: some View {
        HStack {
            ForEach(1...numberOfIndicators) { index in
                ProgressIndicatorView(index: index,
                                      maxIndex: numberOfIndicators,
                                      filled: filled,
                                      animDuration: animDuration)
                    .frame(size: CGSize(width: 5, height: 5))
            }
        }
    }
    
}

struct ProgressIndicatorGroupView_Previews: PreviewProvider {
    
    static var previews: some View {
        ProgressIndicatorGroupView(filled: true, numberOfIndicators: 3, animDuration: 0.3)
    }
    
}
