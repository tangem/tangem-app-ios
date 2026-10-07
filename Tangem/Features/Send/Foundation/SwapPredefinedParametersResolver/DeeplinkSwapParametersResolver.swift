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
        deeplink: SwapDeeplink,
        accountModelsManager: some AccountModelsManager,
        userWalletInfo: UserWalletInfo
    ) -> PredefinedSwapParameters? {
        guard let selection = selectPair(
            deeplink: deeplink,
            accountModelsManager: accountModelsManager,
            userWalletInfo: userWalletInfo
        ) else {
            return nil
        }

        return SwapPredefinedParametersHelper().makeParameters(
            fromWalletModel: selection.source,
            toWalletModel: selection.destination,
            userWalletInfo: userWalletInfo,
            extras: makeExtras(deeplink: deeplink, isApplicable: selection.appliesExtras)
        )
    }

    /// `from_amount` / `provider_id` are honored only for a fully-specified held pair — both sides requested
    /// and matched. With a best-effort source or a manual TO the pair is ambiguous, so they're dropped.
    private func makeExtras(deeplink: SwapDeeplink, isApplicable: Bool) -> PredefinedSwapParameters.Extras? {
        guard isApplicable else {
            return nil
        }

        let sourceAmount = Decimal(stringValue: deeplink.fromAmount).flatMap { $0 > 0 ? $0 : nil }
        let providerId = deeplink.providerId?.nilIfEmpty

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
        deeplink: SwapDeeplink,
        accountModelsManager: some AccountModelsManager,
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
                accountId: DeeplinkWalletModelLocator.accountIdentifier(of: walletModel.account),
                fiatBalance: walletModel.fiatAvailableBalanceProvider.balanceType.value ?? 0,
                isSwappable: expressAvailabilityProvider.swapState(for: walletModel.tokenItem) == .available
            )
        }

        guard let selection = Self.selectCandidates(
            candidates: candidates,
            deeplink: deeplink,
            targetUserWalletId: userWalletInfo.id.stringValue,
            existingAccountIds: existingAccountIds(in: accountModelsManager)
        ) else {
            return nil
        }

        return SelectedPair(
            source: walletModels[selection.source.index],
            destination: selection.destination.map { walletModels[$0.index] },
            appliesExtras: selection.appliesExtras
        )
    }

    /// The backend identifiers of the accounts the wallet has, which is what a deeplink names an account by.
    func existingAccountIds(in accountModelsManager: some AccountModelsManager) -> Set<String> {
        AccountModelsAggregator(.crypto, .joint)
            .models(from: accountModelsManager)
            .compactMap { DeeplinkWalletModelLocator.accountIdentifier(of: $0) }
            .toSet()
    }
}

// MARK: - Selection algorithm

extension DeeplinkSwapParametersResolver {
    /// A swap-eligible token the user holds. `index` maps back to the source wallet model list.
    struct Candidate: Equatable {
        let index: Int
        let tokenId: String?
        let networkId: String
        let accountId: String?
        let fiatBalance: Decimal
        let isSwappable: Bool
    }

    /// Pure FROM/TO selection over the candidates. `nil` means "open swap as from Main". `appliesExtras` is
    /// `true` only for a fully-specified held pair (both sides requested and matched), gating amount/provider.
    static func selectCandidates(
        candidates: [Candidate],
        deeplink: SwapDeeplink,
        targetUserWalletId: String,
        existingAccountIds: Set<String>
    ) -> (source: Candidate, destination: Candidate?, appliesExtras: Bool)? {
        let fromRequested = isSideRequested(
            tokenId: deeplink.fromTokenId,
            networkId: deeplink.fromNetworkId,
            userWalletId: deeplink.fromUserWalletId,
            targetUserWalletId: targetUserWalletId
        )

        let toRequested = isSideRequested(
            tokenId: deeplink.toTokenId,
            networkId: deeplink.toNetworkId,
            userWalletId: deeplink.toUserWalletId,
            targetUserWalletId: targetUserWalletId
        )

        guard fromRequested || toRequested else {
            return nil
        }

        // An account the wallet doesn't have narrows nothing — otherwise it would filter out the very tokens the link asks for.
        let fromRequiredAccountId = deeplink.fromUserAccountId.flatMap { existingAccountIds.contains($0) ? $0 : nil }
        let toRequiredAccountId = deeplink.toUserAccountId.flatMap { existingAccountIds.contains($0) ? $0 : nil }

        let source = fromRequested
            ? mostFundedMatch(in: candidates, tokenId: deeplink.fromTokenId, networkId: deeplink.fromNetworkId, requiredAccountId: fromRequiredAccountId, preferredAccountId: nil)
            : nil

        let destination = toRequested
            ? mostFundedMatch(in: candidates, tokenId: deeplink.toTokenId, networkId: deeplink.toNetworkId, requiredAccountId: toRequiredAccountId, preferredAccountId: source?.accountId)
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
    /// A side counts as requested only with a complete `token_id` + `network_id` and a per-side
    /// `user_wallet_id` naming this wallet. An incomplete or foreign side is treated as not specified.
    ///
    /// `user_account_id` has no say here on purpose: it only narrows where the requested token is looked
    /// up, so an account this device doesn't have must not discard the tokens that came with it.
    static func isSideRequested(
        tokenId: String?,
        networkId: String?,
        userWalletId: String?,
        targetUserWalletId: String
    ) -> Bool {
        guard tokenId != nil, networkId != nil else {
            return false
        }

        if let userWalletId, userWalletId != targetUserWalletId {
            return false
        }

        return true
    }

    /// Most-funded swap-eligible matching token. `requiredAccountId` (a valid deeplink `user_account_id`) hard-limits
    /// selection to that account. `preferredAccountId` (TO relative to the resolved FROM) is a soft
    /// preference — a match inside that account wins over more-funded matches elsewhere.
    static func mostFundedMatch(
        in candidates: [Candidate],
        tokenId: String?,
        networkId: String?,
        requiredAccountId: String?,
        preferredAccountId: String?
    ) -> Candidate? {
        guard let tokenId, let networkId else {
            return nil
        }

        var matching = candidates.filter { $0.tokenId == tokenId && $0.networkId == networkId && $0.isSwappable }

        if let requiredAccountId {
            matching = matching.filter { $0.accountId == requiredAccountId }
        }

        if let preferredAccountId {
            let sameAccount = matching.filter { $0.accountId == preferredAccountId }
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
