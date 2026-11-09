//
//  EarnCalculatorInputRow.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnCalculatorInputRow: View {
    let input: EarnCalculatorViewState.Input
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: Constants.horizontalSpacing) {
            VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                Text(input.title)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)

                Text(styledValue)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            HStack(spacing: Constants.buttonsSpacing) {
                stepButton(
                    icon: DesignSystem.Icons.SignMinus.regular20,
                    accessibilityLabel: "Decrease \(input.title)",
                    isEnabled: input.canDecrease,
                    identifier: input.field.decreaseButtonIdentifier,
                    action: onDecrease
                )

                stepButton(
                    icon: DesignSystem.Icons.SignPlus.regular20,
                    accessibilityLabel: "Increase \(input.title)",
                    isEnabled: input.canIncrease,
                    identifier: input.field.increaseButtonIdentifier,
                    action: onIncrease
                )
            }
        }
    }
}

// MARK: - Subviews

private extension EarnCalculatorInputRow {
    var styledValue: AttributedString {
        var value = AttributedString(input.value)

        if !input.currencySymbol.isEmpty, let range = value.range(of: input.currencySymbol) {
            value[range].foregroundColor = DesignSystem.Color.textSecondary
        }

        return value
    }

    // [REDACTED_TODO_COMMENT]
    func stepButton(
        icon: ImageType,
        accessibilityLabel: String,
        isEnabled: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        TangemUI.Button(icon: icon, accessibilityLabel: accessibilityLabel, action: action)
            .styleType(.secondary(.default))
            .size(.x8)
            .disabled(!isEnabled)
            .accessibilityIdentifier(identifier)
    }
}

// MARK: - Constants

private extension EarnCalculatorInputRow {
    enum Constants {
        static let horizontalSpacing: CGFloat = 10
        static let verticalSpacing: CGFloat = 2
        static let buttonsSpacing: CGFloat = 8
    }
}
