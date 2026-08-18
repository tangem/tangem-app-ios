//
//  EVMAddressUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoSwift
import TangemFoundation

public enum EVMAddressUtils {
    /// Converts an address to its canonical lowercase `0x`-prefixed representation.
    ///
    /// - Parameters:
    ///   - address: The address string, either hex or in the blockchain-specific form (e.g. `xdc…`).
    ///   - blockchain: The blockchain the address belongs to.
    /// - Returns: The lowercase hex address, or `nil` if the blockchain is not EVM or the address is malformed.
    public static func canonicalAddress(_ address: String, blockchain: Blockchain) -> String? {
        guard blockchain.isEvm else {
            return nil
        }

        let lowercasedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let converter = EthereumAddressConverterFactory().makeConverter(for: blockchain)

        guard
            let prefixedAddress = (try? converter.convertToETHAddress(lowercasedAddress))?.addHexPrefix(),
            prefixedAddress.isEvmAddress
        else {
            return nil
        }

        return prefixedAddress
    }

    /// Checks if the given address is a well-known burn address, i.e. one whose incoming funds are unrecoverable.
    ///
    /// - Parameters:
    ///   - address: The address string, either hex or in the blockchain-specific form (e.g. `xdc…`).
    ///   - blockchain: The blockchain the address belongs to.
    /// - Returns: `true` if the address is a known burn address, otherwise `false`.
    public static func isBurnAddress(_ address: String, blockchain: Blockchain) -> Bool {
        guard let canonicalAddress = canonicalAddress(address, blockchain: blockchain) else {
            return false
        }

        return isBurnAddress(canonicalAddress)
    }

    /// Checks if the given hex address is a well-known burn address, ignoring casing and the hex prefix.
    ///
    /// - Parameter address: The hex address string, with or without the `0x` prefix.
    /// - Returns: `true` if the address is a known burn address, otherwise `false`.
    public static func isBurnAddress(_ address: String) -> Bool {
        let normalizedAddress = address
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .addHexPrefix()

        return Constants.burnAddresses.contains(normalizedAddress)
    }

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

// MARK: - Constants

extension EVMAddressUtils {
    enum Constants {
        /// Lowercase, to match what `canonicalAddress` returns.
        static let burnAddresses: Set<String> = [
            "0x0000000000000000000000000000000000000000",
            "0x000000000000000000000000000000000000dead",
            "0xdead000000000000000042069420694206942069",
            "0xdeaddeaddeaddeaddeaddeaddeaddeaddeaddead",
        ]
    }
}
