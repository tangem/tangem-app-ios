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
import BlockchainSdk

/// Handler for BTC signPsbt RPC method.
final class WalletConnectBitcoinSignPsbtHandler {
    private let request: AnyCodable
    private let walletModel: any WalletModel
    private let signer: TangemSigner
    private let parsedRequest: WalletConnectBtcSignPsbtRequest
    private let encoder = JSONEncoder()

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: TangemSigner,
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
        self.signer = signer
    }

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: TangemSigner,
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
        self.signer = signer
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
        // We currently implement only SIGHASH_ALL for legacy + segwit-v0.
        // WalletConnect can send `sighashTypes` per input; we allow: nil, [], [1]
        if let badInput = parsedRequest.signInputs.first(where: { input in
            guard let types = input.sighashTypes, !types.isEmpty else { return false }
            return !(types.count == 1 && types[0] == 1)
        }) {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Unsupported sighashTypes. index=\(badInput.index)")
        }

        return .empty
    }

    func handle() async throws -> RPCResult {
        if parsedRequest.broadcast == true {
            throw WalletConnectTransactionRequestProcessingError.unsupportedMethod("signPsbt broadcast")
        }

        let signedPsbtBase64 = try await sign()
        let response = WalletConnectBtcSignPsbtResponse(psbt: signedPsbtBase64, txid: nil)
        return .response(AnyCodable(response))
    }
}

// MARK: - Signing

private extension WalletConnectBitcoinSignPsbtHandler {
    func sign() async throws -> String {
        // Only sign requested inputs
        guard !parsedRequest.signInputs.isEmpty else {
            return parsedRequest.psbt
        }

        // Prepare hashes in original order for multi-sign (one tap)
        let inputsToSign = parsedRequest.signInputs.sorted(by: { $0.index < $1.index })
        let hashesToSign = try BlockchainSdk.BitcoinPsbtSigningBuilder.hashesToSign(
            psbtBase64: parsedRequest.psbt,
            signInputs: inputsToSign.map { BlockchainSdk.BitcoinPsbtSigningBuilder.SignInput(index: $0.index) }
        )

        let signatureInfos = try await sign(hashes: hashesToSign)
        let pubKey = try signingPublicKey(for: inputsToSign)

        return try BlockchainSdk.BitcoinPsbtSigningBuilder.applySignaturesAndFinalize(
            psbtBase64: parsedRequest.psbt,
            signInputs: inputsToSign.map { BlockchainSdk.BitcoinPsbtSigningBuilder.SignInput(index: $0.index) },
            signatures: signatureInfos,
            publicKey: pubKey
        )
    }

    func signingPublicKey(for inputs: [WalletConnectBtcPsbtSignInput]) throws -> Data {
        // WC spec provides `address` per input. We validate it's one of our wallet addresses.
        for input in inputs {
            let matches = walletModel.addresses.contains(where: { $0.value.caseInsensitiveCompare(input.address) == .orderedSame })
            guard matches else {
                throw WalletConnectTransactionRequestProcessingError.invalidPayload("Unknown address for signing: \(input.address)")
            }
        }

        // Use walletModel public key as signer key.
        // BDK uses hex-encoded pubkey string as map key; we store raw bytes here.
        return walletModel.publicKey.blockchainKey
    }

    func sign(hashes: [Data]) async throws -> [SignatureInfo] {
        let pubKey = walletModel.publicKey

        return try await signer.sign(hashes: hashes, walletPublicKey: pubKey)
            .eraseToAnyPublisher()
            .async()
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
