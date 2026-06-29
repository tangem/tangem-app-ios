//
//  PriceAlertsSubscriptionsDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PriceAlertsSubscriptionsDTO {
    /// Shared body for `POST` (subscribe) and `DELETE` (unsubscribe): the wallets to (un)subscribe and the coin.
    struct Request: Encodable {
        let walletIds: [String]
        let tokenId: String
    }

    /// `POST` returns `{ "status": "subscribed" }`, `DELETE` returns `{ "status": "removed" }`.
    /// Decoded and discarded — the client only cares about the `200` outcome.
    struct StatusResponse: Decodable {
        let status: String
    }

    /// `GET` returns the list of `tokenId` the wallet is subscribed to.
    struct List: Decodable {
        let tokenIds: [String]
    }
}
