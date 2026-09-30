//
//  WalletConnectHederaSignMessageHandler.swift
//  Tangem
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

/// `hedera_signMessage` (HIP-820): signs `"\u{19}Hedera Signed Message:\n" ‖ len ‖ message` like a transaction
/// body and returns a base64 `SignatureMap`.
struct WalletConnectHederaSignMessageHandler {
    /// Upper bound on a message the wallet will show and sign.
    static let maxMessageByteCount = 64 * 1024

    private let request: AnyCodable
    private let message: String
    private let processor: HederaExternalTransactionProcessor
    private let signer: TransactionSigner

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: TransactionSigner,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        let params: WalletConnectHederaSignMessageDTO.Request
        let walletModel: any WalletModel
        let signerAccount: WalletConnectHederaRequestParser.SignerAccountId

        do {
            params = try request.get(WalletConnectHederaSignMessageDTO.Request.self)
            signerAccount = try WalletConnectHederaRequestParser.parseSignerAccountId(params.signerAccountId)
            walletModel = try wcAccountsWalletModelProvider.getModel(
                with: signerAccount.accountId,
                blockchainId: blockchainId,
                accountId: accountId
            )
        } catch {
            WCLogger.error("Failed to create Hedera sign message handler", error: error)
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
        } catch {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(error.localizedDescription)
        }

        guard params.message.utf8.count <= Self.maxMessageByteCount else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("message exceeds \(Self.maxMessageByteCount) bytes")
        }

        self.request = request
        message = params.message
        self.processor = processor
        self.signer = signer
    }
}

extension WalletConnectHederaSignMessageHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .hederaSignMessage }

    var requestData: Data {
        Data(message.utf8)
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        .empty
    }

    func handle() async throws -> RPCResult {
        do {
            let signatureMap = try await processor.signMessage(message, signer: signer)
            return .response(AnyCodable(WalletConnectHederaSignMessageDTO.Response(signatureMap: signatureMap.base64EncodedString())))
        } catch {
            WCLogger.error("Failed to sign Hedera message", error: error)
            throw error
        }
    }
}

enum WalletConnectHederaSignMessageDTO {
    struct Request: Codable {
        let signerAccountId: String
        let message: String
    }

    struct Response: Codable {
        let signatureMap: String
    }
}

/// `hedera_getNodeAddresses` (HIP-820): the consensus nodes this wallet can submit to.
struct WalletConnectHederaGetNodeAddressesHandler {
    private let request: AnyCodable
    private let processor: HederaExternalTransactionProcessor

    init(
        request: AnyCodable,
        blockchainId: String,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        guard let walletModel = wcAccountsWalletModelProvider.getModel(with: blockchainId, accountId: accountId) else {
            throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
        }
        guard let processor = walletModel.hederaExternalTransactionProcessor else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(WalletConnectHederaRequestError.processorUnavailable.localizedDescription)
        }

        self.request = request
        self.processor = processor
    }
}

extension WalletConnectHederaGetNodeAddressesHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .hederaGetNodeAddresses }

    var requestData: Data {
        Data("Consensus node addresses".utf8)
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        .empty
    }

    func handle() async throws -> RPCResult {
        .response(AnyCodable(WalletConnectHederaGetNodeAddressesDTO.Response(nodes: processor.consensusNodeAccountIds)))
    }
}

enum WalletConnectHederaGetNodeAddressesDTO {
    struct Response: Codable {
        let nodes: [String]
    }
}
