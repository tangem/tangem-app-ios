//
//  DeeplinkSwapParametersResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Resolves the FROM/TO pair and optional amount/provider to preselect from a `tangem://swap` deeplink,
/// or `nil` when nothing usable can be preselected.
struct DeeplinkSwapParametersResolver {
    func resolve(
        params: DeeplinkNavigationAction.Params,
        accountModelsManager: any AccountModelsManager,
        userWalletInfo: UserWalletInfo
    ) -> PredefinedSwapParameters? {
        guard FeatureProvider.isAvailable(.swapDeeplinkParameters) else {
            return nil
        }

        guard let selection = selectPair(
            params: params,
            accountModelsManager: accountModelsManager,
            userWalletInfo: userWalletInfo
        ) else {
            return nil
        }

        return SwapPredefinedParametersHelper().makeParameters(
            fromWalletModel: selection.source,
            toWalletModel: selection.destination,
            userWalletInfo: userWalletInfo,
            extras: makeExtras(params: params, isApplicable: selection.appliesExtras)
        )
    }

    /// `from_amount` / `provider_id` are honored only for a fully-specified held pair — both sides requested
    /// and matched. With a best-effort source or a manual TO the pair is ambiguous, so they're dropped.
    private func makeExtras(params: DeeplinkNavigationAction.Params, isApplicable: Bool) -> PredefinedSwapParameters.Extras? {
        guard isApplicable else {
            return nil
        }

        let sourceAmount = Decimal(stringValue: params.swapFromAmount).flatMap { $0 > 0 ? $0 : nil }
        let providerId = params.swapProviderId?.nilIfEmpty

        guard sourceAmount != nil || providerId != nil else {
            return nil
        }

        return .init(sourceAmount: sourceAmount, providerId: providerId)
    }
}

// MARK: - Wallet model bridging

private extension DeeplinkSwapParametersResolver {
    struct SelectedPair {
        let source: any WalletModel
        let destination: (any WalletModel)?
        let appliesExtras: Bool
    }

    /// Builds lightweight candidates from the current wallet's models, runs the pure selection, then maps the
    /// chosen candidates back to their wallet models. Balances are read synchronously from cache.
    func selectPair(
        params: DeeplinkNavigationAction.Params,
        accountModelsManager: any AccountModelsManager,
        userWalletInfo: UserWalletInfo
    ) -> SelectedPair? {
        let walletModels = AccountWalletModelsAggregator.walletModels(from: accountModelsManager)
        let expressAvailabilityProvider = InjectedValues[\.expressAvailabilityProvider]

        let candidates = walletModels.enumerated().map { index, walletModel in
            Candidate(
                index: index,
                // Lowercased to match against the deeplink's already-lowercased token/network ids.
                tokenId: walletModel.tokenItem.id?.lowercased(),
                networkId: walletModel.tokenItem.blockchain.networkId.lowercased(),
                accountDerivationIndex: walletModel.account?.id.toPersistentIdentifier() as? Int,
                fiatBalance: walletModel.fiatAvailableBalanceProvider.balanceType.value ?? 0,
                isSwappable: expressAvailabilityProvider.swapState(for: walletModel.tokenItem) == .available
            )
        }

        guard let selection = Self.selectCandidates(
            candidates: candidates,
            params: params,
            targetUserWalletId: userWalletInfo.id.stringValue,
            existingAccounts: existingAccounts(in: accountModelsManager, userWalletId: userWalletInfo.id)
        ) else {
            return nil
        }

        return SelectedPair(
            source: walletModels[selection.source.index],
            destination: selection.destination.map { walletModels[$0.index] },
            appliesExtras: selection.appliesExtras
        )
    }

    /// Maps each crypto account's backend identifier (`AccountId.rawValue.hexString`) to its derivation index,
    /// for both consistency validation and pinning a side to the deeplink-specified account.
    func existingAccounts(in accountModelsManager: any AccountModelsManager, userWalletId: UserWalletId) -> [String: Int] {
        let pairs = accountModelsManager.cryptoAccountModels.compactMap { account -> (String, Int)? in
            guard let derivationIndex = account.id.toPersistentIdentifier() as? Int else {
                return nil
            }

            let accountId = CommonCryptoAccountModel.AccountId(
                userWalletId: userWalletId,
                derivationIndex: derivationIndex
            ).rawValue.hexString.lowercased()

            return (accountId, derivationIndex)
        }

        return Dictionary(pairs, uniquingKeysWith: { first, _ in first })
    }
}

// MARK: - Selection algorithm

extension DeeplinkSwapParametersResolver {
    /// A swap-eligible token the user holds. `index` maps back to the source wallet model list.
    struct Candidate: Equatable {
        let index: Int
        let tokenId: String?
        let networkId: String
        let accountDerivationIndex: Int?
        let fiatBalance: Decimal
        let isSwappable: Bool
    }

