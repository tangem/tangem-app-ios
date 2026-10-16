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
        self.title = title.mergeForegroundColor(DesignSystem.Color.textPrimary)
        self.subtitle = subtitle.mergeForegroundColor(DesignSystem.Color.textSecondary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(token: DesignSystem.Font.headingMediumToken)

            Text(subtitle)
                .font(token: DesignSystem.Font.subheadingMediumToken)
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }
}

// MARK: - Default color

private extension AttributedString {
    func mergeForegroundColor(_ color: Color) -> AttributedString {
        var container = AttributeContainer()
        container.foregroundColor = color

        var string = self
        string.mergeAttributes(container, mergePolicy: .keepCurrent)
        return string
    }
}
