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
                DesignSystem.Tokens.Theme.Border.secondary
                    .frame(height: DesignSystem.Tokens.BorderWidth.sm)

                infoRow(label: Localization.tangempayYourBalance, value: balanceValue)
            }
        }
        .padding(.horizontal, DesignSystem.Tokens.Spacing.s200)
        .padding(.top, DesignSystem.Tokens.Spacing.s200)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(spacing: DesignSystem.Tokens.Spacing.s150) {
            Text(label)
                .font(DesignSystem.Tokens.Font.Body.medium)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(DesignSystem.Tokens.Font.Body.medium)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.secondary)
        }
        .padding(.vertical, DesignSystem.Tokens.Spacing.s150)
    }
}
