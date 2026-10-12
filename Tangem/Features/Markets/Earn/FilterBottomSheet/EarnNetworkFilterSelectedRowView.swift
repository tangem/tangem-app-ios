//
//  EarnNetworkFilterSelectedRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct EarnNetworkFilterSelectedRowView<ID: Hashable>: View {
    let data: DefaultSelectableRowViewModel<ID>
    let selection: Binding<ID>

    @ScaledMetric private var verticalPadding: CGFloat = 16
    @ScaledMetric private var subtitleSpacing: CGFloat = 2
    @ScaledMetric private var horizontalMinLength: CGFloat = 4

    private var isSelected: Bool {
        selection.isActive(compare: data.id).wrappedValue
    }

    var body: some View {
        SwiftUI.Button(action: { selection.isActive(compare: data.id).toggle() }) {
            HStack(spacing: 0) {
                text

                Spacer(minLength: horizontalMinLength)

                icon
            }
            .padding(.vertical, verticalPadding)
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Subviews

private extension EarnNetworkFilterSelectedRowView {
    var text: some View {
        VStack(alignment: .leading, spacing: subtitleSpacing) {
            Text(data.title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            if let subtitle = data.subtitle {
                Text(subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
        }
        .multilineTextAlignment(.leading)
    }

    var icon: some View {
        TangemUI.Checkmark(checked: isSelected, action: {})
            .expandsHitArea(false)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
