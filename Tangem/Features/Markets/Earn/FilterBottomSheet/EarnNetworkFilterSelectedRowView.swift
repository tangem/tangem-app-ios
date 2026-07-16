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

    @ScaledMetric private var verticalPadding: CGFloat = .unit(.x4) + .unit(.half)
    @ScaledMetric private var horizontalMinLength = CGFloat.unit(.x1)
    @ScaledMetric private var iconSide = CGFloat.unit(.x5)

    private var isSelected: Bool {
        selection.isActive(compare: data.id).wrappedValue
    }

    var body: some View {
        Button(action: { selection.isActive(compare: data.id).toggle() }) {
            HStack(spacing: 0) {
                Text(data.title)
                    .style(Font.Tangem.Body16.semibold, color: .Tangem.Text.Neutral.primary)

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
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.primaryInvertedConstant)
                    .background(Color.Tangem.Graphic.Status.accent, in: .circle)
            } else {
                Assets.circleOutline20.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.Tangem.Border.Neutral.secondary)
            }
        }
        .frame(width: iconSide, height: iconSide)
    }
}
