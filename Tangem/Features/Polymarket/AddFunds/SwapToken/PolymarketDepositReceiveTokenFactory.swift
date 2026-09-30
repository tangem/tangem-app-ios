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
    let depositTarget: PolymarketAccountFundsInteractor.DepositTarget

    func makeReceiveToken() -> SendSwapableToken {
        let tokenItem = depositTarget.tokenItem
        let balanceProvider = accountModel.collateralTokenBalanceProvider

        let sourceToken = CommonSendSourceToken(
            userWalletInfo: userWalletInfo,
            id: WalletModelId(tokenItem: tokenItem),
            header: TokenHeaderProvider(userWalletName: userWalletInfo.name, account: accountModel).makeHeader(),
            feeTokenItem: tokenItem,
            isCustom: false,
            defaultAddressString: depositTarget.fundingAddress,
            availableBalanceProvider: balanceProvider,
            fiatAvailableBalanceProvider: accountModel.fiatAvailableBalanceProvider,
            allowanceService: nil,
            withdrawalNotificationProvider: nil,
            scaledUIAmountMultiplierResolver: nil,
            emailDataCollectorBuilder: PolymarketAccountEmailDataCollectorBuilder(),
            transactionDispatcherProvider: PolymarketDepositTransactionDispatcherProvider(),
            accountModelAnalyticsProvider: nil,
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config),
            confirmTransactionPolicy: CommonConfirmTransactionPolicy(userWalletInfo: userWalletInfo),
            isTangemPayAccount: false,
            jointAccountPolicy: nil,
            tokenItem: tokenItem,
            fiatItem: makeFiatItem(),
            address: depositTarget.fundingAddress,
            extraId: nil,
            transactionHistoryEnricherFactory: { nil }
        )

        let feeProvidersManagerProvider = PolymarketAccountTokenFeeProvidersManagerProvider(
            feeTokenItem: tokenItem,
            feeTokenItemBalanceProvider: balanceProvider
        )

        return CommonSendSwapableToken(
            sourceToken: sourceToken,
            isExemptFee: true,
            swapAvailabilityProvider: PolymarketAccountSwapAvailabilityProvider(),
            sendingRestrictionsProvider: PolymarketAccountSendingRestrictionsProvider(),
            receivingRestrictionsProvider: PolymarketDepositReceivingRestrictionsProvider(
                userWalletInfo: userWalletInfo,
                minCheckoutUSD: depositTarget.minCheckoutUSD,
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
            providerTransactionValidator: PolymarketAccountExpressProviderTransactionValidator(),
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
            icon: Assets.Polymarket.accountAvatar,
            balanceDenomination: .token
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
