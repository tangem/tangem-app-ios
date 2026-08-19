//
//  TangemPayAddFundsDestinationResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

/// Picks the payment-account token to receive the funds, in priority order:
/// 1. The account token whose currency equals the source's (token + network) — the same equality
///    `ExpressManagerSwappingPair.isTransfer` uses, so Express treats the pair as a plain transfer.
/// 2. A *different* account token in the source's network — a swap that never leaves the network.
///    Same-asset candidates that differ only in contract-address checksum casing are excluded here:
///    they would fail the exact transfer check above yet make a degenerate token-into-itself swap.
/// 3. Any candidate that isn't the source's own asset, then the account's default token.
final class TangemPayAddFundsDestinationResolver {
    private let candidates: [SendSwapableToken]
    private let defaultDestination: SendSwapableToken

    init(candidates: [SendSwapableToken], defaultDestination: SendSwapableToken) {
        self.candidates = candidates
        self.defaultDestination = defaultDestination
    }
}

// MARK: - SwapDestinationTokenResolver

extension TangemPayAddFundsDestinationResolver: SwapDestinationTokenResolver {
    func resolveDestination(for source: SendSwapableToken) -> SendReceiveToken {
        let sourceCurrency = source.tokenItem.expressCurrency

        // 1. Same currency — Express treats the pair as a plain transfer.
        if let transfer = candidates.first(where: { $0.tokenItem.expressCurrency == sourceCurrency }) {
            return transfer
        }

        // 2. A different asset in the source's network — a swap that never leaves the network.
        if let inNetworkSwap = candidates.first(where: { candidate in
            candidate.tokenItem.expressCurrency.network == sourceCurrency.network
                && !candidate.tokenItem.isSameAsset(as: source.tokenItem)
        }) {
            return inNetworkSwap
        }

        // 3. Any candidate holding a different asset. The bare default would not do: the source
        //    can be a user-saved copy of the default's own asset (same contract, other metadata),
        //    and swapping a token into itself is meaningless.
        return candidates.first { !$0.tokenItem.isSameAsset(as: source.tokenItem) } ?? defaultDestination
    }
}

// MARK: - Helpers

private extension TokenItem {
    /// Same network and same contract up to case — the casing rule of the app's token
    /// identity, `Token.==`.
    func isSameAsset(as other: TokenItem) -> Bool {
        guard networkId == other.networkId else {
            return false
        }

        switch (contractAddress, other.contractAddress) {
        case (.none, .none):
            return true
        case (.some(let lhs), .some(let rhs)):
            return lhs.caseInsensitiveCompare(rhs) == .orderedSame
        default:
            return false
        }
    }
}
