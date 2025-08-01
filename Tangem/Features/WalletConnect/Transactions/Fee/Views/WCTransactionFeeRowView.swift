//
//  WCTransactionFeeRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import BlockchainSdk
import TangemFoundation
import TangemLocalization

struct WCTransactionFeeRowView: View {
    let fee: Fee
    let feeOption: FeeOption
    let blockchain: Blockchain
    let feeTokenItem: TokenItem
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Assets.Glyphs.feeNew.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Colors.Icon.accent)
                .padding(.trailing, 8)
            Text(Localization.commonNetworkFeeTitle)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
            Text("~ " + formatFeeAmount(fee.amount.value))
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
            Assets.Glyphs.selectIcon.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 18, height: 24)
                .foregroundStyle(Colors.Icon.informative)
        }
        .onTapGesture(perform: onTap)
    }

    private func formatFeeAmount(_ amount: Decimal) -> String {
        let balanceFormatter = BalanceFormatter()
        let balanceConverter = BalanceConverter()

        if let currencyId = feeTokenItem.currencyId,
           let fiatAmount = balanceConverter.convertToFiat(amount, currencyId: currencyId) {
            let formattingOptions = BalanceFormattingOptions(
                minFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.minFractionDigits,
                maxFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.maxFractionDigits,
                formatEpsilonAsLowestRepresentableValue: true,
                roundingType: BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType
            )
            return balanceFormatter.formatFiatBalance(fiatAmount, formattingOptions: formattingOptions)
        }

        let feeString = balanceFormatter.formatCryptoBalance(
            amount,
            currencyCode: blockchain.currencySymbol,
            formattingOptions: .defaultCryptoFeeFormattingOptions
        )
        return feeString
    }
}
