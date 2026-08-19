//
//  TangemPayFundingFlowBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemPay

/// Builds the swap parameters behind Add funds and Withdraw. Returns `nil` while the account has no
/// address to fund or withdraw from.
struct TangemPayFundingFlowBuilder {
    private let userWalletInfo: UserWalletInfo
    private let userWalletModel: any UserWalletModel
    private let tangemPayAccount: TangemPayAccount

    init(
        userWalletInfo: UserWalletInfo,
        userWalletModel: any UserWalletModel,
        tangemPayAccount: TangemPayAccount
    ) {
        self.userWalletInfo = userWalletInfo
        self.userWalletModel = userWalletModel
        self.tangemPayAccount = tangemPayAccount
    }

    @MainActor
    func addFunds() async -> PredefinedSwapParameters? {
        guard let receiveToken = makeSwapableToken(presentation: receiveTokenPresentation) else {
            return nil
        }

        guard FeatureProvider.isAvailable(.tangemPayAddFundsWithdrawRework) else {
            return .to(receiveToken)
        }

        // Non-empty by construction: a present deposit address guarantees at least the default token.
        let destinationCandidates = await makeDestinationCandidates()

        let sourceResolver = TangemPayAddFundsSourceResolver(
            userWalletModel: userWalletModel,
            preferredTokenItems: destinationCandidates.map { $0.tokenItem },
            availabilityChecker: CommonFundingSourceAvailabilityChecker(userWalletInfo: userWalletInfo)
        )

        return .to(
            receiveToken,
            sourceResolver: sourceResolver,
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                // Funding the account from itself makes no sense.
                sourceTokenSelection: .filtered(isIncluded: { !$0.isPayAccount }),
                receiveTokenSelection: .followsSource(
                    TangemPayAddFundsDestinationResolver(
                        candidates: destinationCandidates,
                        defaultDestination: receiveToken
                    )
                ),
                summaryTitle: Localization.tangempayCardDetailsAddFunds
            )
        )
    }

    @MainActor
    func withdraw() async -> PredefinedSwapParameters? {
        guard let sourceToken = await makeWithdrawSourceToken() else {
            return nil
        }

        guard FeatureProvider.isAvailable(.tangemPayAddFundsWithdrawRework) else {
            return .from(sourceToken)
        }

        return .from(
            sourceToken,
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                // The base provider spans every unlocked wallet, hence the filtering by wallet.
                sourceTokenSelection: .restricted(
                    walletsProvider: FilteredTokenSelectorWalletsProvider(
                        base: .common(),
                        includesWallet: { [userWalletId = userWalletInfo.id] wallet in
                            wallet.wallet.id == userWalletId
                        },
                        isIncluded: { $0.isPayAccount }
                    )
                ),
                // Withdrawing the account into itself makes no sense.
                receiveTokenSelection: .filtered(isIncluded: { !$0.isPayAccount }),
                summaryTitle: Localization.tangempayCardDetailsWithdraw
            )
        )
    }
}

// MARK: - Tokens

private extension TangemPayFundingFlowBuilder {
    /// The account's tokens on the networks it is already issued on. Falls back to the account-wide
    /// token when that list is unavailable — an empty one would strand both funding flows.
    @MainActor
    func accountTokens() async -> [TangemPayAccountToken] {
        guard FeatureProvider.isAvailable(.tangemPayMultichain) else {
            return defaultAccountTokens
        }

        // An empty list also means "not loaded yet" — reload so only an account that truly
        // has no enabled networks falls back to the default token.
        if tangemPayAccount.networks.isEmpty {
            await tangemPayAccount.loadBalance()
        }

        let resolved = await TangemPayAccountTokensResolver().resolve(networks: tangemPayAccount.networks)
        return resolved.isEmpty ? defaultAccountTokens : resolved
    }

    var defaultAccountTokens: [TangemPayAccountToken] {
        guard let depositAddress = tangemPayAccount.depositAddress else {
            return []
        }

        return [
            TangemPayAccountToken(
                tokenItem: TangemPayUtilities.usdcTokenItem,
                depositAddress: depositAddress,
                availableForWithdrawal: nil
            ),
        ]
    }

    /// Starts from the token holding the most funds the withdraw API can actually move.
    /// `nil` when no such token is active — the flow would offer a withdrawal the API can't execute.
    @MainActor
    func makeWithdrawSourceToken() async -> (any SendSwapableToken)? {
        guard FeatureProvider.isAvailable(.tangemPayAddFundsWithdrawRework) else {
            return makeSwapableToken(presentation: nil)
        }

        guard let mostFunded = await accountTokens().withdrawStartingPoint else {
            return nil
        }

        return makeSwapableToken(
            tokenItem: mostFunded.tokenItem,
            depositAddress: mostFunded.depositAddress,
            presentation: nil
        )
    }

    @MainActor
    func makeDestinationCandidates() async -> [any SendSwapableToken] {
        await accountTokens().fundingPriorityOrdered.map { accountToken in
            makeSwapableToken(
                tokenItem: accountToken.tokenItem,
                depositAddress: accountToken.depositAddress,
                presentation: receiveTokenPresentation
            )
        }
    }

    func makeSwapableToken(presentation: SendReceiveTokenPresentation?) -> (any SendSwapableToken)? {
        guard let depositAddress = tangemPayAccount.depositAddress else {
            return nil
        }

        return makeSwapableToken(
            tokenItem: TangemPayUtilities.usdcTokenItem,
            depositAddress: depositAddress,
            presentation: presentation
        )
    }

    func makeSwapableToken(
        tokenItem: TokenItem,
        depositAddress: String,
        presentation: SendReceiveTokenPresentation?
    ) -> any SendSwapableToken {
        TangemPaySwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            tangemPayAccount: tangemPayAccount,
            account: tangemPayAccount.account,
            tokenItem: tokenItem,
            depositAddress: depositAddress,
            operationType: .swap,
            receiveTokenPresentation: presentation
        ).makeSwapableToken()
    }

    var receiveTokenPresentation: SendReceiveTokenPresentation? {
        .tangemPayAccount
    }
}
