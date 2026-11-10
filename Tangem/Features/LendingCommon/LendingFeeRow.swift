//
//  LendingFeeRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct LendingFeeRow: View {
    let fee: LendingFee
    let canChangeFeeSpeed: Bool
    let action: () -> Void
    var retry: (() -> Void)?

    var body: some View {
        Row(title: Localization.commonNetworkFeeTitle)
            .end {
                HStack(spacing: 8) {
                    value

                    if retryAction != nil {
                        DesignSystem.Icons.ArrowRefresh.regular20.image
                            .renderingMode(.template)
                            .foregroundStyle(DesignSystem.Color.iconSecondary)
                            .accessibilityHidden(true)
                    } else if canChangeFeeSpeed {
                        DesignSystem.Icons.ChevronDoubleVertical.regular20.image
                            .renderingMode(.template)
                            .foregroundStyle(DesignSystem.Color.iconSecondary)
                            .accessibilityHidden(true)
                    }
                }
            }
            .includeInnerPadding(false)
            .onTap(action: retryAction ?? (canChangeFeeSpeed ? action : nil))
            .accessibilityHint(retryAction == nil ? "" : Localization.commonRetry)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(DesignSystem.Color.bgSecondary)
            .cornerRadiusContinuous(24)
    }

    private var retryAction: (() -> Void)? {
        fee == .unavailable ? retry : nil
    }

    @ViewBuilder
    private var value: some View {
        switch fee {
        case .loading:
            Shimmer()
                .variant(.custom(width: 64, height: 20))
        case .loaded(let symbol, let value):
            Badge(label: symbol, accessibilityLabel: nil)

            Text(value)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
        case .unavailable:
            Text(BalanceFormatter.defaultEmptyBalanceString)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }
}

// MARK: - LendingFee

enum LendingFee: Equatable {
    case loading
    case loaded(symbol: String, value: String)
    case unavailable

    init(_ tokenFee: TokenFee, formatter: FeeFormatter = CommonFeeFormatter()) {
        switch tokenFee.value {
        case .loading:
            self = .loading
        case .failure:
            self = .unavailable
        case .success(let fee):
            let components = formatter.formattedFeeComponents(
                fee: fee.amount.value,
                currencySymbol: tokenFee.tokenItem.currencySymbol,
                currencyId: tokenFee.tokenItem.currencyId,
                isFeeApproximate: tokenFee.tokenItem.isFeeApproximate,
                formattingOptions: .sendCryptoFeeFormattingOptions
            )
            self = .loaded(symbol: tokenFee.tokenItem.currencySymbol, value: components.fiatFee ?? components.cryptoFee)
        }
    }
}
