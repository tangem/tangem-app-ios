//
//  RemoteCollectiblesBuybackSentReporter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct RemoteCollectiblesBuybackSentReporter: CollectiblesBuybackSentReporter {
    private let userWalletID: String
    private let requester: any CollectiblesAPIRequesting

    init(userWalletID: String, requester: any CollectiblesAPIRequesting) {
        self.userWalletID = userWalletID
        self.requester = requester
    }

    func report(buybackID: String, txHash: String) async throws {
        let request = CollectiblesDTO.BuybackTxSentRequest(buybackID: buybackID, txHash: txHash)
        let _: CollectiblesDTO.BuybackStatusResponse = try await requester.request(
            .buybackTxSent(request, userWalletID: userWalletID)
        )
    }
}
