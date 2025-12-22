//
//  BitcoinTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore
import BitcoinDevKit

/// Decoder:
/// https://learnmeabitcoin.com/tools/
/// https://www.blockchain.com/explorer/assets/btc/decode-transaction
class BitcoinTransactionBuilder {
    private let network: UTXONetworkParams
    private let unspentOutputManager: UnspentOutputManager
    private let builderType: BuilderType
    private let sequence: SequenceType

    private var signHashType: UTXONetworkParamsSignHashType { network.signHashType }

    init(
        network: UTXONetworkParams,
        unspentOutputManager: UnspentOutputManager,
        builderType: BuilderType,
        sequence: SequenceType = .rbf
    ) {
        self.network = network
        self.unspentOutputManager = unspentOutputManager
        self.builderType = builderType
        self.sequence = sequence
    }

    func fee(amount: Amount, address: String, feeRate: Int) async throws -> Int {
        let satoshi = amount.asSmallest().value.intValue()
        let preImage = try await unspentOutputManager.preImage(amount: satoshi, feeRate: feeRate, destination: address)
        return preImage.fee
    }

    func buildForSign(transaction: Transaction) async throws -> [Data] {
        let preImage = try await unspentOutputManager.preImage(transaction: transaction)
        let possibleToUseWalletCore = try possibleToUseWalletCore(for: preImage)

        let hashes: [Data] = try {
            switch builderType {
            case .walletCore(let coinType) where possibleToUseWalletCore:
                let builderType = WalletCoreUTXOTransactionSerializer(coinType: coinType, sequence: sequence)
                return try builderType.preImageHashes(transaction: (transaction: transaction, preImage: preImage))
            case .custom, .walletCore:
                let builderType = CommonUTXOTransactionSerializer(sequence: sequence, signHashType: signHashType)
                return try builderType.preImageHashes(transaction: (transaction: transaction, preImage: preImage))
            }
        }()

        return hashes
    }

    func buildForSend(transaction: Transaction, signatures: [SignatureInfo]) async throws -> Data {
        let preImage = try await unspentOutputManager.preImage(transaction: transaction)
        let signatures = try map(scripts: preImage.inputs.map { $0.script }, signatures: signatures)
        let possibleToUseWalletCore = try possibleToUseWalletCore(for: preImage)

        let encoded: Data = try {
            switch builderType {
            case .walletCore(let coinType) where possibleToUseWalletCore:
                let builderType = WalletCoreUTXOTransactionSerializer(coinType: coinType, sequence: sequence)
                return try builderType.compile(transaction: (transaction: transaction, preImage: preImage), signatures: signatures)
            case .custom, .walletCore:
                let builderType = CommonUTXOTransactionSerializer(sequence: sequence, signHashType: signHashType)
                return try builderType.compile(transaction: (transaction: transaction, preImage: preImage), signatures: signatures)
            }
        }()

        return encoded
    }
}

// MARK: - Private

private extension BitcoinTransactionBuilder {
    func map(scripts: [UTXOLockingScript], signatures: [SignatureInfo]) throws -> [SignatureInfo] {
        guard scripts.count == signatures.count else {
            throw Error.wrongSignaturesCount
        }

        return try zip(scripts, signatures).map { script, signature in
            let publicKey: Data = try {
                switch script.spendable {
                // If we're spending an output which was received on address which was generated for the compressed public key,
                // we need to `compress()` the public key that was used for signing
                case .publicKey(let publicKey) where Secp256k1Key.isCompressed(publicKey: publicKey):
                    return try Secp256k1Key(with: signature.publicKey).compress()

                case .publicKey(let publicKey):
                    return publicKey

                // The redeemScript is used only for Twin cards
                // We always use the compressed public key from `SignatureInfo`
                // This is important to identify which of the two cards was used for signing
                case .redeemScript:
                    return try Secp256k1Key(with: signature.publicKey).compress()

                case .none:
                    throw UTXOTransactionSerializerError.spendableScriptNotFound
                }
            }()

            return try SignatureInfo(signature: signature.der(), publicKey: publicKey, hash: signature.hash)
        }
    }

    // The WalletCoreUTXOTransactionSerializer supports only compressed publicKey
    // [REDACTED_TODO_COMMENT]
    func possibleToUseWalletCore(for preImage: PreImageTransaction) throws -> Bool {
        let hasExtendedPublicKey = try preImage.inputs.contains { input in
            switch input.script.spendable {
            case .none: throw UTXOTransactionSerializerError.spendableScriptNotFound
            case .publicKey(let data): Secp256k1Key.isExtended(publicKey: data)
            case .redeemScript: false
            }
        }

        return !hasExtendedPublicKey
    }
}

extension BitcoinTransactionBuilder {
    enum Error: LocalizedError {
        case wrongSignaturesCount

        var errorDescription: String? {
            switch self {
            case .wrongSignaturesCount: "Wrong signatures count"
            }
        }
    }
}

extension BitcoinTransactionBuilder {
    enum BuilderType {
        case walletCore(CoinType)
        case custom
    }
}
