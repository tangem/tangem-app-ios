//
//  TransactionSummaryDescriptionBuilderProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol TransactionSummaryDescriptionBuilderProvider {
    func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder
    func makeSendWithSwapTransactionSummaryDescriptionBuilder() -> SendWithSwapTransactionSummaryDescriptionBuilder
    func makeSwapTransactionSummaryDescriptionBuilder() -> SwapTransactionSummaryDescriptionBuilder
    func makeStakingTransactionSummaryDescriptionBuilder() -> StakingTransactionSummaryDescriptionBuilder
}
