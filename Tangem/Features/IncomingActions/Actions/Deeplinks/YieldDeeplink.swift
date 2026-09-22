//
//  YieldDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://yield[?token_id&network_id&user_wallet_id&derivation_path]`
///
/// Nothing is required: a link that can't reach the Yield-mode screen falls back to the Earn screen
/// when it is handled, so only malformed values turn it away.
struct YieldDeeplink: HostNamedDeeplink, Equatable {
    static let host = "yield"

    let tokenId: String?
    let networkId: String?
    let userWalletId: String?
    let derivationPath: String?

    var action: DeeplinkNavigationAction { .yield(self) }

    init(tokenId: String? = nil, networkId: String? = nil, userWalletId: String? = nil, derivationPath: String? = nil) {
        self.tokenId = tokenId
        self.networkId = networkId
        self.userWalletId = userWalletId
        self.derivationPath = derivationPath
    }
}

// MARK: - Parsing

extension YieldDeeplink {
    init(link: DeeplinkURL) throws {
        let query = link.query

        tokenId = try query.optional(Shared.tokenId, lowercased: true)
        networkId = try query.optional(Shared.networkId, lowercased: true)
        userWalletId = query.unchecked(Shared.userWalletId)
        derivationPath = query.unchecked(Shared.derivationPath)
    }
}

// MARK: - Navigation

extension YieldDeeplink {
    /// The token this link points at, when it can enter Yield mode at all.
    @MainActor
    func findTarget() -> DeeplinkWalletModelLocator.Target? {
        guard
            let tokenId,
            let networkId,
            let target = DeeplinkWalletModelLocator().findTarget(
                userWalletId: userWalletId,
                tokenId: tokenId,
                networkId: networkId,
                derivationPath: derivationPath
            ),
            TokenActionAvailabilityProvider(
                userWalletInfo: target.userWalletModel.userWalletInfo,
                walletModel: target.walletModel
            ).isTokenInteractionAvailable(),
            target.walletModel.yieldModuleManager != nil,
            target.walletModel.multipleTransactionsSender != nil
        else {
            return nil
        }

        return target
    }

    /// Where a link that can't reach Yield mode lands instead: the Earn list, still filtered by the network it
    /// named when that is a network we support.
    var earnFallbackNetworkId: String? {
        networkId.flatMap { networkId in
            SupportedBlockchains.all.contains { $0.networkId == networkId } ? networkId : nil
        }
    }
}
