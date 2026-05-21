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
                Colors.Background.fadeStart,
                Colors.Background.fadeEnd,
                Colors.Background.fadeEnd,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    OnboardingBottomFadeBackground()
}
#endif // DEBUG
