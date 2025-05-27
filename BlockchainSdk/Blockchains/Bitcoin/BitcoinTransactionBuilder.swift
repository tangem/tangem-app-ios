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

/// Decoder:
/// https://learnmeabitcoin.com/tools/
/// https://www.blockchain.com/explorer/assets/btc/decode-transaction
class BitcoinTransactionBuilder {
    private let network: UTXONetworkParams
    private let unspentOutputManager: UnspentOutputManager
    private let builderType: BuilderType
    private let sequence: SequenceType

    private var publicKeyType: UTXONetworkParamsPublicKeyType { network.publicKeyType }
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
        let hasExtendedKey = preImage.inputs.contains { $0.script.spendable?.isExtendedPublicKey ?? false }

        let hashes: [Data] = try {
            switch builderType {
            // The WalletCore build supported only compressed publicKey
            // Make WalletCore support extended publicKey
            // [REDACTED_TODO_COMMENT]
            case .walletCore(let coinType) where !hasExtendedKey:
                let builderType = WalletCoreUTXOTransactionSerializer(coinType: coinType, sequence: sequence)
                return try builderType.preImageHashes(transaction: (transaction: transaction, preImage: preImage))
            case .custom, .walletCore:
                let builderType = CommonUTXOTransactionSerializer(sequence: sequence, signHashType: signHashType)
                return try builderType.preImageHashes(transaction: preImage)
            }
        }()

        return hashes
    }

    func buildForSend(transaction: Transaction, signatures: [SignatureInfo]) async throws -> Data {
        let signatures = try map(signatures: signatures)
        let preImage = try await unspentOutputManager.preImage(transaction: transaction)
        let hasExtendedKey = preImage.inputs.contains { $0.script.spendable?.isExtendedPublicKey ?? false }

        let encoded: Data = try {
            switch builderType {
            // The WalletCore build supported only compressed publicKey
            // Make WalletCore support extended publicKey
            // [REDACTED_TODO_COMMENT]
            case .walletCore(let coinType) where !hasExtendedKey:
                let builderType = WalletCoreUTXOTransactionSerializer(coinType: coinType, sequence: sequence)
                return try builderType.compile(transaction: (transaction: transaction, preImage: preImage), signatures: signatures)
            case .custom, .walletCore:
                let builderType = CommonUTXOTransactionSerializer(sequence: sequence, signHashType: signHashType)
                return try builderType.compile(transaction: preImage, signatures: signatures)
            }
        }()

        return encoded
    }
}

// MARK: - Private

private extension BitcoinTransactionBuilder {
    func map(signatures: [SignatureInfo]) throws -> [SignatureInfo] {
        try signatures.map { signature in
            switch publicKeyType {
            case .compressed:
                try SignatureInfo(
                    signature: signature.der(),
                    publicKey: Secp256k1Key(with: signature.publicKey).compress(),
                    hash: signature.hash
                )
            case .asIs:
                try SignatureInfo(signature: signature.der(), publicKey: signature.publicKey, hash: signature.hash)
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
