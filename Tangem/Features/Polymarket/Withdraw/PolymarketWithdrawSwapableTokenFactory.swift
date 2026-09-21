//
//  PolymarketWithdrawSwapableTokenFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemPolymarket

struct PolymarketWithdrawSwapableTokenFactory: SendSwapableTokenFactory {
    let userWalletInfo: UserWalletInfo
    let source: PolymarketWithdrawSource

    func makeSwapableToken() -> SendSwapableToken {
        let accountModel = source.accountModel
        let tokenItem = PolymarketUtilities.usdcTokenItem
        let balanceProvider = PolymarketWithdrawBalanceProvider(
            base: accountModel.collateralTokenBalanceProvider,
            tokenItem: tokenItem
        )

        let transactionValidator = PolymarketWithdrawTransactionValidator(
            availableBalanceProvider: balanceProvider,
            minimum: PolymarketUSDAmount(usd: source.minimumUSD, tokenItem: tokenItem)
        )

        let transactionDispatcherProvider = TransferAndCEXTransactionDispatcherProvider(
            transactionDispatcher: PolymarketWithdrawTransactionDispatcher(
                withdrawTransactionService: source.transactionService,
                signer: source.signer
            )
        )

        let sourceToken = CommonSendSourceToken(
            userWalletInfo: userWalletInfo,
            id: WalletModelId(tokenItem: tokenItem),
            header: TokenHeaderProvider(userWalletName: userWalletInfo.name, account: accountModel).makeHeader(),
            feeTokenItem: tokenItem,
            isCustom: false,
            defaultAddressString: source.depositWalletAddress,
            availableBalanceProvider: balanceProvider,
            fiatAvailableBalanceProvider: accountModel.fiatAvailableBalanceProvider,
            allowanceService: nil,
            withdrawalNotificationProvider: nil,
            scaledUIAmountMultiplierResolver: nil,
            emailDataCollectorBuilder: PolymarketAccountEmailDataCollectorBuilder(),
            transactionDispatcherProvider: transactionDispatcherProvider,
            accountModelAnalyticsProvider: nil,
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config),
            confirmTransactionPolicy: CommonConfirmTransactionPolicy(userWalletInfo: userWalletInfo),
            isTangemPayAccount: false,
            tokenItem: tokenItem,
            fiatItem: makeFiatItem(),
            address: source.depositWalletAddress,
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
            receivingRestrictionsProvider: PolymarketWithdrawReceivingRestrictionsProvider(),
            tokenFeeProvidersManagerProvider: feeProvidersManagerProvider,
            tokenFeeProvidersManager: feeProvidersManagerProvider.makeTokenFeeProvidersManager(),
            transactionValidator: transactionValidator,
            transactionCreator: AccountTransactionCreator(
                sourceAddress: source.depositWalletAddress,
                transactionValidator: transactionValidator
            ),
            sendYieldModuleHelper: nil,
            balanceProvider: CommonExpressBalanceProvider(
                availableBalanceProvider: balanceProvider,
                feeBalanceProvider: balanceProvider
            ),
            analyticsLogger: CommonExpressAnalyticsLogger(tokenItem: tokenItem),
            providerTransactionValidator: PolymarketAccountExpressProviderTransactionValidator(),
            operationType: .swap,

            supportedProvidersFilter: .cex,
            presentation: nil
        )
    }
}

// MARK: - Private implementation

private extension PolymarketWithdrawSwapableTokenFactory {
    func makeFiatItem() -> FiatItem {
        FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )
    }
}
