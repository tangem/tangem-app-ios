//
//  TangemPayAccountDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://pay-account[?screen&user_wallet_id]`
///
/// An unknown `screen` is left to the routing layer, which falls back to the account's main screen.
struct TangemPayAccountDeeplink: HostNamedDeeplink, Equatable {
    static let host = "pay-account"

    let screen: String?
    let userWalletId: String?

    var action: DeeplinkNavigationAction { .tangemPayAccount(self) }
}

// MARK: - Parsing

extension TangemPayAccountDeeplink {
    private enum Keys {
        static let screen = "screen"
    }

    init(link: DeeplinkURL) throws {
        screen = try link.query.optional(Keys.screen, lowercased: true)
        userWalletId = try link.query.optional(Shared.userWalletId)
    }
}

// MARK: - Navigation

extension TangemPayAccountDeeplink {
    @MainActor
    func findUserWalletModel() -> (any UserWalletModel)? {
        DeeplinkWalletModelLocator().findUserWalletModel(userWalletModelId: userWalletId)
    }

    var openingAction: TangemPayOpeningAction? {
        screen.flatMap { TangemPayOpeningAction(rawValue: $0) }
    }
}
