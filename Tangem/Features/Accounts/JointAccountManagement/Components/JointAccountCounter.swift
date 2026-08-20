//
//  JointAccountCounter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

/// Stepper for the numbers of the joint account composition, bounded by the range it is given:
/// each button turns off once the value reaches the range's edge.
struct JointAccountCounter: View {
    @Binding var value: Int

    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 12) {
            stepButton(
                icon: DesignSystem.Icons.SignMinus.regular16,
                accessibilityLabel: "Decrease",
                isEnabled: value > range.lowerBound
            ) {
                value -= 1
            }

            Text(value.description)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)

            stepButton(
                icon: DesignSystem.Icons.SignPlus.regular16,
                accessibilityLabel: "Increase",
                isEnabled: value < range.upperBound
            ) {
                value += 1
            }
        }
    }

    private func stepButton(icon: ImageType, accessibilityLabel: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        TangemUI.Button(icon: icon, accessibilityLabel: accessibilityLabel, action: action)
            .styleType(.secondary)
            .size(.x7)
            .disabled(!isEnabled)
    }
}
