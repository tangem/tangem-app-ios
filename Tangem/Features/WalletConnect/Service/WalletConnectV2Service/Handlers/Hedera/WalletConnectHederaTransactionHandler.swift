//
//  WalletConnectHederaTransactionHandler.swift
//  Tangem
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

/// `hedera_signAndExecuteTransaction` and `hedera_signTransaction` (HIP-820).
///
/// The bytes the dApp sends are decoded by the Hiero SDK inside BlockchainSdk (which also enforces that all
/// chunks of a `TransactionList` differ only in the node account id); the request details are built from that
/// decoded transaction, and the same bytes are what gets signed.
struct WalletConnectHederaTransactionHandler {
    enum Mode {
        /// `transactionList` → sign every chunk, submit, return node / hash / id.
        case signAndExecute
        /// `transactionBody` → return a `SignatureMap`, nothing is submitted.
        case signOnly

        var method: WalletConnectMethod {
            switch self {
            case .signAndExecute: .hederaSignAndExecuteTransaction
            case .signOnly: .hederaSignTransaction
            }
        }
    }

    private let mode: Mode
    private let request: AnyCodable
    private let transactionBytes: Data
    private let details: WalletConnectHederaTransactionDetails
    private let processor: HederaExternalTransactionProcessor
    private let signer: TransactionSigner

    init(
        mode: Mode,
        request: AnyCodable,
        blockchainId: String,
        signer: TransactionSigner,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        let params: WalletConnectHederaTransactionDTO.Request
        let walletModel: any WalletModel
        let signerAccount: WalletConnectHederaRequestParser.SignerAccountId

        do {
            params = try request.get(WalletConnectHederaTransactionDTO.Request.self)
            signerAccount = try WalletConnectHederaRequestParser.parseSignerAccountId(params.signerAccountId)
            walletModel = try wcAccountsWalletModelProvider.getModel(
                with: signerAccount.accountId,
                blockchainId: blockchainId,
                accountId: accountId
            )
        } catch {
            WCLogger.error("Failed to create Hedera transaction handler", error: error)
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(request.stringRepresentation)
        }

        guard let processor = walletModel.hederaExternalTransactionProcessor else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(WalletConnectHederaRequestError.processorUnavailable.localizedDescription)
        }

        do {
            try WalletConnectHederaRequestParser.validateSigner(
                signerAccount,
                accountId: walletModel.defaultAddressString,
                blockchain: walletModel.tokenItem.blockchain
            )

            let summary: HederaExternalTransactionSummary
            switch mode {
            case .signAndExecute:
                guard let list = params.transactionList else {
                    throw WalletConnectHederaRequestError.invalidBase64("transactionList")
                }
                transactionBytes = try WalletConnectHederaRequestParser.decodeTransactionBytes(list, field: "transactionList")
                summary = try processor.parseTransactionList(transactionBytes)
            case .signOnly:
                guard let body = params.transactionBody else {
                    throw WalletConnectHederaRequestError.invalidBase64("transactionBody")
                }
                transactionBytes = try WalletConnectHederaRequestParser.decodeTransactionBytes(body, field: "transactionBody")
                summary = try processor.parseTransactionList(HederaProtobufCodec.transaction(wrappingBody: transactionBytes))
            }
            details = WalletConnectHederaTransactionDetails(summary)
        } catch {
            WCLogger.error("Rejected Hedera transaction", error: error)
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(error.localizedDescription)
        }

        self.mode = mode
        self.request = request
        self.processor = processor
        self.signer = signer
    }
}

extension WalletConnectHederaTransactionHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { mode.method }

    var requestData: Data {
        (try? JSONEncoder().encode(details)) ?? Data()
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        .empty
    }

    func handle() async throws -> RPCResult {
        do {
            switch mode {
            case .signAndExecute:
                let result = try await processor.signAndExecute(transactionList: transactionBytes, signer: signer)
                let response = WalletConnectHederaTransactionDTO.ExecuteResponse(
                    nodeId: result.nodeId,
                    transactionHash: result.transactionHash,
                    transactionId: result.transactionId
                )
                return .response(AnyCodable(response))
            case .signOnly:
                let signatureMap = try await processor.sign(transactionBody: transactionBytes, signer: signer)
                return .response(AnyCodable(WalletConnectHederaTransactionDTO.SignatureMapResponse(signatureMap: signatureMap.base64EncodedString())))
            }
        } catch {
            WCLogger.error("Failed to process Hedera transaction", error: error)
            throw error
        }
    }
}

enum WalletConnectHederaTransactionDTO {
    struct Request: Codable {
        let signerAccountId: String
        let transactionList: String?
        let transactionBody: String?
    }

    struct ExecuteResponse: Codable {
        let nodeId: String
        let transactionHash: String
        let transactionId: String
    }

    struct SignatureMapResponse: Codable {
        let signatureMap: String
    }
}
