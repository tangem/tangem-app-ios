//
//  ForYouView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemLocalization

struct ForYouView: View {
    let onBackButtonAction: () -> Void

    private var backgroundColor: Color {
        FeatureProvider.isAvailable(.redesign) ? .Tangem.Surface.level2 : Colors.Background.primary
    }

    var body: some View {
        ZStack(alignment: .top) {
            backgroundColor
                .ignoresSafeArea()

            navigationBar
                .background {
                    MarketsNavigationBarBackgroundView(
                        backdropViewColor: backgroundColor,
                        overlayContentHidingProgress: 1,
                        isNavigationBarBackgroundBackdropViewHidden: false,
                        isListContentObscured: false
                    )
                }
                .infinityFrame(axis: .vertical, alignment: .top)
        }
        .ignoresSafeArea(.container, edges: .top)
    }

    private var navigationBar: some View {
        ZStack {
            Text(Localization.forYouTitle)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)

            HStack {
                // Liquid Glass back button on iOS 26 (system-label / circle fallbacks otherwise).
                NavigationBarButton.back(action: onBackButtonAction)
                    .redesigned()

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 64, alignment: .bottom)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ForYouView(onBackButtonAction: {})
    }
}
