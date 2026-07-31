//
//  LoadingShimmerAppearance.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// Which shimmer treatment a loading placeholder uses. `skeleton` keeps the legacy look for existing
/// consumers; DS3 surfaces opt into `tangemShimmer` per call site rather than flipping the default.
public enum LoadingShimmerAppearance {
    case skeleton
    case tangemShimmer
}

public extension View {
    @ViewBuilder
    func loadingShimmer(_ appearance: LoadingShimmerAppearance) -> some View {
        switch appearance {
        case .skeleton:
            shimmer()

        case .tangemShimmer:
            tangemShimmer()
        }
    }
}
