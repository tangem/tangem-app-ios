//
//  RemotePriceAlertsSubscriptions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

typealias PriceAlertTokenId = String

struct RemotePriceAlertsSubscriptions: Equatable {
    private(set) var state: PushRemoteValueState<Set<PriceAlertTokenId>>

    init(state: PushRemoteValueState<Set<PriceAlertTokenId>> = .loading) {
        self.state = state
    }

    init(tokenIds: [PriceAlertTokenId]) {
        self.init(state: .ready(Set(tokenIds)))
    }

    static var loading: RemotePriceAlertsSubscriptions {
        RemotePriceAlertsSubscriptions(state: .loading)
    }

    var tokenIds: Set<PriceAlertTokenId> {
        guard case .ready(let tokenIds) = state else {
            return []
        }

        return tokenIds
    }

    func isSubscribed(tokenId: PriceAlertTokenId) -> Bool {
        tokenIds.contains(tokenId)
    }

    mutating func setSubscribed(_ isSubscribed: Bool, tokenId: PriceAlertTokenId) {
        var tokenIds = tokenIds
        if isSubscribed {
            tokenIds.insert(tokenId)
        } else {
            tokenIds.remove(tokenId)
        }
        state = .ready(tokenIds)
    }
}
