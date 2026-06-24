//
//  TangemPayInsufficientFundsBanner.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TangemPayInsufficientFundsBanner: View {
    let title: String
    let message: String
    let buttonTitle: String
    let buttonAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                icon

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DesignSystem.Font.subheadingMediumToken)
                        .foregroundStyle(DesignSystem.Color.textPrimary)

                    Text(message)
                        .font(DesignSystem.Font.captionMediumToken)
                        .foregroundStyle(DesignSystem.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            TangemButtonV2(
                label: AttributedString(buttonTitle),
                accessibilityLabel: buttonTitle,
                action: buttonAction
            )
            .size(.x8)
            .styleType(.secondary)
            .horizontalLayout(.infinity)
        }
        .padding(16)
        .background(
            DesignSystem.Color.bgStatusWarningSubtle,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var icon: some View {
        Assets.Visa.usdc.image
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .accessibilityHidden(true)
    }
}
