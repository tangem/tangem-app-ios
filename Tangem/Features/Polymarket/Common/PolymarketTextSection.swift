//
//  PolymarketTextSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PolymarketTextSection: View {
    let title: String
    let text: String
    let isSeparated: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            Text(title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Text(text)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Constants.topPadding)
        .padding(.bottom, Constants.spacing)
        .overlay(alignment: .top) {
            if isSeparated {
                Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)
            }
        }
        .padding(.top, isSeparated ? Constants.spacing : 0)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Constants

private extension PolymarketTextSection {
    enum Constants {
        static let spacing: CGFloat = 12
        static let topPadding: CGFloat = 24
    }
}
