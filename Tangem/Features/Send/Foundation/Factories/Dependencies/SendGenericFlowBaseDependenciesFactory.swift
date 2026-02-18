//
//  SendGenericFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUI.TokenIconInfo

protocol SendGenericFlowBaseDependenciesFactory {
    var sourceToken: SendSourceToken { get }
    var baseDataBuilderFactory: SendBaseDataBuilderFactory { get }
}

extension SendGenericFlowBaseDependenciesFactory {
    var userWalletInfo: UserWalletInfo { sourceToken.userWalletInfo }
    var tokenItem: TokenItem { sourceToken.tokenItem }
    var feeTokenItem: TokenItem { sourceToken.feeTokenItem }
    var tokenIconInfo: TokenIconInfo { sourceToken.tokenIconInfo }
}

// MARK: - Common dependencies

extension SendGenericFlowBaseDependenciesFactory {
    // Services

    func makeBlockchainSDKNotificationMapper() -> BlockchainSDKNotificationMapper {
        BlockchainSDKNotificationMapper(tokenItem: tokenItem)
    }

    // TransactionSummaryDescriptionBuilders

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

    func makeSwapTransactionSummaryDescriptionBuilder() -> SwapTransactionSummaryDescriptionBuilder {
        CommonSwapTransactionSummaryDescriptionBuilder(
            sendTransactionSummaryDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder()
        )
    }

    func makeStakingTransactionSummaryDescriptionBuilder() -> StakingTransactionSummaryDescriptionBuilder {
        CommonStakingTransactionSummaryDescriptionBuilder(tokenItem: tokenItem)
    }
}
