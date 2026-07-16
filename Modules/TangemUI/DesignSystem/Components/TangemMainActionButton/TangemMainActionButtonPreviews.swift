//
//  TangemMainActionButtonPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemMainActionButtonShowcase: View {
    @State private var buyEnabled = true
    @State private var swapEnabled = false
    @State private var sellEnabled = true

    public init() {}

    public var body: some View {
        VStack(spacing: 32) {
            buttonsRow

            togglesSection
        }
        .padding()
    }

    private var buttonsRow: some View {
        HStack(spacing: 24) {
            TangemMainActionButton(
                title: "Buy",
                icon: Assets.DesignSystem.plus,
                action: { print("Buy tapped") },
                reasonTapWhenDisabled: { print("reason tapped") }
            )
            .disabled(!buyEnabled)

            TangemMainActionButton(
                title: "Swap",
                icon: Assets.DesignSystem.exchangeMini,
                action: { print("Swap tapped") },
                reasonTapWhenDisabled: { print("reason tapped") }
            )
            .disabled(!swapEnabled)

            TangemMainActionButton(
                title: "Sell",
                icon: Assets.DesignSystem.dollar,
                action: { print("Sell tapped") },
                reasonTapWhenDisabled: { print("reason tapped") }
            )
            .disabled(!sellEnabled)
        }
    }

    private var togglesSection: some View {
        VStack(spacing: 8) {
            Toggle("Buy enabled", isOn: $buyEnabled)

            Toggle("Swap enabled", isOn: $swapEnabled)

            Toggle("Sell enabled", isOn: $sellEnabled)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Interactive Demo") {
    TangemMainActionButtonShowcase()
}

#Preview("Dark") {
    TangemMainActionButtonShowcase()
        .preferredColorScheme(.dark)
}

#endif // DEBUG
