//
//  PriceAlertsSubscriptionsDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PriceAlertsSubscriptionsDTO {
    /// Shared body for `POST` (subscribe) and `DELETE` (unsubscribe): the user wallets to (un)subscribe and the coin.
    struct Request: Encodable {
        let userWalletIds: [String]
        let tokenId: String

        private enum CodingKeys: String, CodingKey {
            // Values are UserWalletIds (SHA-256 hex, lowercase). The wire key stays `walletIds` to match the
            // backend contract, mirroring notification-preferences (Swift `userWalletId`, wire `walletId`).
            case userWalletIds = "walletIds"
            case tokenId
        }
    }

    /// `POST` returns `{ "status": "subscribed" }`, `DELETE` returns `{ "status": "removed" }`.
    /// Decoded and discarded — the client only cares about the `200` outcome.
    struct StatusResponse: Decodable {
        let status: String
    }

    /// `GET` returns the list of `tokenId` values the wallet is subscribed to.
    struct List: Decodable {
        let tokenIds: [String]
    }
}
