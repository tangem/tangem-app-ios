//
//  DemandSurveyAnswerChip.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

// [REDACTED_TODO_COMMENT]
struct DemandSurveyAnswerChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @ScaledMetric private var padding: CGFloat = Layout.padding
    @ScaledMetric private var textPadding: CGFloat = Layout.textPadding

    var body: some View {
        SwiftUI.Button(action: action) {
            Text(title)
                .style(DesignSystem.Font.subheadingMediumToken, color: textColor)
                .padding(.horizontal, textPadding)
                .padding(padding)
                .frame(minWidth: Layout.minWidth)
                .tangemMaterialSurface(in: Capsule(), isVisible: isSelected, prefersInset: true)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var textColor: Color {
        isSelected ? DesignSystem.Color.textPrimary : DesignSystem.Color.textSecondary
    }
}

// MARK: - Layout

private extension DemandSurveyAnswerChip {
    enum Layout {
        static let padding: CGFloat = 8
        static let textPadding: CGFloat = 4
        static let minWidth: CGFloat = 56
    }
}

// MARK: - Previews

#Preview {
    HStack {
        DemandSurveyAnswerChip(title: "Buy crypto", isSelected: true, action: {})
        DemandSurveyAnswerChip(title: "Sell crypto", isSelected: false, action: {})
    }
    .padding(16)
}
