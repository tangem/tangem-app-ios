//
//  BitcoinWalletConnectSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct BitcoinWalletConnectSigner: WalletConnectSigner {
    let signer: TangemSigner

    func sign(data: Data, using walletModel: any WalletModel) async throws -> Data {
        try await sign(
            data: data,
            using: walletModel,
            address: walletModel.defaultAddress.value
        )
    }

    func sign(hashes: [Data], using walletModel: any WalletModel) async throws -> [Data] {
        let pubKey = walletModel.publicKey
        let responses = try await signer.sign(hashes: hashes, walletPublicKey: pubKey)
            .tryMap { responses -> [Data] in
                try responses.enumerated().map { index, signedHash in
                    try bitcoinSignature(
                        signedHash: signedHash,
                        hash: hashes[index],
                        publicKey: pubKey.blockchainKey,
                        address: walletModel.defaultAddress.value
                    )
                }
            }
            .eraseToAnyPublisher()
            .async()

        return responses
    }

    func sign(data: Data, using walletModel: any WalletModel, address: String) async throws -> Data {
        let pubKey = walletModel.publicKey
        let signed = try await signer.sign(hash: data, walletPublicKey: pubKey)
            .tryMap { response -> Data in
                try bitcoinSignature(
                    signedHash: response,
                    hash: data,
                    publicKey: pubKey.blockchainKey,
                    address: address
                )
            }
            .eraseToAnyPublisher()
            .async()

        return signed
    }
}

// MARK: - Helpers

private extension BitcoinWalletConnectSigner {
    func bitcoinSignature(
        signedHash: Data,
        hash: Data,
        publicKey: Data,
        address: String
    ) throws -> Data {
        // Unmarshal to get r, s, v components
        guard let extended = try? Secp256k1Signature(with: signedHash).unmarshal(
            with: publicKey,
            hash: hash
        ) else {
            throw WCTransactionSignError.signFailed
        }

        // Compose Bitcoin message signature: header + r + s
        let headerBase = signatureHeaderBase(
            address: address,
            publicKey: publicKey
        )

        // v is 27..30 (27 + recId). Convert to recId.
        let vByte = extended.v.last ?? 27
        let recId = Int(vByte) - 27
        guard (0 ... 3).contains(recId) else {
            throw WCTransactionSignError.signFailed
        }

        let header = UInt8(headerBase + recId)
        return Data([header]) + extended.r + extended.s
    }

    func signatureHeaderBase(address: String, publicKey: Data) -> Int {
        if isBech32(address) {
            // SegWit bech32
            return 39
        }

        // Legacy: base depends on key compression
        let isCompressed = Secp256k1Key.isCompressed(publicKey: publicKey)
        return isCompressed ? 31 : 27
    }

    func isBech32(_ address: String) -> Bool {
        let lower = address.lowercased()
        return lower.hasPrefix("bc1") || lower.hasPrefix("tb1") || lower.hasPrefix("bcrt1")
    }
}
