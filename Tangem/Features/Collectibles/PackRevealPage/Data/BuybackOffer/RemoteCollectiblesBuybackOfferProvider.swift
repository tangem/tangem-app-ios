//
//  RemoteCollectiblesBuybackOfferProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct RemoteCollectiblesBuybackOfferProvider: CollectiblesBuybackOfferProvider {
    private let userWalletID: String
    private let requester: any CollectiblesAPIRequesting

    init(userWalletID: String, requester: any CollectiblesAPIRequesting) {
        self.userWalletID = userWalletID
        self.requester = requester
    }

    func load(nftAddress: String) async throws -> CollectiblesBuybackOffer? {
        let response: CollectiblesDTO.BuybackAvailabilityResponse = try await requester.request(
            .buybackAvailability(.init(nftAddress: nftAddress), userWalletID: userWalletID)
        )

        return try Mapper.mapToOffer(response)
    }
}
