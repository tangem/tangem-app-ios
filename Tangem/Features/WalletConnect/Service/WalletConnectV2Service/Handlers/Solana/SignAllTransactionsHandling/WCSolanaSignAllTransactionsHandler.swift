//
//  WCSolanaSignAllTransactionsHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

final class WCSolanaSignAllTransactionsHandler {
    private let walletModel: any WalletModel
    private let signer: WalletConnectSigner
    private let hashesToSign: [String]
    private let request: AnyCodable
    private let encoder = JSONEncoder()

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: WalletConnectSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws(WalletConnectTransactionRequestProcessingError) {
        do {
            let parameters = try request.get(WCSolanaSignAllTransactionsDTO.Response.self)

            guard let walletModel = walletModelProvider.getModel(with: blockchainId) else {
                throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
            }

            self.walletModel = walletModel
            hashesToSign = parameters.transactions
        } catch {
            let stringRepresentation = request.stringRepresentation
            WCLogger.info("[WC 2.0] Failed to create sign handler. Raised error: \(error)")
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(stringRepresentation)
        }

        self.signer = signer
        self.request = request
    }

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: WalletConnectSigner,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws(WalletConnectTransactionRequestProcessingError) {
        do {
            let parameters = try request.get(WCSolanaSignAllTransactionsDTO.Response.self)

            guard
                let walletModel = wcAccountsWalletModelProvider.getModel(with: blockchainId, accountId: accountId)
            else {
                throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
            }

            self.walletModel = walletModel
            hashesToSign = parameters.transactions
        } catch {
            let stringRepresentation = request.stringRepresentation
            WCLogger.info("[WC 2.0] Failed to create sign handler. Raised error: \(error)")
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(stringRepresentation)
        }

        self.signer = signer
        self.request = request
    }

    private func prepareTransactionToSign(hash: String) throws -> Data {
        let data = try Data(hash.base64Decoded())
        let (signature, _) = try SolanaTransactionHelper().removeSignaturesPlaceholders(from: data)
        return signature
    }
}

extension WCSolanaSignAllTransactionsHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .solanaSignAllTransactions }

    var requestData: Data {
        (try? encoder.encode(hashesToSign.map(prepareTransactionToSign(hash:)))) ?? Data()
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        .empty
    }

    func handle() async throws -> RPCResult {
        let transactionsToSign: [Data] = try hashesToSign.map { try prepareTransactionToSign(hash: $0) }

        let transactionsToRespond: [String] = try await signer.sign(hashes: transactionsToSign, using: walletModel)
            .enumerated()
            .map { index, signedTransaction in
                let assembledResponseTransaction = Data(1) + signedTransaction + transactionsToSign[index]
                return assembledResponseTransaction.base64EncodedString()
            }

        let responseBody = WCSolanaSignAllTransactionsDTO.Body(transactions: transactionsToRespond)
        return .response(AnyCodable(responseBody))
    }
}
