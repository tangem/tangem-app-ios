//
//  TangemPayPopupFeeRows.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct TangemPayPopupFeeRows: View {
    let feeLabel: String
    let feeValue: String
    let balanceValue: String?

    var body: some View {
        VStack(spacing: 0) {
            infoRow(label: feeLabel, value: feeValue)

            if let balanceValue {
                DesignSystem.Color.borderSecondary
                    .frame(height: 1)

                infoRow(label: Localization.tangempayYourBalance, value: balanceValue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
        }
        .padding(.vertical, 12)
    }
}
