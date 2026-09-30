//
//  WalletConnectTronSignTransactionHandler.swift
//  Tangem
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

/// `tron_signTransaction`: signs sha256(`raw_data_hex`) with the connected account and returns the dApp's
/// transaction object with the `signature` array filled in. Nothing is broadcast; the dApp does that.
struct WalletConnectTronSignTransactionHandler {
    private let request: AnyCodable
    private let requestParams: WalletConnectTronSignTransactionDTO.Request
    private let signable: WalletConnectTronRequestParser.SignableTransaction
    private let signer: WalletConnectSigner
    private let walletModel: any WalletModel

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: WalletConnectSigner,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        do {
            requestParams = try request.get(WalletConnectTronSignTransactionDTO.Request.self)
            walletModel = try wcAccountsWalletModelProvider.getModel(
                with: requestParams.address,
                blockchainId: blockchainId,
                accountId: accountId
            )
        } catch {
            WCLogger.error("Failed to create Tron sign transaction handler", error: error)
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(request.stringRepresentation)
        }

        do {
            // Bind the signature to the account WalletConnect resolved, not to `params.address` as typed by the dApp.
            signable = try WalletConnectTronRequestParser.makeSignableTransaction(
                from: requestParams.unsignedTransaction,
                expectedOwnerAddress: walletModel.defaultAddressString
            )
        } catch {
            WCLogger.error("Rejected Tron transaction", error: error)
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(error.localizedDescription)
        }

        self.request = request
        self.signer = signer
    }
}

extension WalletConnectTronSignTransactionHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .tronSignTransaction }

    /// The request details show what was decoded from `raw_data_hex` — the bytes being signed — not the dApp's JSON.
    var requestData: Data {
        (try? JSONEncoder().encode(signable.parsed)) ?? Data()
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        .empty
    }

    func handle() async throws -> RPCResult {
        do {
            let unmarshalled = try await signer.sign(data: signable.hash, using: walletModel)
            let signatureHex = try WalletConnectTronRequestParser.transactionSignatureHex(from: unmarshalled)
            let unsigned = requestParams.unsignedTransaction

            let response = WalletConnectTronSignTransactionDTO.Response(
                txID: signable.parsed.txID,
                signature: [signatureHex],
                rawData: unsigned.rawData,
                rawDataHex: unsigned.rawDataHex,
                visible: unsigned.visible ?? false
            )
            return .response(AnyCodable(response))
        } catch {
            WCLogger.error("Failed to sign Tron transaction", error: error)
            throw error
        }
    }
}
