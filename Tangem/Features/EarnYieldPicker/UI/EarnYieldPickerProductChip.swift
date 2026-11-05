//
//  EarnYieldPickerProductChip.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct EarnYieldPickerProductChip: View {
    let name: String
    let rate: String
    let isSelected: Bool
    let onTap: () -> Void

    @ScaledMetric private var width: CGFloat = Constants.width
    @ScaledMetric private var iconSide: CGFloat = Constants.iconSide

    var body: some View {
        SwiftUI.Button(action: onTap) {
            VStack(alignment: .leading, spacing: Constants.spacing) {
                HStack(spacing: Constants.spacing) {
                    Text(name)
                        .style(DesignSystem.Font.captionMediumToken, color: nameColor)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    if isSelected {
                        DesignSystem.Icons.Success.filled16.image
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: iconSide, height: iconSide)
                            .foregroundStyle(DesignSystem.Color.iconInverse)
                            .accessibilityHidden(true)
                    }
                }

                Text(rate)
                    .style(DesignSystem.Font.headingSmallToken, color: rateColor)
                    .lineLimit(1)
            }
            .padding(Constants.padding)
            .frame(width: width, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Colors

private extension EarnYieldPickerProductChip {
    var nameColor: Color {
        isSelected ? DesignSystem.Color.textInverseSecondary : DesignSystem.Color.textSecondary
    }

    var rateColor: Color {
        isSelected ? DesignSystem.Color.textInversePrimary : DesignSystem.Color.textPrimary
    }

    var background: Color {
        isSelected ? DesignSystem.Color.bgInverse : DesignSystem.Color.bgTransparentPrimary
    }
}

// MARK: - Constants

private extension EarnYieldPickerProductChip {
    enum Constants {
        static let width: CGFloat = 173
        static let iconSide: CGFloat = 16
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 2
        static let cornerRadius: CGFloat = 24
    }
}

// MARK: - Previews

#Preview {
    HStack(spacing: 8) {
        EarnYieldPickerProductChip(name: "Pooled staking", rate: "2% APY", isSelected: false, onTap: {})
        EarnYieldPickerProductChip(name: "Lending on Aave", rate: "3% APY", isSelected: true, onTap: {})
    }
    .padding(24)
    .background(DesignSystem.Color.bgPrimary)
}
