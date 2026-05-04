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
    private let data: DefaultSelectableRowViewModel<ID>
    private let selection: Binding<ID>

    @ScaledMetric private var verticalPadding: CGFloat
    @ScaledMetric private var horizontalMinLength: CGFloat
    @ScaledSize private var iconSize: CGSize

    private var isSelected: Bool {
        selection.isActive(compare: data.id).wrappedValue
    }

    init(data: DefaultSelectableRowViewModel<ID>, selection: Binding<ID>) {
        self.data = data
        self.selection = selection

        _verticalPadding = ScaledMetric(wrappedValue: .unit(.x3))
        _horizontalMinLength = ScaledMetric(wrappedValue: .unit(.x1))
        _iconSize = ScaledSize(wrappedValue: CGSize(bothDimensions: .unit(.x5)))
    }

    var body: some View {
        Button(action: { selection.isActive(compare: data.id).toggle() }) {
            HStack(spacing: 0) {
                Text(data.title)
                    .style(.Tangem.Body16.semibold, color: .Tangem.Text.Neutral.primary)

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
        .frame(size: iconSize)
    }
}
