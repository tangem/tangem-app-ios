//
//  RemoteCollectiblesBuybackStatusProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct RemoteCollectiblesBuybackStatusProvider: CollectiblesBuybackStatusProvider {
    private let userWalletID: String
    private let requester: any CollectiblesAPIRequesting

    init(userWalletID: String, requester: any CollectiblesAPIRequesting) {
        self.userWalletID = userWalletID
        self.requester = requester
    }

    func load(buybackID: String) async throws -> CollectiblesBuybackStatus {
        let response: CollectiblesDTO.BuybackStatusResponse = try await requester.request(
            .buybackStatus(.init(buybackID: buybackID), userWalletID: userWalletID)
        )

        return Mapper.mapToStatus(response)
    }
}
