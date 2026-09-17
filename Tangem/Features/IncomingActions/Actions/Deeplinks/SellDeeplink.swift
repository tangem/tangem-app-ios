//
//  SellDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://sell[?user_wallet_id]`
struct SellDeeplink: HostNamedDeeplink, Equatable {
    static let host = "sell"

    let userWalletId: String?

    var action: DeeplinkNavigationAction { .sell(self) }
}

// MARK: - Parsing

extension SellDeeplink {
    init(link: DeeplinkURL) throws {
        try link.query.validate(Shared.tokenId, Shared.networkId, Shared.promoCode)

        userWalletId = link.query.unchecked(Shared.userWalletId)
    }
}

// MARK: - Navigation

extension SellDeeplink {
    @MainActor
    func findUserWalletModel() -> (any UserWalletModel)? {
        DeeplinkWalletModelLocator().findUserWalletModel(userWalletModelId: userWalletId, requiring: .multiCurrency)
    }
}
