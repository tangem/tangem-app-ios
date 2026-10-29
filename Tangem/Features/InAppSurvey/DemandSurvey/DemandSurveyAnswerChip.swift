//
//  DemandSurveyAnswerChip.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct DemandSurveyAnswerChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SwiftUI.Button(action: action) {
            Text(title)
                .style(DesignSystem.Font.subheadingMediumToken, color: textColor)
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.vertical, Layout.verticalPadding)
                .background(Capsule().fill(backgroundColor))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var textColor: Color {
        isSelected ? DesignSystem.Color.textInversePrimary : DesignSystem.Color.textPrimary
    }

    private var backgroundColor: Color {
        isSelected ? DesignSystem.Color.bgInverse : DesignSystem.Color.bgTransparentSecondary
    }
}

// MARK: - Layout

private extension DemandSurveyAnswerChip {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 10
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
