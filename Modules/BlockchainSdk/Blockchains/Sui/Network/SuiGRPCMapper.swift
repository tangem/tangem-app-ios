//
//  SuiGRPCMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftProtobuf
import TangemFoundation

struct SuiGRPCMapper {
    // MARK: - Requests

    func makeListCoinsRequest(address: String, cursor: String?) throws -> Sui_Rpc_V2_ListOwnedObjectsRequest {
        var request = Sui_Rpc_V2_ListOwnedObjectsRequest()
        request.owner = address
        request.pageSize = Constants.pageSize
        request.objectType = Constants.coinObjectType
        request.readMask = .init(protoPaths: ["object_id", "version", "digest", "object_type", "balance", "previous_transaction"])

        if let cursor {
            request.pageToken = try decodeBase64(cursor)
        }

        return request
    }

    func makeGetEpochRequest() -> Sui_Rpc_V2_GetEpochRequest {
        var request = Sui_Rpc_V2_GetEpochRequest()
        request.readMask = .init(protoPaths: ["reference_gas_price"])
        return request
    }

    func makeSimulateTransactionRequest(transaction: String) throws -> Sui_Rpc_V2_SimulateTransactionRequest {
        var request = Sui_Rpc_V2_SimulateTransactionRequest()
        request.transaction = try makeTransaction(bytes: transaction)
        request.readMask = .init(protoPaths: [
            "transaction.effects.status",
            "transaction.effects.gas_used",
            "transaction.transaction.gas_payment.price",
        ])
        return request
    }

    func makeExecuteTransactionRequest(transaction: String, signature: String) throws -> Sui_Rpc_V2_ExecuteTransactionRequest {
        var userSignature = Sui_Rpc_V2_UserSignature()
        userSignature.bcs.value = try decodeBase64(signature)

        var request = Sui_Rpc_V2_ExecuteTransactionRequest()
        request.transaction = try makeTransaction(bytes: transaction)
        request.signatures = [userSignature]
        request.readMask = .init(protoPaths: ["digest"])
        return request
    }

    // MARK: - Responses

    func mapToCoins(response: Sui_Rpc_V2_ListOwnedObjectsResponse) throws -> SuiGetCoins {
        let coins = try response.objects.compactMap(mapToCoin(object:))
        let nextPageToken = response.nextPageToken

        return SuiGetCoins(
            hasNextPage: !nextPageToken.isEmpty,
            data: coins,
            nextCursor: nextPageToken.isEmpty ? nil : nextPageToken.base64EncodedString()
        )
    }

    func mapToReferenceGasPrice(response: Sui_Rpc_V2_GetEpochResponse) throws -> SuiReferenceGasPrice {
        guard response.epoch.hasReferenceGasPrice else {
            throw BlockchainSdkError.failedToParseNetworkResponse()
        }

        return String(response.epoch.referenceGasPrice)
    }

    func mapToInspectTransaction(response: Sui_Rpc_V2_SimulateTransactionResponse) throws -> SuiInspectTransaction {
        let executed = response.transaction

        guard
            executed.hasEffects,
            executed.effects.hasGasUsed,
            executed.transaction.gasPayment.hasPrice
        else {
            throw BlockchainSdkError.failedToParseNetworkResponse()
        }

        let gasUsed = executed.effects.gasUsed

        return SuiInspectTransaction(
            effects: SuiTransaction.SuiTransactionEffects(
                status: mapToStatus(executed.effects),
                gasUsed: SuiTransaction.SuiTransactionGasUsed(
                    computationCost: String(gasUsed.computationCost),
                    storageCost: String(gasUsed.storageCost),
                    storageRebate: String(gasUsed.storageRebate),
                    nonRefundableStorageFee: String(gasUsed.nonRefundableStorageFee)
                )
            ),
            input: SuiTransaction.SuiTransactionData(
                gasData: SuiTransaction.GasData(price: String(executed.transaction.gasPayment.price))
            )
        )
    }

    func mapToExecuteTransaction(response: Sui_Rpc_V2_ExecuteTransactionResponse) throws -> SuiExecuteTransaction {
        let executed = response.transaction

        guard executed.hasDigest, !executed.digest.isEmpty else {
            throw BlockchainSdkError.failedToParseNetworkResponse()
        }

        return SuiExecuteTransaction(digest: executed.digest)
    }

    func normalizeCoinType(_ coinType: String) -> String {
        let elements = coinType.components(separatedBy: Constants.typeSeparator)
        let sui = SuiCoinObject.CoinType.sui

        guard elements.count == 3, elements[1] == sui.lowerID, elements[2] == sui.upperID else {
            return coinType
        }

        let address = elements[0].removeHexPrefix().drop { $0 == "0" }
        let suiAddress = sui.contract.removeHexPrefix()

        return address == suiAddress ? sui.string : coinType
    }

    // MARK: - Private

    private func mapToCoin(object: Sui_Rpc_V2_Object) throws -> SuiGetCoins.Coin? {
        guard object.hasObjectID, object.hasVersion, object.hasDigest, object.hasObjectType, object.hasBalance else {
            throw BlockchainSdkError.failedToParseNetworkResponse()
        }

        guard let coinType = extractCoinType(objectType: object.objectType) else {
            return nil
        }

        return SuiGetCoins.Coin(
            coinType: normalizeCoinType(coinType),
            coinObjectId: object.objectID,
            version: String(object.version),
            digest: object.digest,
            balance: String(object.balance),
            previousTransaction: object.previousTransaction
        )
    }

    private func extractCoinType(objectType: String) -> String? {
        guard
            let start = objectType.firstIndex(of: "<"),
            objectType.hasSuffix(">")
        else {
            return nil
        }

        let coinType = objectType[objectType.index(after: start) ..< objectType.index(before: objectType.endIndex)]
        return coinType.isEmpty ? nil : String(coinType)
    }

    private func mapToStatus(_ effects: Sui_Rpc_V2_TransactionEffects) -> SuiTransaction.SuiTransactionEffects.Status {
        let isSuccess = effects.hasStatus && effects.status.success
        return .init(status: isSuccess ? Constants.successStatus : Constants.failureStatus)
    }

    private func makeTransaction(bytes: String) throws -> Sui_Rpc_V2_Transaction {
        var transaction = Sui_Rpc_V2_Transaction()
        transaction.bcs.value = try decodeBase64(bytes)
        return transaction
    }

    private func decodeBase64(_ string: String) throws -> Data {
        guard let data = Data(base64Encoded: string), !data.isEmpty else {
            throw BlockchainSdkError.failedToBuildTx
        }

        return data
    }
}

// MARK: - Constants

private extension SuiGRPCMapper {
    enum Constants {
        static let pageSize: UInt32 = 1000
        static let coinObjectType = "0x2::coin::Coin"
        static let typeSeparator = "::"
        static let successStatus = "success"
        static let failureStatus = "failure"
    }
}
