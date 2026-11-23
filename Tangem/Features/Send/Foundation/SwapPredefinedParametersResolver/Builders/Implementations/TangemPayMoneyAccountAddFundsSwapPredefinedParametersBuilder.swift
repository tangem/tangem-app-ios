//
//  TangemPayMoneyAccountAddFundsSwapPredefinedParametersBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct TangemPayMoneyAccountAddFundsSwapPredefinedParametersBuilder: SwapPredefinedParametersBuilder {
    let userWalletModel: any UserWalletModel
    let moneyAccount: any TangemPayMoneyAccountModel

    func make() -> PredefinedSwapParameters {
        let walletModel = moneyAccount.walletModel
        let availableBalanceProvider = walletModel.availableBalanceProvider

        let receiveToken = TangemPaySwapableTokenFactory(
            userWalletInfo: userWalletModel.userWalletInfo,
            account: TangemPayMoneyAccountModelAdapter(moneyAccount: moneyAccount),
            tokenItem: moneyAccount.tokenItem,
            feeTokenItem: moneyAccount.tokenItem,
            defaultAddressString: walletModel.defaultAddressString,
            availableBalanceProvider: availableBalanceProvider,
            fiatAvailableBalanceProvider: TangemPayFiatTokenBalanceProvider(cryptoBalanceProvider: availableBalanceProvider),
            transactionDispatcher: UnsupportedTransactionDispatcher(),
            transactionValidator: TangemPaySendTransactionValidator(availableBalanceProvider: availableBalanceProvider),
            operationType: .swap
        ).makeSwapableToken()

        let sourceResolver = TangemPayAddFundsSourceResolver(
            userWalletModel: userWalletModel,
            preferredTokenItems: [receiveToken.tokenItem]
        )

        return PredefinedSwapParameters(
            userWalletInfo: userWalletModel.userWalletInfo,
            source: sourceResolver,
            receive: .resolved(receiveToken),
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                sourceTokenSelection: .selectable(.filtered(isIncluded: { !$0.isPayAccount })),
                receiveTokenSelection: .followsSource(
                    AccountFundingDestinationResolver(
                        candidates: [receiveToken],
                        defaultDestination: receiveToken
                    )
                ),
                summaryTitle: Localization.tangempayCardDetailsAddFunds
            )
        )
    }
}
