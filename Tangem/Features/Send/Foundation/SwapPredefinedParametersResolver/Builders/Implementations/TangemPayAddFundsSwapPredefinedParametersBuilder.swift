//
//  TangemPayAddFundsSwapPredefinedParametersBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPay

struct TangemPayAddFundsSwapPredefinedParametersBuilder: SwapPredefinedParametersBuilder {
    let userWalletInfo: UserWalletInfo
    let userWalletModel: any UserWalletModel
    let tangemPayAccount: TangemPayAccount
    let depositAddress: String
    let accountTokens: [TangemPayAccountToken]
    let recentOperationsRecorder: TangemPayRecentOperationsRecorder

    func make() -> PredefinedSwapParameters {
        let receiveToken = makeSwapableToken(
            accountToken: TangemPayAccountToken(
                tokenItem: TangemPayUtilities.usdcTokenItem,
                depositAddress: depositAddress,
                availableForWithdrawal: nil,
                chainId: nil
            )
        )

        // Empty once the account is issued on no network; the resolver then keeps the default destination.
        let destinationCandidates = accountTokens.fundingPriorityOrdered.map { makeSwapableToken(accountToken: $0) }

        let sourceResolver = TangemPayAddFundsSourceResolver(
            userWalletModel: userWalletModel,
            preferredTokenItems: destinationCandidates.map { $0.tokenItem }
        )

        return PredefinedSwapParameters(
            userWalletInfo: receiveToken.userWalletInfo,
            source: sourceResolver,
            receive: .resolved(receiveToken),
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                // Funding the account from itself makes no sense.
                sourceTokenSelection: .selectable(.filtered(isIncluded: { !$0.isPayAccount })),
                receiveTokenSelection: .followsSource(
                    AccountFundingDestinationResolver(
                        candidates: destinationCandidates,
                        defaultDestination: receiveToken
                    )
                ),
                summaryTitle: Localization.tangempayCardDetailsAddFunds,
                onTransactionSent: recentOperationsRecorder.record
            )
        )
    }
}

// MARK: - Private

private extension TangemPayAddFundsSwapPredefinedParametersBuilder {
    func makeSwapableToken(accountToken: TangemPayAccountToken) -> any SendSwapableToken {
        TangemPaySwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            tangemPayAccount: tangemPayAccount,
            account: tangemPayAccount.account,
            accountToken: accountToken,
            operationType: .swap,
            receiveTokenPresentation: .tangemPayAccount
        ).makeSwapableToken()
    }
}
