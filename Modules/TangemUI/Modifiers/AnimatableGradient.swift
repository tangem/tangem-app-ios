//
//  AnimatableGradient.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

public struct AnimatableGradient: AnimatableModifier {
    private let backgroundColor: Color
    private let progressColor: Color
    private var gradientStop: CGFloat

    public var animatableData: CGFloat {
        get { gradientStop }
        set { gradientStop = newValue }
    }

    public init(
        backgroundColor: Color,
        progressColor: Color,
        gradientStop: CGFloat
    ) {
        self.backgroundColor = backgroundColor
        self.progressColor = progressColor
        self.gradientStop = gradientStop
    }

    public func body(content: Content) -> some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: progressColor, location: gradientStop),
                .init(color: backgroundColor, location: gradientStop),
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
