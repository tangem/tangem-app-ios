//
//  OnboardingBottomFadeBackground.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

/// Bottom-anchored gradient that fades scroll content out behind a sticky action bar.
struct OnboardingBottomFadeBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                DesignSystem.Color.bgPrimary.opacity(0),
                DesignSystem.Color.bgPrimary,
                DesignSystem.Color.bgPrimary,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview {
    OnboardingBottomFadeBackground()
}
