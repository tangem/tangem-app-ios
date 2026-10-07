//
//  CollectiblesAPIService+Purchase.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesAPIService {
    func generatePurchase(
        machineID: String,
        fromAddress: String,
        toAddress: String,
        turboMode: CollectiblesTurboMode,
        userWalletID: String
    ) async throws -> CollectiblesGeneratedPurchase {
        let generateRequest = CollectiblesDTO.GeneratePurchaseTxRequest(
            fromAddress: fromAddress,
            machineID: machineID,
            toAddress: toAddress,
            turboMode: Mapper.mapToTurboMode(turboMode)
        )
        let response: CollectiblesDTO.GeneratePurchaseTxResponse = try await request(
            .generatePurchaseTx(generateRequest, userWalletID: userWalletID)
        )

        return try Mapper.mapToGeneratedPurchase(response)
    }

    func reportPurchaseSent(
        txID: String,
        txHash: String,
        userWalletID: String
    ) async throws -> CollectiblesPurchaseStatus {
        let sentRequest = CollectiblesDTO.PurchaseTxSentRequest(txID: txID, txHash: txHash)
        let transaction: CollectiblesDTO.PurchaseTransaction = try await request(
            .purchaseTxSent(sentRequest, userWalletID: userWalletID)
        )

        return Mapper.mapToPurchaseStatus(transaction)
    }

    func loadPurchaseStatus(txID: String, userWalletID: String) async throws -> CollectiblesPurchaseStatus {
        let transaction: CollectiblesDTO.PurchaseTransaction = try await request(
            .purchaseStatus(.init(txID: txID), userWalletID: userWalletID)
        )

        return Mapper.mapToPurchaseStatus(transaction)
    }

    func openPack(txID: String, userWalletID: String) async throws -> CollectiblesPurchaseStatus {
        let transaction: CollectiblesDTO.PurchaseTransaction = try await request(
            .openPack(.init(txID: txID), userWalletID: userWalletID)
        )

        return Mapper.mapToPurchaseStatus(transaction)
    }
}
