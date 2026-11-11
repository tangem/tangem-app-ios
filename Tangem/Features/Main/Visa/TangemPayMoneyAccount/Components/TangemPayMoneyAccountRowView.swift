//
//  TangemPayMoneyAccountRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemPay
import TangemUI
import TangemUIUtils

struct TangemPayMoneyAccountRowView: View {
    let state: TangemPayMoneyAccountRowState
    let onTap: () -> Void

    @ScaledMetric private var cachedIconSize: CGFloat = 16
    @ScaledMetric private var cachedIndicatorSpacing: CGFloat = 6
    @ScaledMetric private var scaleFactor: CGFloat = 1

    var body: some View {
        row
            .padding(12)
            .background(
                DesignSystem.Color.bgSecondary,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
    }

    @ViewBuilder
    private var row: some View {
        if case .active(let balance, let isCached) = state {
            Row(title: Localization.moneyAccountMainName, subtitle: subtitle)
                .valueAccessory { balanceView(balance, isCached: isCached) }
                .subvalueAccessory { currencyText }
                .start { avatar }
                .includeInnerPadding(false)
                .onTap(action: onTap)
        } else {
            Row(title: Localization.moneyAccountMainName, subtitle: subtitle)
                .start { avatar }
                .includeInnerPadding(false)
                .onTap(action: onTap)
        }
    }

    private var avatar: some View {
        Assets.Visa.accountMoneyAvatar.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
    }

    private func balanceView(_ balance: FormattedTokenBalanceType, isCached: Bool) -> some View {
        HStack(spacing: cachedIndicatorSpacing) {
            if isCached || balance.isFailure {
                cachedCloudIcon
            }

            LoadableBalanceView(
                state: LoadableBalanceViewStateBuilder().build(type: balance),
                style: LoadableBalanceView.Style(
                    font: TangemRowConstants.Style.Title.font,
                    textColor: DesignSystem.Color.textPrimary
                ),
                loader: LoadableBalanceView.LoaderStyle(
                    size: CGSize(width: 40, height: 12) * scaleFactor,
                    cornerRadiusStyle: .capsule
                )
            )
        }
    }

    private var currencyText: some View {
        SensitiveText(TangemPayUtilities.fiatItem.currencyCode)
            .style(TangemRowConstants.Style.Subtitle.font, color: TangemRowConstants.Style.Subtitle.color)
    }

    private var cachedCloudIcon: some View {
        Assets.failedCloud.image
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .frame(width: cachedIconSize, height: cachedIconSize)
    }

    private var subtitle: String {
        switch state {
        case .activating:
            Localization.moneyAccountMainStatusActivating
        case .awaitingDeposit:
            Localization.moneyAccountMainStatusAwaitingDeposit
        case .failed:
            Localization.moneyAccountMainStatusFailed
        case .active:
            Localization.moneyAccountMainStatusActiveV2
        }
    }
}

// MARK: - Previews

#Preview {
    TangemPayMoneyAccountRowView(state: .awaitingDeposit, onTap: {})
        .padding(.horizontal, 12)
}
