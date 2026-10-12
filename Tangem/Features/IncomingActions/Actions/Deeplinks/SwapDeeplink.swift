//
//  SwapDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://swap[?from_*&to_*&from_amount&provider_id&user_wallet_id]`
///
/// No parameter can invalidate the link: whatever can't be used is ignored when the link is handled,
/// which opens the default swap instead of leaving the user where they were.
struct SwapDeeplink: HostNamedDeeplink, Equatable {
    static let host = "swap"

    let userWalletId: String?
    let fromTokenId: String?
    let fromNetworkId: String?
    let toTokenId: String?
    let toNetworkId: String?
    let fromUserWalletId: String?
    let toUserWalletId: String?
    let fromUserAccountId: String?
    let toUserAccountId: String?
    let fromAmount: String?
    let providerId: String?

    var action: DeeplinkNavigationAction { .swap(self) }

    init(
        userWalletId: String? = nil,
        fromTokenId: String? = nil,
        fromNetworkId: String? = nil,
        toTokenId: String? = nil,
        toNetworkId: String? = nil,
        fromUserWalletId: String? = nil,
        toUserWalletId: String? = nil,
        fromUserAccountId: String? = nil,
        toUserAccountId: String? = nil,
        fromAmount: String? = nil,
        providerId: String? = nil
    ) {
        self.userWalletId = userWalletId
        self.fromTokenId = fromTokenId
        self.fromNetworkId = fromNetworkId
        self.toTokenId = toTokenId
        self.toNetworkId = toNetworkId
        self.fromUserWalletId = fromUserWalletId
        self.toUserWalletId = toUserWalletId
        self.fromUserAccountId = fromUserAccountId
        self.toUserAccountId = toUserAccountId
        self.fromAmount = fromAmount
        self.providerId = providerId
    }
}

// MARK: - Parsing

extension SwapDeeplink {
    /// Parameters only a swap link carries.
    private enum Keys {
        static let fromTokenId = "from_token_id"
        static let fromNetworkId = "from_network_id"
        static let toTokenId = "to_token_id"
        static let toNetworkId = "to_network_id"
        static let fromUserWalletId = "from_user_wallet_id"
        static let toUserWalletId = "to_user_wallet_id"
        static let fromUserAccountId = "from_user_account_id"
        static let toUserAccountId = "to_user_account_id"
        static let fromAmount = "from_amount"
        static let providerId = "provider_id"
    }

    init(link: DeeplinkURL) {
        let query = link.query

        self.init(
            userWalletId: query.unchecked(Shared.userWalletId),
            fromTokenId: query.unchecked(Keys.fromTokenId, lowercased: true),
            fromNetworkId: query.unchecked(Keys.fromNetworkId, lowercased: true),
            toTokenId: query.unchecked(Keys.toTokenId, lowercased: true),
            toNetworkId: query.unchecked(Keys.toNetworkId, lowercased: true),
            fromUserWalletId: query.unchecked(Keys.fromUserWalletId),
            toUserWalletId: query.unchecked(Keys.toUserWalletId),
            fromUserAccountId: query.unchecked(Keys.fromUserAccountId, lowercased: true),
            toUserAccountId: query.unchecked(Keys.toUserAccountId, lowercased: true),
            fromAmount: query.unchecked(Keys.fromAmount),
            providerId: query.unchecked(Keys.providerId)
        )
    }
}

// MARK: - Navigation

extension SwapDeeplink {
    /// The swap this link opens on a screen that has no wallet of its own: on the wallet the link names, or on
    /// the selected one when this device doesn't have that wallet.
    @MainActor
    func makeParameters() -> PredefinedSwapParameters? {
        let locator = DeeplinkWalletModelLocator()
        let requestedUserWalletModel = userWalletId.flatMap { locator.findUserWalletModel(userWalletModelId: $0) }

        // Unlike the wallet-specific destinations, swap doesn't die on an unresolvable `user_wallet_id`.
        guard let userWalletModel = requestedUserWalletModel ?? locator.findUserWalletModel(userWalletModelId: nil) else {
            return nil
        }

        // The preselection goes with the wallet it was made for: those tokens were picked for a portfolio this
        // device doesn't have, so preselecting them on the selected wallet would be a guess. A link that names
        // no wallet at all was written for whichever one is selected, and keeps what it asks for.
        let namedWalletIsMissing = userWalletId != nil && requestedUserWalletModel == nil

        return makeParameters(for: userWalletModel, preselecting: !namedWalletIsMissing)
    }

    @MainActor
    func makeParameters(for userWalletModel: any UserWalletModel, preselecting: Bool = true) -> PredefinedSwapParameters? {
        guard userWalletModel.config.hasFeature(.swapping) else {
            return nil
        }

        if preselecting, let parameters = DeeplinkSwapParametersResolver().resolve(
            deeplink: self,
            accountModelsManager: userWalletModel.accountModelsManager,
            userWalletInfo: userWalletModel.userWalletInfo
        ) {
            return parameters
        }

        let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        guard let sourceToken = MainSwapSourceResolver.makeBestEffortSourceToken(
            from: walletModels,
            userWalletInfo: userWalletModel.userWalletInfo
        ) else {
            return nil
        }

        let resolver = MainSwapSourceResolver(
            userWalletModel: userWalletModel,
            swapAvailabilityChecker: CommonSwapAvailabilityChecker(userWalletInfo: userWalletModel.userWalletInfo)
        )

        return .from(sourceToken, pair: .deferred(sourceResolver: resolver))
    }
}
