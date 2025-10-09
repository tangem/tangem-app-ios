//
//  ExpandableItemTransitions.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

extension AnyTransition {
    static let collapsedViewTransition = AnyTransition.asymmetric(
        insertion: .opacity
            .combined(with: .offset(y: -20))
            .animation(.linear(duration: 0.7)),
        removal: .opacity
            .animation(.linear(duration: 0.2))
            .combined(with: .move(edge: .top))
    )

    static let expandedViewTransition = AnyTransition.asymmetric(
        insertion: .opacity.animation(.easeOut(duration: 1)).combined(with: .offset(y: 40)),
        removal: .offset(y: 40).combined(with: .opacity).animation(.linear(duration: 0.3))
    )
}
