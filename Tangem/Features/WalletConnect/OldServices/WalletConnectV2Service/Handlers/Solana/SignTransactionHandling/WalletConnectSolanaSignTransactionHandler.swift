//
//  WalletConnectSolanaSignTransactionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

final class WalletConnectSolanaSignTransactionHandler {
    private let walletModel: any WalletModel
    private let signer: WalletConnectSigner
    private let transaction: String
    private let request: AnyCodable
    private let encoder = JSONEncoder()

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: WalletConnectSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws {
        let parameters = try request.get(WalletConnectSolanaSignTransactionDTO.Response.self)

        do {
            guard let walletModel = walletModelProvider.getModel(with: blockchainId) else {
                throw WalletConnectV2Error.walletModelNotFound(blockchainId)
            }

            self.walletModel = walletModel
            transaction = parameters.transaction
        } catch {
            let stringRepresentation = request.stringRepresentation
            WCLogger.error("Failed to create sign handler", error: error)
            throw WalletConnectV2Error.dataInWrongFormat(stringRepresentation)
        }

        self.signer = signer
        self.request = request
    }

    /// Remove signatures placeholder from raw transaction
    func prepareTransactionToSign() throws -> Data {
        let data = try Data(transaction.base64Decoded())
        return try SolanaTransactionHelper().removeSignaturesPlaceholders(from: data)
    }
}

extension WalletConnectSolanaSignTransactionHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .solanaSignTransaction }

    var requestData: Data {
        (try? encoder.encode([transaction])) ?? Data()
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    var event: WalletConnectEvent { .sign }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        return transaction
    }

    func handle() async throws -> RPCResult {
        let unsignedHash = try prepareTransactionToSign()
        let signedHash = try await signer.sign(data: unsignedHash, using: walletModel)

        return .response(
            AnyCodable(WalletConnectSolanaSignTransactionDTO.Body(signature: signedHash.base58EncodedString))
        )
    }
}
