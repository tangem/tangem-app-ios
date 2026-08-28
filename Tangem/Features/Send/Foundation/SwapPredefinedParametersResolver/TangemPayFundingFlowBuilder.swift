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

        // Empty once the account is issued on no network; the resolver then keeps the default destination.
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

    enum WithdrawResolution {
        case parameters(PredefinedSwapParameters)
        case unavailable
    }

    @MainActor
    func withdraw() async -> WithdrawResolution {
        guard FeatureProvider.isAvailable(.tangemPayAddFundsWithdrawRework) else {
            guard let sourceToken = makeSwapableToken(presentation: nil) else {
                return .unavailable
            }

            return .parameters(.from(sourceToken))
        }

        let accountTokens = await accountTokens()

        guard let mostFunded = accountTokens.withdrawStartingPoint else {
            return .unavailable
        }

        let sourceToken = makeSwapableToken(accountToken: mostFunded, presentation: nil)

        return .parameters(.from(
            sourceToken,
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                sourceTokenSelection: makeWithdrawSourceSelection(accountTokens: accountTokens),
                // Moving funds between the account's own tokens isn't a withdrawal.
                receiveTokenSelection: .selectable(.filtered(isIncluded: { !$0.isPayAccount })),
                summaryTitle: Localization.tangempayCardDetailsWithdraw
            )
        ))
    }

    private func makeWithdrawSourceSelection(
        accountTokens: [TangemPayAccountToken]
    ) -> SwapFlowConfiguration.TokenSelection {
        guard let tangemPayAccountModel = tangemPayAccount.account else {
            // The base provider spans every unlocked wallet, hence the filtering by wallet.
            return .restricted(
                walletsProvider: FilteredTokenSelectorWalletsProvider(
                    base: .common(),
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

// MARK: - Tokens

private extension TangemPayFundingFlowBuilder {
    @MainActor
    func accountTokens() async -> [TangemPayAccountToken] {
        guard FeatureProvider.isAvailable(.tangemPayMultichain) else {
            return defaultAccountTokens
        }

        // An empty list also means "not loaded yet" — reload so only an account that truly
        // has no enabled networks ends up with nothing.
        if tangemPayAccount.networks.isEmpty {
            await tangemPayAccount.loadBalance()
        }

        return TangemPayAccountTokensResolver().resolve(networks: tangemPayAccount.networks)
    }

    var defaultAccountTokens: [TangemPayAccountToken] {
        guard let depositAddress = tangemPayAccount.depositAddress else {
            return []
        }

        return [
            TangemPayAccountToken(
                tokenItem: TangemPayUtilities.usdcTokenItem,
                depositAddress: depositAddress,
                availableForWithdrawal: nil,
                chainId: nil
            ),
        ]
    }

    @MainActor
    func makeDestinationCandidates() async -> [any SendSwapableToken] {
        await accountTokens().fundingPriorityOrdered.map { accountToken in
            makeSwapableToken(accountToken: accountToken, presentation: receiveTokenPresentation)
        }
    }

    func makeSwapableToken(presentation: SendReceiveTokenPresentation?) -> (any SendSwapableToken)? {
        guard let accountToken = defaultAccountTokens.first else {
            return nil
        }

        return makeSwapableToken(accountToken: accountToken, presentation: presentation)
    }

    func makeSwapableToken(
        accountToken: TangemPayAccountToken,
        presentation: SendReceiveTokenPresentation?
    ) -> any SendSwapableToken {
        TangemPaySwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            tangemPayAccount: tangemPayAccount,
            account: tangemPayAccount.account,
            accountToken: accountToken,
            operationType: .swap,
            receiveTokenPresentation: presentation
        ).makeSwapableToken()
    }

    var receiveTokenPresentation: SendReceiveTokenPresentation? {
        .tangemPayAccount
    }
}
