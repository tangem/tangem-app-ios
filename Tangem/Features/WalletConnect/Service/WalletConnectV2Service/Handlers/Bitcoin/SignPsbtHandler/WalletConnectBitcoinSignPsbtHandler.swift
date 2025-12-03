//
//  WalletConnectBitcoinSignPsbtHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Commons
import enum JSONRPC.RPCResult

/// Handler for BTC signPsbt RPC method.
/// Actual PSBT signing/finalization is not yet implemented.
final class WalletConnectBitcoinSignPsbtHandler {
    private let request: AnyCodable
    private let walletModel: any WalletModel
    private let parsedRequest: WalletConnectBtcSignPsbtRequest
    private let encoder = JSONEncoder()

    init(
        request: AnyCodable,
        blockchainId: String,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws {
        do {
            parsedRequest = try request.get(WalletConnectBtcSignPsbtRequest.self)
        } catch {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(request.description)
        }

        guard let model = walletModelProvider.getModel(with: blockchainId) else {
            throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
        }

        walletModel = model
        self.request = request
    }

    init(
        request: AnyCodable,
        blockchainId: String,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        do {
            parsedRequest = try request.get(WalletConnectBtcSignPsbtRequest.self)
        } catch {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(request.description)
        }

        guard let model = wcAccountsWalletModelProvider.getModel(with: blockchainId, accountId: accountId) else {
            throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
        }

        walletModel = model
        self.request = request
    }
}

// MARK: - WalletConnectMessageHandler

extension WalletConnectBitcoinSignPsbtHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .signPsbt }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    var requestData: Data {
        (try? encoder.encode(parsedRequest)) ?? Data()
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        // Only 0 or 1 sighashTypes per input is supported for now
        if let badInput = parsedRequest.signInputs.first(where: { ($0.sighashTypes?.count ?? 0) > 1 }) {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(
                "Multiple sighashTypes are not supported. index=\(badInput.index)"
            )
        }

        return .empty
    }

    func handle() async throws -> RPCResult {
        // [REDACTED_TODO_COMMENT]
        // For now, return the same PSBT without broadcasting.

        if parsedRequest.broadcast == true {
            // Broadcasting requires finalization (extract raw tx), which is not implemented yet
            throw WalletConnectTransactionRequestProcessingError.unsupportedMethod("signPsbt broadcast")
        }

        let response = WalletConnectBtcSignPsbtResponse(psbt: parsedRequest.psbt, txid: nil)
        return .response(AnyCodable(response))
    }
}

// MARK: - Models

struct WalletConnectBtcSignPsbtRequest: Codable {
    let psbt: String
    let signInputs: [WalletConnectBtcPsbtSignInput]
    let broadcast: Bool?
}

struct WalletConnectBtcPsbtSignInput: Codable {
    let address: String
    let index: Int
    let sighashTypes: [Int]?
}

struct WalletConnectBtcSignPsbtResponse: Codable {
    let psbt: String
    let txid: String?
}
