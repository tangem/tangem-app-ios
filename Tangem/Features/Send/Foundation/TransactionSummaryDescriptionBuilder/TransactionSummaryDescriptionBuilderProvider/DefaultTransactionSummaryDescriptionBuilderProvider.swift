//
//  DefaultTransactionSummaryDescriptionBuilderProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct DefaultTransactionSummaryDescriptionBuilderProvider {
    let tokenItem: TokenItem
}

extension DefaultTransactionSummaryDescriptionBuilderProvider: TransactionSummaryDescriptionBuilderProvider {
    func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        if case .nonFungible = tokenItem.token?.metadata.kind {
            return NFTSendTransactionSummaryDescriptionBuilder()
        }

        switch tokenItem.blockchain {
        case .koinos:
            return KoinosSendTransactionSummaryDescriptionBuilder(tokenItem: tokenItem)
        case .tron where tokenItem.isToken:
            return TronSendTransactionSummaryDescriptionBuilder(tokenItem: tokenItem)
        default:
            return CommonSendTransactionSummaryDescriptionBuilder(tokenItem: tokenItem)
        }
    }

    func makeSendWithSwapTransactionSummaryDescriptionBuilder() -> SendWithSwapTransactionSummaryDescriptionBuilder {
        CommonSendWithSwapTransactionSummaryDescriptionBuilder(
            swapTransactionSummaryDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder()
        )
    }

    func makeSwapTransactionSummaryDescriptionBuilder() -> SwapTransactionSummaryDescriptionBuilder {
        CommonSwapTransactionSummaryDescriptionBuilder(
            sendTransactionSummaryDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder()
        )
    }

    func makeStakingTransactionSummaryDescriptionBuilder() -> StakingTransactionSummaryDescriptionBuilder {
        CommonStakingTransactionSummaryDescriptionBuilder(tokenItem: tokenItem)
    }
}
