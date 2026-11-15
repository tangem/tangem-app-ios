//
//  EarnProductBenefitsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct EarnProductBenefitsView: View {
    let benefits: [EarnProductDetails.Benefit]

    @ScaledMetric private var iconSlotSide: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            // [REDACTED_TODO_COMMENT]
            EarnProductSectionTitle(title: "Benefits")

            VStack(alignment: .leading, spacing: 16) {
                ForEach(benefits, id: \.self) { benefit in
                    point(benefit)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }

    private func point(_ benefit: EarnProductDetails.Benefit) -> some View {
        HStack(alignment: .top, spacing: 12) {
            benefit.icon.image
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSlotSide, height: iconSlotSide)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .accessibilityHidden(true)

            Text(text(for: benefit))
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private func text(for benefit: EarnProductDetails.Benefit) -> AttributedString {
        var description = AttributedString(" " + benefit.description)
        description.foregroundColor = DesignSystem.Color.textSecondary

        return AttributedString(benefit.title) + description
    }
}

// MARK: - Previews

#Preview {
    EarnProductBenefitsView(benefits: EarnProductDetails.preview.benefits)
        .background(DesignSystem.Color.bgPrimary)
}
