//
//  NFTSendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct NFTSendTransactionSummaryDescriptionBuilder {
    private let feeTokenItem: TokenItem

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder protocol conformance

extension NFTSendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(transactionType: SendSummaryTransactionData) -> String? {
        guard case .send(_, let fee) = transactionType else {
            return nil
        }

        let feeInFiat = feeTokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(fee.amount.value, currencyId: $0) }
        let feeFormatter = BalanceFormatter()
        let feeInFiatFormatted = feeFormatter.formatFiatBalance(feeInFiat, formattingOptions: .defaultFiatFormattingOptions)

        return Localization.sendSummaryTransactionDescription(Localization.commonNft, feeInFiatFormatted)
    }
}
