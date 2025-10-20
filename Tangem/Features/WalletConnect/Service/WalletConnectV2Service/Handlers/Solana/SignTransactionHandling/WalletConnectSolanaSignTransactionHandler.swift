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
    private let hardwareLimitationsUtil: HardwareLimitationsUtil
    private let walletNetworkServiceFactory: WalletNetworkServiceFactory
    private let analyticsProvider: WalletConnectServiceAnalyticsProvider
    private let transaction: String
    private let request: AnyCodable
    private let encoder = JSONEncoder()

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: TangemSigner,
        hardwareLimitationsUtil: HardwareLimitationsUtil,
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
        self.hardwareLimitationsUtil = hardwareLimitationsUtil
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
        let transactionData = try Data(transaction.base64Decoded())
        let withoutSignaturePlaceholders = try SolanaTransactionHelper().removeSignaturesPlaceholders(from: transactionData)
        let unsignedHash = withoutSignaturePlaceholders.transaction

        guard FeatureProvider.isAvailable(.wcSolanaALT) else {
            return try await handleDefaultTransaction(unsignedHash: unsignedHash)
        }

        let canHandleTransaction = (try? hardwareLimitationsUtil.canHandleTransaction(
            walletModel.tokenItem,
            transaction: transactionData
        )) ?? true

        if canHandleTransaction {
            return try await handleDefaultTransaction(unsignedHash: unsignedHash)
        } else {
            let signatureCount = withoutSignaturePlaceholders.signatureCount
            return try await handleLongTransaction(unsignedHash: unsignedHash, signatureCount: signatureCount)
        }
    }
}

private extension WalletConnectSolanaSignTransactionHandler {
    func handleDefaultTransaction(unsignedHash: Data) async throws -> RPCResult {
        let solanaSigner = SolanaWalletConnectSigner(signer: signer)
        let signedHash = try await solanaSigner.sign(data: unsignedHash, using: walletModel)

        return .response(
            AnyCodable(WalletConnectSolanaSignTransactionDTO.Body(signature: signedHash.base58EncodedString))
        )
    }

    func handleLongTransaction(unsignedHash: Data, signatureCount: Int) async throws -> RPCResult {
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

        let altResult: Bool

        do {
            try await transactionService.send(transactionData: unsignedHash)
            altResult = true
        } catch {
            altResult = false
        }

        analyticsProvider.logCompleteHandleSolanaALTTransactionRequest(isSuccess: altResult)

        throw WalletConnectTransactionRequestProcessingError.invalidPayload("Solana ALT handling error for request: \(request.description)")
    }
}
