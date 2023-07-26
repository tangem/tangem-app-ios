//
//  CardsInfoPagerContentAnimationModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// This animator is responsible for applying visual effects (such as vertical offset and opacity changes)
/// for the `content` part of the pager view.
struct CardsInfoPagerContentAnimationModifier: AnimatableModifier {
    var progress: CGFloat
    let verticalOffset: CGFloat
    let hasValidIndexToSelect: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let ratio = hasValidIndexToSelect ? abs(sin(.pi * progress)) : 0.0

        content
            .opacity(1.0 - Double(ratio))
            .offset(y: verticalOffset * ratio)
    }
}
