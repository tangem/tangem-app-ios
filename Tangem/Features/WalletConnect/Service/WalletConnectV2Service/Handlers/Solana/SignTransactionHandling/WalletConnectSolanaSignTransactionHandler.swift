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
    private let analyticsProvider: WalletConnectServiceAnalyticsProvider
    private let transaction: String
    private let request: AnyCodable
    private let encoder = JSONEncoder()

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: TangemSigner,
        walletNetworkServiceFactory: WalletNetworkServiceFactory,
        walletModelProvider: WalletConnectWalletModelProvider,
        analyticsProvider: WalletConnectServiceAnalyticsProvider
    ) throws {
        let parameters = try request.get(WalletConnectSolanaSignTransactionDTO.Response.self)

        do {
            guard let walletModel = walletModelProvider.getModel(with: blockchainId) else {
                throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
            }

            self.walletModel = walletModel
            transaction = parameters.transaction
        } catch {
            let stringRepresentation = request.stringRepresentation
            WCLogger.error("Failed to create sign handler", error: error)
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(stringRepresentation)
        }

        self.signer = signer
        self.walletNetworkServiceFactory = walletNetworkServiceFactory
        self.analyticsProvider = analyticsProvider
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
                throw WalletConnectTransactionRequestProcessingError.invalidPayload("Signature count > 1")
            }

            analyticsProvider.logReceiveHandleSolanaALTTransactionRequest()

            let transactionService = try SolanaALTTransactionService(
                blockchain: walletModel.tokenItem.blockchain,
                walletPublicKey: walletModel.publicKey,
                walletNetworkServiceFactory: walletNetworkServiceFactory,
                signer: signer
            )

            do {
                try await transactionService.send(transactionData: unsignedHash)
            } catch {
                WCLogger.error("Failed to send solana_signTransaction", error: error)
                analyticsProvider.logCompleteHandleSolanaALTTransactionRequest(isSuccess: false)
                throw error
            }

            analyticsProvider.logCompleteHandleSolanaALTTransactionRequest(isSuccess: true)

            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Solana ALT handling error for request: \(request.description)")
        }
    }
}

private extension WalletConnectSolanaSignTransactionHandler {
    func prepareTransactionToSign(_ transaction: String) throws -> (Data, Int) {
        let data = try Data(transaction.base64Decoded())
        return try SolanaTransactionHelper().removeSignaturesPlaceholders(from: data)
    }

    func defaultHandleTransaction(unsignedHash: Data) async throws -> RPCResult {
        let solanaSigner = SolanaWalletConnectSigner(signer: signer)
        let signedHash = try await solanaSigner.sign(data: unsignedHash, using: walletModel)

        return .response(
            AnyCodable(WalletConnectSolanaSignTransactionDTO.Body(signature: signedHash.base58EncodedString))
        )
    }
}
