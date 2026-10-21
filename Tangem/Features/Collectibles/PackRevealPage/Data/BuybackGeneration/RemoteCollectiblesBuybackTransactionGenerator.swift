//
//  RemoteCollectiblesBuybackTransactionGenerator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct RemoteCollectiblesBuybackTransactionGenerator: CollectiblesBuybackTransactionGenerator {
    private let userWalletID: String
    private let requester: any CollectiblesAPIRequesting

    init(userWalletID: String, requester: any CollectiblesAPIRequesting) {
        self.userWalletID = userWalletID
        self.requester = requester
    }

    func generate(
        nftAddress: String,
        fromAddress: String,
        toAddress: String
    ) async throws -> CollectiblesBuybackTransaction {
        let request = CollectiblesDTO.GenerateBuybackDataRequest(
            fromAddress: fromAddress,
            nftAddress: nftAddress,
            toAddress: toAddress
        )
        let response: CollectiblesDTO.GenerateBuybackDataResponse = try await requester.request(
            .generateBuybackData(request, userWalletID: userWalletID)
        )

        return try Mapper.mapToTransaction(response)
    }
}
