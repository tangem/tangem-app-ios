//
//  TangemPayWithdrawSwapPredefinedParametersBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPay

struct TangemPayWithdrawSwapPredefinedParametersBuilder: SwapPredefinedParametersBuilder {
    let userWalletInfo: UserWalletInfo
    let tangemPayAccount: TangemPayAccount
    let accountTokens: [TangemPayAccountToken]
    let sourceAccountToken: TangemPayAccountToken
    let repeatedTarget: TangemPayRecentOperationTarget?
    let recentOperationsRecorder: TangemPayRecentOperationsRecorder

    func make() -> PredefinedSwapParameters {
        let sourceToken = makeSwapableToken(accountToken: sourceAccountToken)

        let receive: any SwapReceiveTokenResolver = if let repeatedTarget, let receiveToken = TangemPayRepeatedWithdrawReceiveTokenFactory(target: repeatedTarget).makeReceiveToken() {
            .resolved(receiveToken)
        } else {
            .userSelection
        }

        return PredefinedSwapParameters(
            userWalletInfo: sourceToken.userWalletInfo,
            source: .resolved(sourceToken),
            receive: receive,
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                sourceTokenSelection: .selectable(makeSourceSelection()),
                // Moving funds between the account's own tokens isn't a withdrawal.
                receiveTokenSelection: .selectable(.filtered(isIncluded: { !$0.isPayAccount })),
                summaryTitle: Localization.tangempayCardDetailsWithdraw,
                onTransactionSent: recentOperationsRecorder.record
            )
        )
    }
}

// MARK: - Private

private extension TangemPayWithdrawSwapPredefinedParametersBuilder {
    func makeSwapableToken(accountToken: TangemPayAccountToken) -> any SendSwapableToken {
        TangemPaySwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            tangemPayAccount: tangemPayAccount,
            account: tangemPayAccount.account,
            accountToken: accountToken,
            operationType: .swap,
            receiveTokenPresentation: nil
        ).makeSwapableToken()
    }

    func makeSourceSelection() -> SwapFlowConfiguration.TokenSelection {
        guard let tangemPayAccountModel = tangemPayAccount.account else {
            // The base provider spans every unlocked wallet, hence the filtering by wallet.
            return .restricted(
                walletsProvider: FilteredTokenSelectorWalletsProvider(
                    base: .cryptoJointTangemPayAccounts(),
                    includesWallet: { [userWalletId = userWalletInfo.id] wallet in
                        wallet.wallet.id == userWalletId
                    },
                    isIncluded: { $0.isPayAccount }
                ),
                allowsMarketsTokens: false
            )
        }

        return .restricted(
            walletsProvider: TangemPayWithdrawSourceWalletsProvider(
                userWalletInfo: userWalletInfo,
                tangemPayAccount: tangemPayAccount,
                tangemPayAccountModel: tangemPayAccountModel,
                // A token the withdraw API can't address can hold funds, but nothing moves them out.
                accountTokens: accountTokens.filter(\.isWithdrawEligible)
            ),
            // A markets token can never be a payment account row.
            allowsMarketsTokens: false
        )
    }
}
