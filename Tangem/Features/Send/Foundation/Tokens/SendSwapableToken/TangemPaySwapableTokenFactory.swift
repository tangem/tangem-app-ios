//
//  TangemPaySwapableTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress
import TangemPay

/// Maybe put in init `TangemPayAccount` ?
struct TangemPaySwapableTokenFactory: SendSwapableTokenFactory {
    let userWalletInfo: UserWalletInfo
    let account: (any TangemPayAccountModel)?
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let defaultAddressString: String
    let availableBalanceProvider: any TokenBalanceProvider
    let fiatAvailableBalanceProvider: any TokenBalanceProvider
    let transactionDispatcher: any TransactionDispatcher
    let transactionValidator: any SendTransactionValidator
    let operationType: ExpressOperationType
    /// Abstract receive-side presentation when this token is used as the swap destination
    /// (Add funds flow). Left `nil` when the token is used as the source (Withdraw flow).
    var receiveTokenPresentation: SendReceiveTokenPresentation? = nil

    func makeSwapableToken() -> SendSwapableToken {
        let sourceTokenFactory = TangemPaySourceTokenFactory(
            userWalletInfo: userWalletInfo,
            account: account,
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            defaultAddressString: defaultAddressString,
            availableBalanceProvider: availableBalanceProvider,
            fiatAvailableBalanceProvider: fiatAvailableBalanceProvider,
            transactionDispatcher: transactionDispatcher
        )
        let sourceToken = sourceTokenFactory.makeSourceToken()

        let sendingRestrictionsProvider = TangemPaySendingRestrictionsProvider()
        let receivingRestrictionsProvider = TangemPayReceivingRestrictionsProvider(userWalletInfo: userWalletInfo)

        let tokenFeeProvidersManagerProvider = TangemPayTokenFeeProvidersManagerProvider(
            feeTokenItem: feeTokenItem,
            feeTokenItemBalanceProvider: availableBalanceProvider
        )
        let tokenFeeProvidersManager = tokenFeeProvidersManagerProvider.makeTokenFeeProvidersManager()

        let transactionCreator = TangemPayTransactionCreator(
            sourceAddress: defaultAddressString,
            transactionValidator: transactionValidator
        )

        let balanceProvider = TangemPayExpressBalanceProvider(
            availableBalanceProvider: availableBalanceProvider
        )

        let analyticsLogger = CommonExpressAnalyticsLogger(tokenItem: tokenItem)

        let providerTransactionValidator = TangemPayExpressProviderTransactionValidator()

        let swapAvailabilityProvider = TangemPaySwapAvailabilityProvider()

        return CommonSendSwapableToken(
            sourceToken: sourceToken,
            isExemptFee: true,
            swapAvailabilityProvider: swapAvailabilityProvider,
            sendingRestrictionsProvider: sendingRestrictionsProvider,
            receivingRestrictionsProvider: receivingRestrictionsProvider,
            tokenFeeProvidersManagerProvider: tokenFeeProvidersManagerProvider,
            tokenFeeProvidersManager: tokenFeeProvidersManager,
            transactionValidator: transactionValidator,
            transactionCreator: transactionCreator,
            sendYieldModuleHelper: nil,
            balanceProvider: balanceProvider,
            analyticsLogger: analyticsLogger,
            providerTransactionValidator: providerTransactionValidator,
            operationType: operationType,

            // TangemPay is limited to CEX providers — every operation type collapses to a CEX-style filter.
            supportedProvidersFilter: .cex,
            presentation: receiveTokenPresentation
        )
    }
}

extension TangemPaySwapableTokenFactory {
    /// The account carries all the plumbing — call sites only choose the token, address, and role.
    init(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        account: (any TangemPayAccountModel)?,
        tokenItem: TokenItem,
        depositAddress: String,
        operationType: ExpressOperationType,
        receiveTokenPresentation: SendReceiveTokenPresentation?
    ) {
        self.init(
            userWalletInfo: userWalletInfo,
            account: account,
            tokenItem: tokenItem,
            feeTokenItem: tokenItem,
            defaultAddressString: depositAddress,
            availableBalanceProvider: tangemPayAccount.balancesProvider.availableBalanceProvider,
            fiatAvailableBalanceProvider: tangemPayAccount.balancesProvider.fiatAvailableBalanceProvider,
            transactionDispatcher: tangemPayAccount.transactionDispatcher,
            transactionValidator: TangemPaySendTransactionValidator(
                availableBalanceProvider: tangemPayAccount.balancesProvider.availableBalanceProvider
            ),
            operationType: operationType,
            receiveTokenPresentation: receiveTokenPresentation
        )
    }
}

extension SendReceiveTokenPresentation {
    /// The payment account is always presented in USD, independent of the wallet's selected
    /// fiat currency.
    static var tangemPayAccount: SendReceiveTokenPresentation? {
        guard FeatureProvider.isAvailable(.tangemPayAddFundsWithdrawRework) else {
            return nil
        }

        return SendReceiveTokenPresentation(currencySymbol: TangemPayUtilities.fiatItem.currencyCode)
    }
}
