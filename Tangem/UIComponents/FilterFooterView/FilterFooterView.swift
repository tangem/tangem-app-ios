//
//  FilterFooterView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemUIUtils

struct FilterFooterView: View {
    let isVisible: Bool
    let onReset: () -> Void
    let onApply: () -> Void
    var resetAccessibilityIdentifier: String?
    var applyAccessibilityIdentifier: String?

    @ScaledMetric private var padding: CGFloat = 16
    @ScaledMetric private var buttonSpacing: CGFloat = 8

    var body: some View {
        VStack(spacing: .zero) {
            if isVisible {
                VStack(spacing: buttonSpacing) {
                    TangemUI.Button(label: Localization.commonReset, accessibilityLabel: Localization.commonReset, action: onReset)
                        .size(.x12)
                        .styleType(.secondary(.default))
                        .horizontalLayout(.infinity)
                        .accessibilityIdentifier(resetAccessibilityIdentifier)

                    TangemUI.Button(label: Localization.commonApply, accessibilityLabel: Localization.commonApply, action: onApply)
                        .size(.x12)
                        .styleType(.default)
                        .horizontalLayout(.infinity)
                        .accessibilityIdentifier(applyAccessibilityIdentifier)
                }
                .padding(padding)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isVisible)
    }
}
