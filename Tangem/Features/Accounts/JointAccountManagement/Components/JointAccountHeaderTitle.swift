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

struct JointAccountHeaderTitle: View {
    private let title: AttributedString
    private let subtitle: AttributedString

    init(title: String, subtitle: String) {
        self.init(title: AttributedString(title), subtitle: AttributedString(subtitle))
    }

    init(title: AttributedString, subtitle: AttributedString) {
        self.title = title
        self.subtitle = subtitle
    }

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
