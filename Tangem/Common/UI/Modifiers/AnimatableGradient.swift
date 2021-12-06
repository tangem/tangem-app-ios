//
//  AnimatableGradient.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct AnimatableGradient: AnimatableModifier {
    
    let backgroundColor: Color
    let progressColor: Color
    var gradientStop: CGFloat
    
    var animatableData: CGFloat {
        get { gradientStop }
        set { gradientStop = newValue }
    }
    
    func body(content: Content) -> some View {
        LinearGradient(gradient: Gradient(stops: [
            .init(color: progressColor, location: gradientStop),
            .init(color: backgroundColor, location: gradientStop)
        ]),
        startPoint: .leading,
        endPoint: .trailing)
    }
}
