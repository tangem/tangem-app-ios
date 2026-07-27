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

    @ScaledMetric private var verticalPadding: CGFloat = 18
    @ScaledMetric private var horizontalMinLength: CGFloat = 4
    @ScaledMetric private var iconSide: CGFloat = 20

    private var isSelected: Bool {
        selection.isActive(compare: data.id).wrappedValue
    }

    var body: some View {
        SwiftUI.Button(action: { selection.isActive(compare: data.id).toggle() }) {
            HStack(spacing: 0) {
                Text(data.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Spacer(minLength: horizontalMinLength)

                icon
            }
            .padding(.vertical, verticalPadding)
        }
    }
}

// MARK: - Subviews

private extension EarnNetworkFilterSelectedRowView {
    var icon: some View {
        Group {
            if isSelected {
                Assets.checkmark20.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DesignSystem.Color.iconStaticDark)
                    .background(DesignSystem.Color.iconAccentBlue, in: .circle)
            } else {
                Assets.circleOutline20.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DesignSystem.Color.borderTertiary)
            }
        }
        .frame(width: iconSide, height: iconSide)
    }
}
