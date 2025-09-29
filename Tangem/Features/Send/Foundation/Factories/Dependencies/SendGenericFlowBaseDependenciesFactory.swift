//
//  SendGenericFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

protocol SendGenericFlowBaseDependenciesFactory {
    var tokenItem: TokenItem { get }
    var feeTokenItem: TokenItem { get }
    var tokenIconInfo: TokenIconInfo { get }
    var userWalletInfo: SendWalletInfo { get }

    var walletModelBalancesProvider: WalletModelBalancesProvider { get }
    var walletModelDependenciesProvider: WalletModelDependenciesProvider { get }
    var transactionDispatcherFactory: TransactionDispatcherFactory { get }
    var baseDataBuilderFactory: SendBaseDataBuilderFactory { get }
}

// MARK: - Common dependencies

extension SendGenericFlowBaseDependenciesFactory {
    func isFeeApproximate() -> Bool {
        tokenItem.blockchain.isFeeApproximate(for: tokenItem.amountType)
    }

    func possibleToConvertToFiat() -> Bool {
        walletModelBalancesProvider.fiatAvailableBalanceProvider.balanceType.value != .none
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
            return NFTSendTransactionSummaryDescriptionBuilder(feeTokenItem: feeTokenItem)
        }

        switch tokenItem.blockchain {
        case .koinos:
            return KoinosSendTransactionSummaryDescriptionBuilder(
                tokenItem: tokenItem,
                feeTokenItem: feeTokenItem
            )
        case .tron where tokenItem.isToken:
            return TronSendTransactionSummaryDescriptionBuilder(
                tokenItem: tokenItem,
                feeTokenItem: feeTokenItem
            )
        default:
            return CommonSendTransactionSummaryDescriptionBuilder(
                tokenItem: tokenItem,
                feeTokenItem: feeTokenItem
            )
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
