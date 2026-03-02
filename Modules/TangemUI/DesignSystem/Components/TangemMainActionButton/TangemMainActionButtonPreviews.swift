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
    @State private var buyState: TangemMainActionButton.ButtonState = .normal
    @State private var swapState: TangemMainActionButton.ButtonState = .disabled
    @State private var sellState: TangemMainActionButton.ButtonState = .normal

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
                icon: Assets.plusMini,
                buttonState: buyState,
                action: { print("Buy tapped") }
            )

            TangemMainActionButton(
                title: "Swap",
                icon: Assets.exchangeMini,
                buttonState: swapState,
                action: { print("Swap tapped") }
            )

            TangemMainActionButton(
                title: "Sell",
                icon: Assets.dollarMini,
                buttonState: sellState,
                action: { print("Sell tapped") }
            )
        }
    }

    private var togglesSection: some View {
        VStack(spacing: 8) {
            Toggle("Buy enabled", isOn: .init(
                get: { buyState.isNormal },
                set: { buyState = $0 ? .normal : .disabled }
            ))

            Toggle("Swap enabled", isOn: .init(
                get: { swapState.isNormal },
                set: { swapState = $0 ? .normal : .disabled }
            ))

            Toggle("Sell enabled", isOn: .init(
                get: { sellState.isNormal },
                set: { sellState = $0 ? .normal : .disabled }
            ))
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
