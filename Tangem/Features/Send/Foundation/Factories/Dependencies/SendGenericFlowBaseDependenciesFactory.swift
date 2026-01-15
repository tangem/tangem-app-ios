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
    var feeTokenItem: TokenItem { get }
    var tokenIconInfo: TokenIconInfo { get }
    var userWalletInfo: UserWalletInfo { get }

    var tokenHeaderProvider: SendGenericTokenHeaderProvider { get }
    var tokenFeeManager: TokenFeeManager { get }
    var availableBalanceProvider: TokenBalanceProvider { get }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { get }

    var walletModelDependenciesProvider: WalletModelDependenciesProvider { get }
    var transactionDispatcherFactory: TransactionDispatcherFactory { get }
    var baseDataBuilderFactory: SendBaseDataBuilderFactory { get }

    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { get }
}

// MARK: - Common dependencies

extension SendGenericFlowBaseDependenciesFactory {
    func makeSourceToken() -> SendSourceToken {
        SendSourceToken(
            header: tokenHeaderProvider.makeSendTokenHeader(),
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            tokenIconInfo: tokenIconInfo,
            fiatItem: makeFiatItem(),
            possibleToConvertToFiat: possibleToConvertToFiat(),
            tokenFeeManager: tokenFeeManager,
            availableBalanceProvider: availableBalanceProvider,
            fiatAvailableBalanceProvider: fiatAvailableBalanceProvider,
            transactionValidator: walletModelDependenciesProvider.transactionValidator,
            transactionCreator: walletModelDependenciesProvider.transactionCreator,
            transactionDispatcher: transactionDispatcherFactory.makeSendDispatcher(),
            accountModelAnalyticsProvider: accountModelAnalyticsProvider
        )
    }

    func isFeeApproximate() -> Bool {
        tokenItem.blockchain.isFeeApproximate(for: tokenItem.amountType)
    }

    func possibleToConvertToFiat() -> Bool {
        fiatAvailableBalanceProvider.balanceType.value != .none
    }

    func makeFiatItem() -> FiatItem {
        FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )
    }

    // Services

    func makeBlockchainSDKNotificationMapper() -> BlockchainSDKNotificationMapper {
        BlockchainSDKNotificationMapper(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
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
