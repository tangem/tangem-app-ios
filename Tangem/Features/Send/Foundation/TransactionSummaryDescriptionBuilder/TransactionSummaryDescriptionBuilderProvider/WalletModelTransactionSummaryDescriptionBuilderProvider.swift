//
//  WalletModelTransactionSummaryDescriptionBuilderProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WalletModelTransactionSummaryDescriptionBuilderProvider {
    let walletModel: any WalletModel
}

// MARK: - TransactionSummaryDescriptionBuilderProvider

extension WalletModelTransactionSummaryDescriptionBuilderProvider: TransactionSummaryDescriptionBuilderProvider {
    func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        let tokenItem = walletModel.tokenItem

        if let jointAccount = walletModel.account as? any JointAccountModel {
            return JointAccountSendTransactionSummaryDescriptionBuilder(tokenItem: tokenItem, policy: jointAccount.policy)
        }

        return DefaultTransactionSummaryDescriptionBuilderProvider(tokenItem: tokenItem).makeSendTransactionSummaryDescriptionBuilder()
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
        CommonStakingTransactionSummaryDescriptionBuilder(tokenItem: walletModel.tokenItem)
    }
}