    /// Pure FROM/TO selection over the candidates. `nil` means "open swap as from Main". `appliesExtras` is
    /// `true` only for a fully-specified held pair (both sides requested and matched), gating amount/provider.
    static func selectCandidates(
        candidates: [Candidate],
        params: DeeplinkNavigationAction.Params,
        targetUserWalletId: String,
        existingAccounts: [String: Int]
    ) -> (source: Candidate, destination: Candidate?, appliesExtras: Bool)? {
        let fromRequested = isSideRequested(
            tokenId: params.swapFromTokenId,
            networkId: params.swapFromNetworkId,
            userWalletId: params.swapFromUserWalletId,
            userAccountId: params.swapFromUserAccountId,
            targetUserWalletId: targetUserWalletId,
            existingAccounts: existingAccounts
        )

        let toRequested = isSideRequested(
            tokenId: params.swapToTokenId,
            networkId: params.swapToNetworkId,
            userWalletId: params.swapToUserWalletId,
            userAccountId: params.swapToUserAccountId,
            targetUserWalletId: targetUserWalletId,
            existingAccounts: existingAccounts
        )

        guard fromRequested || toRequested else {
            return nil
        }

        let fromRequiredAccount = params.swapFromUserAccountId.flatMap { existingAccounts[$0] }
        let toRequiredAccount = params.swapToUserAccountId.flatMap { existingAccounts[$0] }

        let source = fromRequested
            ? mostFundedMatch(in: candidates, tokenId: params.swapFromTokenId, networkId: params.swapFromNetworkId, requiredAccountDerivationIndex: fromRequiredAccount, preferredAccountDerivationIndex: nil)
            : nil

        let destination = toRequested
            ? mostFundedMatch(in: candidates, tokenId: params.swapToTokenId, networkId: params.swapToNetworkId, requiredAccountDerivationIndex: toRequiredAccount, preferredAccountDerivationIndex: source?.accountDerivationIndex)
            : nil

        if fromRequested, toRequested, source == nil, destination == nil {
            return nil
        }

        guard let resolvedSource = source ?? bestEffortSource(in: candidates, excluding: destination) else {
            return nil
        }

        // A token can't be both the source and the destination of a swap.
        let resolvedDestination = destination?.index == resolvedSource.index ? nil : destination

        let appliesExtras = fromRequested && toRequested && source != nil && resolvedDestination != nil

        return (resolvedSource, resolvedDestination, appliesExtras)
    }
}

// MARK: - Selection helpers

private extension DeeplinkSwapParametersResolver {
    /// A side counts as requested only with a complete `token_id` + `network_id` and consistent per-side
    /// `user_wallet_id`/`user_account_id`. An incomplete or inconsistent side is treated as not specified.
    static func isSideRequested(
        tokenId: String?,
        networkId: String?,
        userWalletId: String?,
        userAccountId: String?,
        targetUserWalletId: String,
        existingAccounts: [String: Int]
    ) -> Bool {
        guard tokenId != nil, networkId != nil else {
            return false
        }

        if let userWalletId, userWalletId != targetUserWalletId {
            return false
        }

        if let userAccountId, existingAccounts[userAccountId] == nil {
            return false
        }

        return true
    }

    /// Most-funded swap-eligible matching token. `requiredAccountDerivationIndex` (a valid deeplink `user_account_id`) hard-limits
    /// selection to that account. `preferredAccountDerivationIndex` (TO relative to the resolved FROM) is a soft
    /// preference — a match inside that account wins over more-funded matches elsewhere.
    static func mostFundedMatch(
        in candidates: [Candidate],
        tokenId: String?,
        networkId: String?,
        requiredAccountDerivationIndex: Int?,
        preferredAccountDerivationIndex: Int?
    ) -> Candidate? {
        guard let tokenId, let networkId else {
            return nil
        }

        var matching = candidates.filter { $0.tokenId == tokenId && $0.networkId == networkId && $0.isSwappable }

        if let requiredAccountDerivationIndex {
            matching = matching.filter { $0.accountDerivationIndex == requiredAccountDerivationIndex }
        }

        if let preferredAccountDerivationIndex {
            let sameAccount = matching.filter { $0.accountDerivationIndex == preferredAccountDerivationIndex }
            if let match = sameAccount.max(by: { $0.fiatBalance < $1.fiatBalance }) {
                return match
            }
        }

        return matching.max { $0.fiatBalance < $1.fiatBalance }
    }

    static func bestEffortSource(in candidates: [Candidate], excluding destination: Candidate?) -> Candidate? {
        candidates
            .filter { $0.isSwappable && $0.index != destination?.index }
            .max { $0.fiatBalance < $1.fiatBalance }
    }
}
