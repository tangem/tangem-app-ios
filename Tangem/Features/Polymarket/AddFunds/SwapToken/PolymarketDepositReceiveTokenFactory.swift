//
//  PolymarketDepositReceiveTokenFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemExpress
import TangemPolymarket

struct PolymarketDepositReceiveTokenFactory {
    let userWalletInfo: UserWalletInfo
    let accountModel: any PolymarketAccountModel
    let fundingTarget: PolymarketAddFundsInteractor.FundingTarget

    func makeReceiveToken() -> SendSwapableToken {
        let tokenItem = PolymarketUtilities.usdcTokenItem

        let balanceProvider = accountModel.collateralTokenBalanceProvider

        let sourceToken = CommonSendSourceToken(
            userWalletInfo: userWalletInfo,
            id: WalletModelId(tokenItem: tokenItem),
            header: TokenHeaderProvider(userWalletName: userWalletInfo.name, account: accountModel).makeHeader(),
            feeTokenItem: tokenItem,
            isCustom: false,
            defaultAddressString: fundingTarget.fundingAddress,
            availableBalanceProvider: balanceProvider,
            fiatAvailableBalanceProvider: accountModel.fiatTotalTokenBalanceProvider,
            allowanceService: nil,
            withdrawalNotificationProvider: nil,
            scaledUIAmountMultiplierResolver: nil,
            emailDataCollectorBuilder: PolymarketDepositEmailDataCollectorBuilder(),
            transactionDispatcherProvider: PolymarketDepositTransactionDispatcherProvider(),
            accountModelAnalyticsProvider: nil,
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config),
            confirmTransactionPolicy: CommonConfirmTransactionPolicy(userWalletInfo: userWalletInfo),
            isTangemPayAccount: false,
            tokenItem: tokenItem,
            fiatItem: makeFiatItem(),
            address: fundingTarget.fundingAddress,
            extraId: nil,
            transactionHistoryEnricherFactory: { nil }
        )

        let feeProvidersManagerProvider = PolymarketDepositTokenFeeProvidersManagerProvider(
            feeTokenItem: tokenItem,
            feeTokenItemBalanceProvider: balanceProvider
        )

        return CommonSendSwapableToken(
            sourceToken: sourceToken,
            isExemptFee: true,
            swapAvailabilityProvider: PolymarketDepositSwapAvailabilityProvider(),
            sendingRestrictionsProvider: PolymarketDepositSendingRestrictionsProvider(),
            receivingRestrictionsProvider: PolymarketDepositReceivingRestrictionsProvider(
                userWalletInfo: userWalletInfo,
                minimumDepositUSD: fundingTarget.asset.minimumDepositUSD,
                tokenItem: tokenItem
            ),
            tokenFeeProvidersManagerProvider: feeProvidersManagerProvider,
            tokenFeeProvidersManager: feeProvidersManagerProvider.makeTokenFeeProvidersManager(),
            transactionValidator: PolymarketDepositTransactionValidator(),
            transactionCreator: PolymarketDepositTransactionCreator(),
            sendYieldModuleHelper: nil,
            balanceProvider: CommonExpressBalanceProvider(
                availableBalanceProvider: balanceProvider,
                feeBalanceProvider: balanceProvider
            ),
            analyticsLogger: CommonExpressAnalyticsLogger(tokenItem: tokenItem),
            providerTransactionValidator: PolymarketDepositExpressProviderTransactionValidator(),
            operationType: .swap,
            supportedProvidersFilter: .swap,
            presentation: makePresentation(tokenItem: tokenItem)
        )
    }
}

// MARK: - Private implementation

private extension PolymarketDepositReceiveTokenFactory {
    func makePresentation(tokenItem: TokenItem) -> SendReceiveTokenPresentation {
        SendReceiveTokenPresentation(
            currencySymbol: tokenItem.currencySymbol,
            icon: Assets.Polymarket.accountAvatar
        )
    }

    func makeFiatItem() -> FiatItem {
        FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )
    }
}
