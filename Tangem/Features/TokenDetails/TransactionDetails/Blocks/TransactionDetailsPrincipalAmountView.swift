//
//  TransactionDetailsPrincipalAmountView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

/// The amount an operation was charged against — e.g. the fee sheet's "For sending 120.03 USDT",
/// which points at the transfer the fee was paid for. `label` carries the role, `amount` the value.
struct TransactionDetailsPrincipalAmountViewData: Equatable {
    let icon: ImageType
    let label: String
    let amount: String
    let tokenIconInfo: TokenIconInfo
}

struct TransactionDetailsPrincipalAmountView: View {
    let data: TransactionDetailsPrincipalAmountViewData

    @ScaledMetric private var iconContainerSide: CGFloat = 40
    @ScaledMetric private var iconSide: CGFloat = 20
    @ScaledMetric private var tokenBadgeSide: CGFloat = 16

    var body: some View {
        TangemRow(title: data.amount, subtitle: data.label)
            .lineOrder(.secondaryFirst)
            .verticalAlignment(.center)
            .titleAccessory { TokenIcon(tokenIconInfo: data.tokenIconInfo, size: CGSize(bothDimensions: tokenBadgeSide)) }
            .start { leadingIcon }
            .roundedBackground(with: DesignSystem.Color.bgTertiary, padding: 0, radius: 24)
    }

    private var leadingIcon: some View {
        data.icon.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(size: CGSize(bothDimensions: iconSide))
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .frame(size: CGSize(bothDimensions: iconContainerSide))
            .background(DesignSystem.Color.bgOpaquePrimary, in: Circle())
    }
}

// MARK: - Previews

#Preview("Principal amount") {
    TransactionDetailsPrincipalAmountView(data: TransactionDetailsPreviewFactory.principalAmount())
        .padding(16)
        .background(DesignSystem.Color.bgSecondary)
}
