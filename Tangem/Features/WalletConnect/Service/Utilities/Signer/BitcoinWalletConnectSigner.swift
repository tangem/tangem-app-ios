//
//  BitcoinWalletConnectSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct BitcoinWalletConnectSigner: WalletConnectSigner {
    let signer: TangemSigner

    func sign(data: Data, using walletModel: any WalletModel) async throws -> Data {
        // Sign the provided hash using the card
        let pubKey = walletModel.publicKey
        let signed = try await signer.sign(hash: data, walletPublicKey: pubKey)
            .tryMap { response -> Data in
                // Unmarshal to get r, s, v components
                guard let extended = try? Secp256k1Signature(with: response).unmarshal(
                    with: pubKey.blockchainKey,
                    hash: data
                ) else {
                    throw WCTransactionSignError.signFailed
                }

                // Compose Bitcoin message signature: header + r + s
                let headerBase = signatureHeaderBase(
                    address: walletModel.defaultAddress.value,
                    publicKey: pubKey.blockchainKey
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
            .eraseToAnyPublisher()
            .async()

        return signed
    }

    func sign(hashes: [Data], using walletModel: any WalletModel) async throws -> [Data] {
        let pubKey = walletModel.publicKey
        let responses = try await signer.sign(hashes: hashes, walletPublicKey: pubKey)
            .tryMap { responses -> [Data] in
                try responses.enumerated().map { index, signedHash in
                    guard let extended = try? Secp256k1Signature(with: signedHash).unmarshal(
                        with: pubKey.blockchainKey,
                        hash: hashes[index]
                    ) else {
                        throw WCTransactionSignError.signFailed
                    }

                    let headerBase = signatureHeaderBase(
                        address: walletModel.defaultAddress.value,
                        publicKey: pubKey.blockchainKey
                    )
                    let vByte = extended.v.last ?? 27
                    let recId = Int(vByte) - 27
                    guard (0 ... 3).contains(recId) else {
                        throw WCTransactionSignError.signFailed
                    }

                    let header = UInt8(headerBase + recId)
                    return Data([header]) + extended.r + extended.s
                }
            }
            .eraseToAnyPublisher()
            .async()

        return responses
    }
}

// MARK: - Helpers

private extension BitcoinWalletConnectSigner {
    func signatureHeaderBase(address: String, publicKey: Data) -> Int {
        if isBech32(address) {
            // SegWit bech32
            return 39
        }

        // Legacy: base depends on key compression
        let isCompressed = publicKey.count == 33
        return isCompressed ? 31 : 27
    }

    func isBech32(_ address: String) -> Bool {
        let lower = address.lowercased()
        return lower.hasPrefix("bc1") || lower.hasPrefix("tb1") || lower.hasPrefix("bcrt1")
    }
}
