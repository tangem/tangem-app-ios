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
    private let walletModel: WalletModel
    private let signer: WalletConnectSigner
    private let hashesToSign: [String]

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: WalletConnectSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws {
        let parameters = try request.get(WCSolanaSignAllTransactionsDTO.Response.self)

        do {
            guard let walletModel = walletModelProvider.getModel(with: blockchainId) else {
                throw WalletConnectV2Error.walletModelNotFound(blockchainId)
            }

            self.walletModel = walletModel
            hashesToSign = parameters.transactions
        } catch {
            let stringRepresentation = request.stringRepresentation
            WCLogger.info("[WC 2.0] Failed to create sign handler. Raised error: \(error)")
            throw WalletConnectV2Error.dataInWrongFormat(stringRepresentation)
        }

        self.signer = signer
    }

    /// Remove signature placeholder from raw transaction
    func prepareTransactionToSign(hash: String) throws -> Data {
        try Data(hash.base64Decoded()).dropFirst(Constants.signaturePlaceholderPrefixLength)
    }
}

extension WCSolanaSignAllTransactionsHandler: WalletConnectMessageHandler {
    var event: WalletConnectEvent { .sign }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        return hashesToSign.reduce("", +)
    }

    func handle() async throws -> RPCResult {
        let signedHashes = try await signer.sign(
            hashes: hashesToSign.map { try prepareTransactionToSign(hash: $0) },
            using: walletModel
        )

        let preparedToSendHashes: [String] = try hashesToSign.enumerated().map { index, hashToSign in
            let hashToSignData = try prepareTransactionToSign(hash: hashToSign)
            let data = Data(1) + signedHashes[index] + hashToSignData
            return data.base64EncodedString()
        }

        return .response(AnyCodable(WCSolanaSignAllTransactionsDTO.Body(transactions: preparedToSendHashes)))
    }
}

private enum Constants {
    static let signaturePlaceholderPrefixLength = 65
}
