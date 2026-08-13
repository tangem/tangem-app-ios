//
//  JointAccountHeaderTitle.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

/// Leading-aligned title with an explanation under it, opening a step of the joint account creation.
struct JointAccountHeaderTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(token: DesignSystem.Font.headingMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)

            Text(subtitle)
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }
}
