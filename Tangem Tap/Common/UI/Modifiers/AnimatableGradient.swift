//
//  AnimatableGradient.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct AnimatableGradient: AnimatableModifier {
    
    var gradientStop: CGFloat
    
    var animatableData: CGFloat {
        get { gradientStop }
        set { gradientStop = newValue }
    }
    
    func body(content: Content) -> some View {
        LinearGradient(gradient: Gradient(stops: [
            .init(color: .tangemTapGreen, location: gradientStop),
            .init(color: .tangemTapGreen2, location: gradientStop)
        ]),
        startPoint: .leading,
        endPoint: .trailing)
    }
}
