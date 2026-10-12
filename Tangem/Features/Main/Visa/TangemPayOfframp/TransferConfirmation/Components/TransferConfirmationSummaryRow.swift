//
//  TransferConfirmationSummaryRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TransferConfirmationSummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.titleToValueSpacing) {
            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            Text(value)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .frame(minHeight: Constants.valueHeight, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Constants.verticalPadding)
    }
}

// MARK: - Constants

private extension TransferConfirmationSummaryRow {
    enum Constants {
        static let titleToValueSpacing: CGFloat = 2
        static let verticalPadding: CGFloat = 16
        static let valueHeight: CGFloat = 24
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: .zero) {
        TransferConfirmationSummaryRow(title: "Account number", value: "0000000000")

        Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)

        TransferConfirmationSummaryRow(title: "Routing number", value: "0000000000")
    }
    .padding(.horizontal, 16)
    .background(DesignSystem.Color.bgSecondary)
    .cornerRadiusContinuous(24)
}
