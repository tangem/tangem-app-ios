//
//  CommonENSProcessor.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// A processor that handles Ethereum Name Service (ENS) name operations according to ENS specifications.
/// This implementation provides functionality for name hashing and encoding following the ENS standards.
/// For more information about ENS, see: https://docs.ens.domains
struct CommonENSProcessor: ENSProcessor {
    /// Regular expression pattern that validates ENS names.
    /// The pattern ensures that:
    /// - Names consist of valid characters (a-z, 0-9, and hyphen)
    /// - Each label (part between dots) is 1-63 characters long
    /// - Labels don't start or end with a hyphen
    /// - The top-level domain is at least 2 characters
    private let ensNameRegex = try! NSRegularExpression(pattern: "^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z]{2,}$")

    /// Computes the namehash of an ENS name.
    /// The namehash is a recursive process that generates a unique hash for any valid domain name.
    /// This hash is used in ENS smart contracts to uniquely identify names.
    ///
    /// - Parameter name: The ENS name to hash (e.g., "vitalik.eth")
    /// - Returns: A 32-byte Data object containing the namehash
    /// - Throws: Error.invalidName if the name format is invalid
    func getNameHash(_ name: String) throws -> Data {
        let normalized = try normalizeAndCheckName(name)
        let labels = normalized.split(separator: ".")
        var node = Data(count: 32)

        for label in labels.reversed() {
            let labelData = label.data(using: .utf8)!
            let labelHash = labelData.sha3(.keccak256)
            node = (node + labelHash).sha3(.keccak256)
        }

        return node
    }

    /// Encodes an ENS name according to DNS wire format.
    /// This encoding is used in ENS resolvers and registrars for various operations.
    ///
    /// - Parameter name: The ENS name to encode (e.g., "vitalik.eth")
    /// - Returns: Data object containing the DNS wire format encoding of the name
    /// - Throws:
    ///   - Error.invalidName if the name format is invalid
    ///   - Error.invalidLabelLength if any label length is outside the valid range (1-63 characters)
    func encode(name: String) throws -> Data {
        let normalized = try normalizeAndCheckName(name)
        let labels = normalized.split(separator: ".")

        let totalLength = labels.reduce(0) { $0 + $1.count + 1 } + 1
        var encoded = Data(count: totalLength)
        var offset = 0

        for label in labels {
            guard label.count >= 1, label.count <= 63 else {
                throw Error.invalidLabelLength(String(label))
            }

            encoded[offset] = UInt8(label.count)
            offset += 1

            let labelData = label.data(using: .utf8)!
            encoded[offset ..< (offset + label.count)] = labelData
            offset += label.count
        }

        encoded[offset] = 0
        return encoded
    }

    /// Normalizes and validates an ENS name.
    /// Normalization includes converting to lowercase and validation against ENS name rules.
    ///
    /// - Parameter name: The ENS name to normalize and validate
    /// - Returns: The normalized name if valid
    /// - Throws: Error.invalidName if the name doesn't match ENS naming rules
    private func normalizeAndCheckName(_ name: String) throws -> String {
        let normalized = name.lowercased()
        let range = NSRange(location: 0, length: normalized.utf16.count)

        guard ensNameRegex.firstMatch(in: normalized, range: range) != nil else {
            throw Error.invalidName(normalized)
        }

        return normalized
    }
}

/// Errors that can occur during ENS name processing
extension CommonENSProcessor {
    enum Error: Swift.Error {
        /// Indicates that the provided name doesn't conform to ENS naming rules
        case invalidName(String)
        /// Indicates that a label in the name is either too short (< 1 character) or too long (> 63 characters)
        case invalidLabelLength(String)
    }
}
