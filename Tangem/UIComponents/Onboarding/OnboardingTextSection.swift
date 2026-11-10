//
//  OnboardingTextSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct OnboardingTextSection: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            Text(title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Text(text)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Constants

private extension OnboardingTextSection {
    enum Constants {
        static let spacing: CGFloat = 12
    }
}
