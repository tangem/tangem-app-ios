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
    private let signer: TangemSigner
    private let walletNetworkServiceFactory: WalletNetworkServiceFactory
    private let transaction: String
    private let request: AnyCodable
    private let encoder = JSONEncoder()

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: TangemSigner,
        walletNetworkServiceFactory: WalletNetworkServiceFactory,
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
        self.walletNetworkServiceFactory = walletNetworkServiceFactory
        self.request = request
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

    /// Remove signatures placeholder from raw transaction
    func prepareTransactionToSign(_ transaction: String) throws -> (Data, Int) {
        let data = try Data(transaction.base64Decoded())
        return try SolanaTransactionHelper().removeSignaturesPlaceholders(from: data)
    }

    func handle() async throws -> RPCResult {
        let (unsignedHash, signatureCount) = try prepareTransactionToSign(transaction)

        guard FeatureProvider.isAvailable(.wcSolanaALT) else {
            return try await defaultHandleTransaction(unsignedHash: unsignedHash)
        }

        switch SolanaWalletConnectTransactionRely.rely(transaction: unsignedHash) {
        case .default:
            return try await defaultHandleTransaction(unsignedHash: unsignedHash)
        case .alt:
            guard signatureCount == 1 else {
                throw WalletConnectV2Error.dataInWrongFormat("Signature count > 1")
            }

            let transactionService = try SolanaALTTransactionService(
                blockchain: walletModel.tokenItem.blockchain,
                walletPublicKey: walletModel.publicKey,
                walletNetworkServiceFactory: walletNetworkServiceFactory,
                signer: signer
            )

            try await transactionService.send(transactionData: unsignedHash)

            throw WalletConnectV2Error.missingTransaction
        }
    }
}

private extension WalletConnectSolanaSignTransactionHandler {
    func defaultHandleTransaction(unsignedHash: Data) async throws -> RPCResult {
        let solanaSigner = SolanaWalletConnectSigner(signer: signer)
        let signedHash = try await solanaSigner.sign(data: unsignedHash, using: walletModel)

        return .response(
            AnyCodable(WalletConnectSolanaSignTransactionDTO.Body(signature: signedHash.base58EncodedString))
        )
    }
}
