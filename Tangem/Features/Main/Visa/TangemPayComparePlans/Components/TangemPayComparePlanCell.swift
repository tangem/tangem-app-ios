//
//  TangemPayComparePlanCell.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPayComparePlanCell: View {
    let value: String

    var body: some View {
        Text(value)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)
            .frame(width: Constants.width, height: Constants.height, alignment: .topLeading)
            .background(DesignSystem.Color.bgTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private extension TangemPayComparePlanCell {
    enum Constants {
        static let width: CGFloat = 332
        static let height: CGFloat = 112
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack(spacing: 8) {
        TangemPayComparePlanCell(value: "$10,000")
        TangemPayComparePlanCell(value: "Platinum")
    }
    .padding()
}
#endif // DEBUG
