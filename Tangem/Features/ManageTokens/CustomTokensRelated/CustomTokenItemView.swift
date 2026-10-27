//
//  CustomTokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct CustomTokenItemView: View {
    let info: CustomTokenItemViewInfo
    let removeAction: (CustomTokenItemViewInfo) -> Void

    var body: some View {
        HStack(spacing: 12) {
            TokenIcon(
                tokenIconInfo: info.iconInfo,
                size: .init(bothDimensions: 36)
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(info.name)
                        .style(Fonts.Bold.subheadline, color: DesignSystem.Color.textPrimary)

                    Text(info.symbol)
                        .style(Fonts.Regular.caption1, color: DesignSystem.Color.textSecondary)
                }

                Text(Localization.commonCustom)
                    .style(Fonts.Bold.caption1, color: DesignSystem.Color.textSecondary)
            }

            Spacer(minLength: 16)

            SwiftUI.Button {
                removeAction(info)
            } label: {
                Text(Localization.manageTokensRemove)
                    .style(Fonts.Bold.caption1, color: DesignSystem.Color.textPrimary)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(DesignSystem.Color.bgTransparentSecondary)
                    .cornerRadiusContinuous(20)
            }
        }
        .background(DesignSystem.Color.bgSecondary)
        .padding(.all, 16)
    }
}

#Preview {
    let iconInfoBuilder = TokenIconInfoBuilder()
    let tokenItem = TokenItem.token(.sushiMock, .init(.polygon(testnet: false), derivationPath: nil))
    return CustomTokenItemView(
        info: .init(
            tokenItem: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)),
            iconInfo: iconInfoBuilder.build(from: tokenItem, isCustom: true),
            name: tokenItem.name,
            symbol: tokenItem.currencySymbol
        ),
        removeAction: { _ in }
    )
}
