//
//  EthereumAddressUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoSwift

/// Utility for validating and checksumming Ethereum addresses
///
/// - Provides methods to check if a string is a valid Ethereum address (with or without checksum),
/// - Supports EIP-55 checksum validation and conversion.
/// - Used to distinguish between raw hex addresses and ENS names in address input fields.
enum EthereumAddressUtils {
    // MARK: - Private Implementation

    /// Checks if the given hex string is a valid Ethereum address, including checksum validation.
    ///
    /// - Parameter address: The hex address string (with 0x prefix).
    /// - Returns: `true` if the address is valid and has a correct checksum (if mixed case), otherwise `false`.
    static func isValidAddressHex(value address: String) -> Bool {
        guard !address.isEmpty, address.hasHexPrefixStrictCheck(), address.count == 42 else {
            return false
        }

        if let checksummed = toChecksumAddress(address), checksummed == address {
            return true
        } else {
            let cleanHex = address.removeHexPrefix()
            if cleanHex.lowercased() != cleanHex, cleanHex.uppercased() != cleanHex {
                return false
            }
        }

        return true
    }

    /// Converts a hex address string to its EIP-55 checksummed representation.
    ///
    /// - Parameter address: The hex address string (with or without 0x prefix).
    /// - Returns: The checksummed address string, or `nil` if the input is invalid.
    static func toChecksumAddress(_ address: String) -> String? {
        let address = address.lowercased().removeHexPrefix()
        guard let hashData = address.data(using: .utf8) else {
            return nil
        }

        let hash = hashData.sha3(.keccak256).hex().removeHexPrefix()

        var ret = "0x"
        let hashChars = Array(hash)
        let addressChars = Array(address)
        for i in 0 ..< addressChars.count {
            guard let intValue = Int(String(hashChars[i]), radix: 16) else {
                return nil
            }

            if intValue >= 8 {
                ret.append(addressChars[i].uppercased())
            } else {
                ret.append(addressChars[i])
            }
        }
        return ret
    }
}
