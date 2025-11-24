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

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: TangemSigner,
        hardwareLimitationsUtil: HardwareLimitationsUtil,
        walletNetworkServiceFactory: WalletNetworkServiceFactory,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String,
        analyticsProvider: WalletConnectServiceAnalyticsProvider
    ) throws {
        let parameters = try request.get(WalletConnectSolanaSignTransactionDTO.Response.self)

        do {
            guard
                let walletModel = wcAccountsWalletModelProvider.getModel(with: blockchainId, accountId: accountId)
            else {
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

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        let (canHandleTransaction, _, _) = try prepareTransaction()

        if canHandleTransaction {
            return .empty
        } else {
            return .multipleTransactions
        }
    }

    func handle() async throws -> RPCResult {
        let (canHandleTransaction, unsignedHash, signatureCount) = try prepareTransaction()

        if canHandleTransaction {
            return try await handleDefaultTransaction(unsignedHash: unsignedHash)
        } else {
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

        // [REDACTED_USERNAME], this error is handled in UI gracefully. Normal ALT flow.
        throw WalletConnectTransactionRequestProcessingError.eraseMultipleTransactions
    }

    func prepareTransaction() throws -> (
        canHandleTransaction: Bool,
        unsignedHash: Data,
        signatureCount: Int
    ) {
        let transactionData = try Data(transaction.base64Decoded())
        let withoutSignaturePlaceholders = try SolanaTransactionHelper().removeSignaturesPlaceholders(from: transactionData)
        let unsignedHash = withoutSignaturePlaceholders.transaction

        guard FeatureProvider.isAvailable(.wcSolanaALT) else {
            return (true, unsignedHash, withoutSignaturePlaceholders.signatureCount)
        }

        let canHandleTransaction = (try? hardwareLimitationsUtil.canHandleTransaction(
            walletModel.tokenItem,
            transaction: transactionData
        )) ?? true

        return (canHandleTransaction, unsignedHash, withoutSignaturePlaceholders.signatureCount)
    }
}
