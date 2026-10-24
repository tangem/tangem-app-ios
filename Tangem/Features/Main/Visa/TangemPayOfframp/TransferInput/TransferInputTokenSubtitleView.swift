//
//  TransferInputTokenSubtitleView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TransferInputTokenSubtitleView: View {
    let item: TransferInputTokenItem

    var body: some View {
        text
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
    }

    @ViewBuilder
    private var text: some View {
        if item.isOfframpAvailable {
            SensitiveText(
                builder: { Localization.tangempayWithdrawBankSourceSubtitle(item.networkName, $0) },
                sensitive: item.balanceText
            )
        } else {
            Text(
                Localization.tangempayWithdrawBankSourceSubtitle(
                    item.networkName,
                    Localization.tangempayWithdrawBankOfframpUnavailable
                )
            )
        }
    }
}
