//
//  EthEip7702Util.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import CryptoSwift
import WalletCore

/// Utility for building EIP-7702 authorization payloads.
///
/// EIP-7702 introduces a transaction type where an EOA can temporarily delegate execution rights to a smart contract for the duration
/// of a single transaction.
///
/// Authorization payload format (pre-hash): MAGIC || rlp([chainId, contractAddress, nonce])
/// The resulting byte array is hashed with keccak256 and signed by the EOA.
public struct EthEip7702Util {
    private let addressSizeInBytes = 20

    /// Magic prefix byte used to domain-separate EIP-7702 authorization data.
    private let magicByte: UInt8 = 0x05

    func encodeAuthorizationForSigning(
        chainId: BigUInt,
        contractAddress: String,
        nonce: BigUInt
    ) throws -> Data {
        let addressBytes = Data(hex: contractAddress)
        guard addressBytes.count == addressSizeInBytes else {
            throw Eip7702Error.invalidAddressLength
        }

        let serializedChainId = chainId.serialize()

        // Special-case nonce == 0:
        // BigUInt.serialize() returns empty Data for zero,
        // but here we want an explicit zero byte (00),
        // not an empty value or RLP empty string marker.
        let serializedNonce: Data = nonce == 0 ? Data([UInt8(0)]) : nonce.serialize()

        let rlpList = EthereumRlpRlpList.with {
            $0.items = [
                EthereumRlpRlpItem.with { $0.numberU256 = serializedChainId },
                EthereumRlpRlpItem.with { $0.address = contractAddress },
                EthereumRlpRlpItem.with { $0.data = serializedNonce },
            ]
        }

        let encodingInput = EthereumRlpEncodingInput.with { $0.item.list = rlpList }
        let inputData = try encodingInput.serializedData()
        let outputData = EthereumRlp.encode(coin: .ethereum, input: inputData)
        let rlpEncodedData = try EthereumRlpEncodingOutput(serializedData: outputData).encoded

        return (Data([magicByte]) + rlpEncodedData).sha3(.keccak256)
    }
}

// MARK: - Errors

enum Eip7702Error: Error {
    case invalidAddressLength
    case invalidChainId
}
