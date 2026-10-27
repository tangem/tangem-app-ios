//
//  CollectiblesDepositReceiveTokenFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemExpress

struct CollectiblesDepositReceiveTokenFactory {
    let userWalletInfo: UserWalletInfo
    let accountModel: any CollectiblesBalanceSource & BaseAccountModel
    let tokenItem: TokenItem
    let fundingAddress: String

    func makeReceiveToken() -> SendSwapableToken {
        let balanceProvider = accountModel.usdcTokenBalanceProvider

        let sourceToken = CommonSendSourceToken(
            userWalletInfo: userWalletInfo,
            id: WalletModelId(tokenItem: tokenItem),
            header: TokenHeaderProvider(userWalletName: userWalletInfo.name, account: accountModel).makeHeader(),
            feeTokenItem: tokenItem,
            isCustom: false,
            defaultAddressString: fundingAddress,
            availableBalanceProvider: balanceProvider,
            fiatAvailableBalanceProvider: accountModel.fiatTotalTokenBalanceProvider,
            allowanceService: nil,
            withdrawalNotificationProvider: nil,
            scaledUIAmountMultiplierResolver: nil,
            emailDataCollectorBuilder: CollectiblesAccountEmailDataCollectorBuilder(),
            transactionDispatcherProvider: CollectiblesDepositTransactionDispatcherProvider(),
            accountModelAnalyticsProvider: nil,
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config),
            confirmTransactionPolicy: CommonConfirmTransactionPolicy(userWalletInfo: userWalletInfo),
            isTangemPayAccount: false,
            jointAccountPolicy: nil,
            tokenItem: tokenItem,
            fiatItem: makeFiatItem(),
            address: fundingAddress,
            extraId: nil,
            transactionHistoryEnricherFactory: { nil }
        )

        let feeProvidersManagerProvider = CollectiblesAccountTokenFeeProvidersManagerProvider(
            feeTokenItem: tokenItem,
            feeTokenItemBalanceProvider: balanceProvider
        )

        return CommonSendSwapableToken(
            sourceToken: sourceToken,
            isExemptFee: true,
            swapAvailabilityProvider: CollectiblesAccountSwapAvailabilityProvider(),
            sendingRestrictionsProvider: CollectiblesAccountSendingRestrictionsProvider(),
            receivingRestrictionsProvider: CollectiblesDepositReceivingRestrictionsProvider(userWalletInfo: userWalletInfo),
            tokenFeeProvidersManagerProvider: feeProvidersManagerProvider,
            tokenFeeProvidersManager: feeProvidersManagerProvider.makeTokenFeeProvidersManager(),
            transactionValidator: CollectiblesDepositTransactionValidator(),
            transactionCreator: CollectiblesDepositTransactionCreator(),
            sendYieldModuleHelper: nil,
            balanceProvider: CommonExpressBalanceProvider(
                availableBalanceProvider: balanceProvider,
                feeBalanceProvider: balanceProvider
            ),
            analyticsLogger: CommonExpressAnalyticsLogger(tokenItem: tokenItem),
            providerTransactionValidator: CollectiblesAccountExpressProviderTransactionValidator(),
            operationType: .swap,
            supportedProvidersFilter: .byTypes([.dex]),
            isCustomSlippageAllowed: accountModel.resolve(using: CustomSlippageAvailabilityResolver()),
            presentation: SendReceiveTokenPresentation(
                currencySymbol: tokenItem.currencySymbol,
                icon: Assets.Accounts.starAccounts,
                balanceDenomination: .token
            )
        )
    }
}

// MARK: - Private logic

private extension CollectiblesDepositReceiveTokenFactory {
    func makeFiatItem() -> FiatItem {
        FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )
    }
}
