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
        let response: CollectiblesDTO.GeneratePurchaseTxResponse

        do {
            response = try await request(.generatePurchaseTx(generateRequest, userWalletID: userWalletID))
        } catch Error.http(_, let body) where Mapper.mapToErrorCode(body) == ErrorCode.lowInventory {
            throw CollectiblesPurchaseGenerationError.lowInventory
        }

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

        return Mapper.mapToPurchaseStatus(transaction.status)
    }

    func loadPurchaseStatus(
        txID: String,
        includesAutoBuyback: Bool,
        userWalletID: String
    ) async throws -> CollectiblesPurchaseTransaction {
        let statusRequest = CollectiblesDTO.PurchaseTransactionRequest(
            txID: txID,
            includeNftWon: true,
            includeAutoBuyback: includesAutoBuyback
        )
        let transaction: CollectiblesDTO.PurchaseTransaction = try await request(
            .purchaseStatus(statusRequest, userWalletID: userWalletID)
        )

        return Mapper.mapToPurchaseTransaction(transaction)
    }

    func loadActivePurchases(userWalletID: String) async throws -> [CollectiblesPendingPurchase] {
        let response: CollectiblesDTO.ActiveTransactions = try await request(.activeTxs(userWalletID: userWalletID))

        return response.activeTxs.compactMap(Mapper.mapToPendingPurchase)
    }

    func openPack(
        txID: String,
        includesAutoBuyback: Bool,
        userWalletID: String
    ) async throws -> CollectiblesPurchaseTransaction {
        let transaction: CollectiblesDTO.PurchaseTransaction

        do {
            transaction = try await request(
                .openPack(.init(txID: txID), includesAutoBuyback: includesAutoBuyback, userWalletID: userWalletID)
            )
        } catch {
            guard let openingError = Self.openingError(from: error) else {
                throw error
            }

            throw openingError
        }

        return Mapper.mapToPurchaseTransaction(transaction)
    }
}

// MARK: - Error codes

private extension CollectiblesAPIService {
    enum ErrorCode {
        static let lowInventory = 3016
        static let packNotReady = 3009
        static let packOpeningFailed = 3010
        static let openingRefusals: Set<Int> = [packNotReady, packOpeningFailed]
    }

    enum ErrorDetail {
        static let spinNotFound = "No spin transaction found"
    }

    static func openingError(from error: any Swift.Error) -> CollectiblesPackOpeningError? {
        guard
            case Error.http(_, let body) = error,
            let response = Mapper.mapToErrorResponse(body),
            let code = response.code,
            ErrorCode.openingRefusals.contains(code)
        else {
            return nil
        }

        let isSpinNotFound = code == ErrorCode.packOpeningFailed && response.detail?.contains(ErrorDetail.spinNotFound) == true

        return isSpinNotFound ? .spinNotFound : .refused
    }
}
