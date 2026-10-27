//
//  CommonCollectiblesPurchaseProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CommonCollectiblesPurchaseProvider {
    private let userWalletID: String
    private let service: CollectiblesAPIService

    init(userWalletID: String, service: CollectiblesAPIService = CollectiblesAPIService()) {
        self.userWalletID = userWalletID
        self.service = service
    }
}

// MARK: - CollectiblesPurchaseGenerator protocol conformance

extension CommonCollectiblesPurchaseProvider: CollectiblesPurchaseGenerator {
    func generate(
        machineID: String,
        fromAddress: String,
        toAddress: String,
        turboMode: CollectiblesTurboMode
    ) async throws -> CollectiblesGeneratedPurchase {
        try await service.generatePurchase(
            machineID: machineID,
            fromAddress: fromAddress,
            toAddress: toAddress,
            turboMode: turboMode,
            userWalletID: userWalletID
        )
    }
}

// MARK: - CollectiblesPurchaseSentReporter protocol conformance

extension CommonCollectiblesPurchaseProvider: CollectiblesPurchaseSentReporter {
    func report(txID: String, txHash: String) async throws -> CollectiblesPurchaseStatus {
        try await service.reportPurchaseSent(txID: txID, txHash: txHash, userWalletID: userWalletID)
    }
}

// MARK: - CollectiblesPurchaseStatusProvider protocol conformance

extension CommonCollectiblesPurchaseProvider: CollectiblesPurchaseStatusProvider {
    func load(txID: String) async throws -> CollectiblesPurchaseTransaction {
        try await service.loadPurchaseStatus(txID: txID, userWalletID: userWalletID)
    }
}

// MARK: - CollectiblesPackOpener protocol conformance

extension CommonCollectiblesPurchaseProvider: CollectiblesPackOpener {
    func open(txID: String) async throws -> CollectiblesPurchaseTransaction {
        try await service.openPack(txID: txID, userWalletID: userWalletID)
    }
}
