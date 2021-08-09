//
//  OnboardingProgressIndicator.swift
//  Tangem Tap
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
                .foregroundColor(.tangemTapGrayLight4)
            Circle()
                .foregroundColor(.tangemTapGrayDark6)
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
