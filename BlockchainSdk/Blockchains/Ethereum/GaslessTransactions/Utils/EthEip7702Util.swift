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

    /// Builds the hash that must be signed by the EOA.
    /// - Parameters:
    ///   - chainId: EVM chain identifier (e.g. 1 for mainnet).
    ///   - contractAddress: Contract address to authorize (hex string).
    ///   - nonce: Replay-protection nonce.
    /// - Returns: keccak256 hash to be signed.
    func encodeAuthorizationForSigning(chainId: BigUInt, contractAddress: String, nonce: BigUInt) throws -> Data {
        let addressBytes = Data(hex: contractAddress)

        guard addressBytes.count == addressSizeInBytes else {
            throw Eip7702Error.invalidAddressLength
        }

        let payload = try encodeAuthorizationData(chainId: chainId, address: addressBytes, nonce: nonce)
        return payload.sha3(.keccak256)
    }

    /// Encodes the EIP-7702 authorization payload using RLP.
    ///
    /// Important notes:
    /// - All values are encoded as raw byte strings, never as UTF-8 strings.
    /// - Integers are encoded as unsigned big-endian bytes with no leading zeros.
    /// - `nonce == 0` is encoded as an empty byte string, per RLP rules.
    ///
    /// - Returns: `MAGIC || rlp([chainId, address, nonce])`
    func encodeAuthorizationData(chainId: BigUInt, address: Data, nonce: BigUInt) throws -> Data {
        guard address.count == addressSizeInBytes else {
            throw Eip7702Error.invalidAddressLength
        }

        // Chain ID must be non-negative; RLP does not support signed integers.
        guard chainId >= 0 else {
            throw Eip7702Error.invalidChainId
        }

        let encoder = RLPEncoder()

        // Encode chainId as unsigned big-endian bytes.
        let chainIdRlp = RLPValue.bytes(chainId.serialize())

        // Address is already raw 20-byte data.
        let addressRlp = RLPValue.bytes(address)

        // Nonce is encoded as big-endian bytes; zero becomes empty Data().
        let nonceRlp = RLPValue.bytes(nonce.serialize())

        // RLP list: [chainId, address, nonce]
        let list = RLPValue.array([chainIdRlp, addressRlp, nonceRlp])

        // Prefix the RLP payload with the magic byte.
        let encoded = try encoder.encode(list)
        return Data([magicByte]) + encoded
    }
}

// MARK: - Errors

enum Eip7702Error: Error {
    case invalidAddressLength
    case invalidChainId
}
