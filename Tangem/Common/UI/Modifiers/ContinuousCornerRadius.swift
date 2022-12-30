//
//  ContinuousCornerRadius.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ContinuousCornerRadius: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

extension View {
    @ViewBuilder
    func cornerRadiusContinuous(_ radius: CGFloat) -> some View {
        self.modifier(
            ContinuousCornerRadius(radius: radius)
        )
    }
}
