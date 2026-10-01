//
//  CommonCollectiblesPrizePoolProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CommonCollectiblesPrizePoolProvider {
    private let userWalletID: String
    private let service: CollectiblesAPIService

    init(userWalletID: String, service: CollectiblesAPIService = CollectiblesAPIService()) {
        self.userWalletID = userWalletID
        self.service = service
    }
}

// MARK: - CollectiblesPrizePoolProvider protocol conformance

extension CommonCollectiblesPrizePoolProvider: CollectiblesPrizePoolProvider {
    func load(machineID: String, page: Int) async throws -> CollectiblesPrizePoolPage {
        try await service.loadPrizePool(machineID: machineID, page: page, userWalletID: userWalletID)
    }
}
