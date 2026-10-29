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
            fiatAvailableBalanceProvider: PolymarketUSDBalanceProvider(collateralBalanceProvider: balanceProvider),
            allowanceService: nil,
            withdrawalNotificationProvider: nil,
            scaledUIAmountMultiplierResolver: nil,
            emailDataCollectorBuilder: PolymarketAccountEmailDataCollectorBuilder(),
            transactionDispatcherProvider: PolymarketDepositTransactionDispatcherProvider(),
            transactionSummaryDescriptionBuilderProvider: DefaultTransactionSummaryDescriptionBuilderProvider(tokenItem: tokenItem),
            blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper(tokenItem: tokenItem),
            accountModelAnalyticsProvider: nil,
            receivingRestrictionsProvider: PolymarketDepositReceivingRestrictionsProvider(
                userWalletInfo: userWalletInfo,
                minCheckoutUSD: depositTarget.minCheckoutUSD,
                tokenItem: tokenItem
            ),
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
            isCustomSlippageAllowed: accountModel.resolve(using: CustomSlippageAvailabilityResolver()),
            presentation: makePresentation()
        )
    }
}

// MARK: - Private implementation

private extension PolymarketDepositReceiveTokenFactory {
    func makePresentation() -> SendReceiveTokenPresentation {
        SendReceiveTokenPresentation(
            currencySymbol: AppConstants.usdCurrencyCode,
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
