//
//  BuyDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://buy[?user_wallet_id]`
struct BuyDeeplink: HostNamedDeeplink, Equatable {
    static let host = "buy"

    let userWalletId: String?

    var action: DeeplinkNavigationAction { .buy(self) }
}

// MARK: - Parsing

extension BuyDeeplink {
    init(link: DeeplinkURL) throws {
        try link.query.validate(Shared.tokenId, Shared.networkId, Shared.promoCode)

        userWalletId = link.query.unchecked(Shared.userWalletId)
    }
}

// MARK: - Navigation

extension BuyDeeplink {
    @MainActor
    func findUserWalletModel() -> (any UserWalletModel)? {
        DeeplinkWalletModelLocator().findUserWalletModel(userWalletModelId: userWalletId, requiring: .multiCurrency)
    }
}
