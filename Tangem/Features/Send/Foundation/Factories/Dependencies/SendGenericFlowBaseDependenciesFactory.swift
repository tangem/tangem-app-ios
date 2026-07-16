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
    var tokenItem: TokenItem { get }
}

extension SendGenericFlowBaseDependenciesFactory where Self: SendFlowBaseDependenciesFactory {
    var tokenItem: TokenItem { transferableToken.tokenItem }
}

extension SendGenericFlowBaseDependenciesFactory where Self: StakingFlowDependenciesFactory {
    var tokenItem: TokenItem { stakingableToken.tokenItem }
}

// MARK: - Common dependencies

extension SendGenericFlowBaseDependenciesFactory {
    // MARK: - TransactionSummaryDescriptionBuilders

    func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        Self.makeSendTransactionSummaryDescriptionBuilder(tokenItem: tokenItem)
    }

    static func makeSendTransactionSummaryDescriptionBuilder(tokenItem: TokenItem) -> SendTransactionSummaryDescriptionBuilder {
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
            sendTransactionSummaryDescriptionBuilderFactory: Self.makeSendTransactionSummaryDescriptionBuilder(tokenItem:)
        )
    }

    func makeStakingTransactionSummaryDescriptionBuilder() -> StakingTransactionSummaryDescriptionBuilder {
        CommonStakingTransactionSummaryDescriptionBuilder(tokenItem: tokenItem)
    }

    func makeSendWithSwapTransactionSummaryDescriptionBuilder() -> SendWithSwapTransactionSummaryDescriptionBuilder {
        CommonSendWithSwapTransactionSummaryDescriptionBuilder(
            swapTransactionSummaryDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder()
        )
    }

    // MARK: - Analytics

    func makeSendAnalyticsLogger(sendType: CommonSendAnalyticsLogger.SendType, coordinatorSource: SendCoordinator.Source = .main) -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(sendType: sendType, coordinatorSource: coordinatorSource)
    }

    func makeSwapAnalyticsLogger() -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(sendType: .swap, coordinatorSource: .main)
    }

    func makeSendWithSwapAnalyticsLogger(
        sendType: CommonSendAnalyticsLogger.SendType,
        coordinatorSource: SendCoordinator.Source = .main
    ) -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(sendType: sendType, coordinatorSource: coordinatorSource)
    }
}
