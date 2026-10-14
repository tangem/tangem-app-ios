//
//  View+PolymarketStateTransition.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

public extension Animation {
    static let polymarketStateChange: Animation = .curve(.easeInOutRefined, duration: 0.3)
}

public extension AnyTransition {
    static let polymarketState: AnyTransition = .opacity.animation(.polymarketStateChange)
}

public extension View {
    func polymarketStateTransition(_ state: some Hashable, alignment: Alignment = .top) -> some View {
        ZStack(alignment: alignment) {
            id(state)
                .transition(.polymarketState)
        }
        .animation(.polymarketStateChange, value: state)
    }
}
