//
//  WalletConnectTronSignMessageHandler.swift
//  Tangem
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

/// `tron_signMessage`: TIP-191 personal message signature (`tronWeb.trx.signMessageV2` layout).
struct WalletConnectTronSignMessageHandler {
    /// Upper bound on a message the wallet will show and sign.
    static let maxMessageByteCount = 64 * 1024

    private let request: AnyCodable
    private let message: String
    private let signer: WalletConnectSigner
    private let walletModel: any WalletModel

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: WalletConnectSigner,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        let castedParams: WalletConnectTronSignMessageDTO.Request
        do {
            castedParams = try request.get(WalletConnectTronSignMessageDTO.Request.self)
            walletModel = try wcAccountsWalletModelProvider.getModel(
                with: castedParams.address,
                blockchainId: blockchainId,
                accountId: accountId
            )
        } catch {
            WCLogger.error("Failed to create Tron sign message handler", error: error)
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(request.stringRepresentation)
        }

        guard castedParams.message.utf8.count <= Self.maxMessageByteCount else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("message exceeds \(Self.maxMessageByteCount) bytes")
        }

        self.request = request
        message = castedParams.message
        self.signer = signer
    }
}

extension WalletConnectTronSignMessageHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .tronSignMessage }

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
            let digest = WalletConnectTronRequestParser.messageDigest(message)
            let unmarshalled = try await signer.sign(data: digest, using: walletModel)
            let signature = try WalletConnectTronRequestParser.messageSignatureHex(from: unmarshalled)
            return .response(AnyCodable(WalletConnectTronSignMessageDTO.Response(signature: signature)))
        } catch {
            WCLogger.error("Failed to sign Tron message", error: error)
            throw error
        }
    }
}

enum WalletConnectTronSignMessageDTO {
    struct Request: Codable {
        let address: String
        let message: String
    }

    struct Response: Codable {
        let signature: String
    }
}
